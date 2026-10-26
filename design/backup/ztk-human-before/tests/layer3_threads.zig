// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Layer 3 — the pool, with more than one context.
//!
//! Scenarios 81, 83, 84, 282, 283, 288 and 290. These are the ones a single
//! context cannot show: a waiter that is actually blocked, a hook that is
//! actually inside the pool, and what another context may do while it is.
//!
//! The extra contexts are `std.Thread`, as the cross-layer notes say.

/// One pool, its hooks, its `Io`, and the teardown. The same shape as the
/// layer 3 fixture, kept here rather than shared: a test file is read on its
/// own.
const Fixture = struct {
    threaded: std.Io.Threaded,
    io: Io = undefined,
    rec: h.Recorder = undefined,
    pool: *m.Pool = undefined,

    const both: [2]m.inner.TypeId = .{ o.MSG.ID, o.NOTE.ID };

    fn start(self: *Fixture) !void {
        self.threaded = std.Io.Threaded.init(alloc, .{});
        self.io = self.threaded.io();
        self.rec = .{ .alloc = alloc, .io = self.io };

        var slot: m.inner.Slot = null;
        try m.pool.new(alloc, self.io, &both, self.rec.hooks(), &slot);
        self.pool = m.Pool.moveFromSlot(&slot).?;
    }

    fn finish(self: *Fixture) void {
        self.pool.close();
        self.pool.destroy();
        self.threaded.deinit();
    }
};

/// Spins until the condition holds. There is no `sleep` in std here —
/// waiting is `Io`'s job in 0.16 — so a test that must let another context
/// reach a point yields instead.
fn spinUntil(comptime done: fn (*Fixture) bool, f: *Fixture) void {
    while (!done(f)) std.Thread.yield() catch {};
}

fn hookIsInside(f: *Fixture) bool {
    return f.rec.in_hook.load(.acquire);
}

test "81 — hooks run outside the lock" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    // The hook asks the pool a question while the pool is calling it. Under
    // the lock this would be a deadlock, and the test would hang rather
    // than fail — which is why it is worth having.
    f.rec.reenter = f.pool;

    var slot: m.inner.Slot = null;
    try f.pool.get(o.MSG.ID, .available_or_new, &slot);
    try f.pool.put(&slot);

    try expect(f.rec.reentered);
    try expectEqual(@as(usize, 1), try f.pool.countOf(o.MSG.ID));
}

test "83 — the waiting get times out on an empty pool" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;
    try expectError(error.Timeout, f.pool.getWait(o.MSG.ID, &slot, a_millisecond * 20));

    try expect(slot == null);

    // It waited for a stored parent. It never reached the get hook, which is
    // what separates it from every mode of `get`.
    try expectEqual(@as(usize, 0), f.rec.gets);
}

/// What one waiting context ended with. Read after the join, except for
/// `waiting`, which the test reads while that context is still running.
const Waiter = struct {
    pool: *m.Pool = undefined,
    timeout_ns: ?u64 = null,
    got: ?*m.inner.Anchor = null,
    outcome: ?anyerror = null,
    waiting: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    fn run(self: *Waiter) void {
        var slot: m.inner.Slot = null;

        self.waiting.store(true, .release);

        self.pool.getWait(o.MSG.ID, &slot, self.timeout_ns) catch |err| {
            self.outcome = err;
            return;
        };

        self.got = slot;
    }
};

test "84 — the waiting get waits until another context puts" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var w: Waiter = .{ .pool = f.pool, .timeout_ns = null };

    const waiter = try std.Thread.spawn(.{}, Waiter.run, .{&w});

    while (!w.waiting.load(.acquire)) std.Thread.yield() catch {};

    // Make one here and give it to the pool. The waiter is blocked, so the
    // parent reaches it through the pool rather than through the hook.
    var slot: m.inner.Slot = null;
    try f.pool.get(o.MSG.ID, .new_only, &slot);
    const given = slot.?;
    try f.pool.put(&slot);

    waiter.join();

    try expect(w.outcome == null);
    try expect(w.got.? == given);

    var back: m.inner.Slot = w.got;
    o.releaseSlot(&back, alloc, f.io);
}

test "290 — the waiting get takes a stored item when one arrives" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    // The same, with a deadline rather than none. The deadline is anchored
    // once before the loop, so a spurious wakeup does not restart it.
    var w: Waiter = .{ .pool = f.pool, .timeout_ns = a_millisecond * 500 };

    const waiter = try std.Thread.spawn(.{}, Waiter.run, .{&w});

    while (!w.waiting.load(.acquire)) std.Thread.yield() catch {};

    var slot: m.inner.Slot = null;
    try f.pool.get(o.MSG.ID, .new_only, &slot);
    try f.pool.put(&slot);

    waiter.join();

    try expect(w.outcome == null);
    try expect(w.got != null);

    var back: m.inner.Slot = w.got;
    o.releaseSlot(&back, alloc, f.io);
}

test "a close wakes every waiter" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var w: Waiter = .{ .pool = f.pool, .timeout_ns = null };

    const waiter = try std.Thread.spawn(.{}, Waiter.run, .{&w});

    while (!w.waiting.load(.acquire)) std.Thread.yield() catch {};

    // Nothing is ever put. Only the close ends this wait.
    f.pool.close();

    waiter.join();

    try expect(w.got == null);
    try expectEqual(@as(anyerror, error.Closed), w.outcome.?);
}

/// One `put` on another context, so the test can close the pool while that
/// put's hook is still running.
const Putter = struct {
    pool: *m.Pool = undefined,
    slot: m.inner.Slot = null,
    outcome: ?anyerror = null,

    fn run(self: *Putter) void {
        self.pool.put(&self.slot) catch |err| {
            self.outcome = err;
        };
    }
};

test "282, 283 and 288 — a close while the put hook runs loses nothing" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    // The hook gives back two parts with the parent, and sits inside the
    // pool until this test lets it go.
    var go: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
    f.rec.parts = 2;
    f.rec.hold = &go;

    var p: Putter = .{ .pool = f.pool };
    try f.pool.get(o.MSG.ID, .new_only, &p.slot);

    const putter = try std.Thread.spawn(.{}, Putter.run, .{&p});

    spinUntil(hookIsInside, &f);

    // Closed with a put in flight. The close hook is called here with
    // nothing stored, which is call one.
    f.pool.close();

    // 288: closed, but a call is still inside, so freeing is not allowed
    // yet. The negative program is what shows `destroy` aborting on it.
    try expect(f.pool.isClosed());
    try expect(!f.pool.isIdle());

    go.store(true, .release);
    putter.join();

    try expect(p.outcome == null);

    // The straggling put found the pool closed and handed everything it
    // still had to the close hook rather than dropping it: the parent it
    // took out of the caller's Slot, and both parts the hook added.
    try expectEqual(@as(usize, 2), f.rec.close_calls);
    try expectEqual(@as(usize, 3), f.rec.closed_items);

    // And the caller's Slot is empty either way. The parent left it before
    // the hook ran.
    try expect(p.slot == null);

    // Every call has returned now, so freeing is allowed.
    try expect(f.pool.isIdle());
}

const a_millisecond: u64 = 1_000_000;

const alloc = std.testing.allocator;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;
const h = @import("hooks.zig");
const m = @import("matryoshka");
const o = @import("parents.zig");
const Io = std.Io;
const std = @import("std");
