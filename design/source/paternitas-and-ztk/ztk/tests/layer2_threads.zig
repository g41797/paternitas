// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Layer 2 — the mailbox, with more than one context.
//!
//! Scenarios 32, 36, 50, 51, 52 and 266. These are the ones a single
//! context cannot show: a receiver that is actually blocked, and what
//! arrives while it is.
//!
//! The extra contexts are `std.Thread`, as the cross-layer notes say.
//! Cancel, futures and `Io.Group` are task2.

/// One mailbox, its `Io`, and the teardown. The same shape as the layer 2
/// fixture, kept here rather than shared: a test file is read on its own.
const Fixture = struct {
    threaded: std.Io.Threaded,
    io: Io = undefined,
    mbx: *m.Mbox = undefined,

    fn start(self: *Fixture) !void {
        self.threaded = std.Io.Threaded.init(alloc, .{});
        self.io = self.threaded.io();

        var slot: m.inner.Slot = null;
        try m.mbox.new(alloc, self.io, &slot);
        self.mbx = m.Mbox.moveFromSlot(&slot).?;
    }

    fn finish(self: *Fixture) void {
        var rem: m.queue.Queue = self.mbx.close();
        o.releaseAll(&rem, alloc, self.io);

        self.mbx.destroy();
        self.threaded.deinit();
    }
};

/// What one receiving context did. Read by the test after the join.
const Caught = struct {
    got: usize = 0,
    outcome: ?anyerror = null,

    /// Set last, and the only field another context reads before the join.
    ///
    /// `got` and `outcome` are written by the receiving context and read by
    /// the test after it joins, so they need nothing. This one is read while
    /// that context is still running.
    done: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    fn isDone(self: *const Caught) bool {
        return self.done.load(.acquire);
    }

    /// Receives one parent, waiting as long as it is told to.
    fn one(self: *Caught, mbx: *m.Mbox, timeout_ns: ?u64) void {
        var slot: m.inner.Slot = null;

        mbx.receive(&slot, timeout_ns) catch |err| {
            self.outcome = err;
            self.done.store(true, .release);
            return;
        };

        self.got = 1;
        o.releaseSlot(&slot, alloc, std.testing.io);
        self.done.store(true, .release);
    }

    /// Receives until the mailbox closes, counting what it got.
    fn untilClosed(self: *Caught, mbx: *m.Mbox) void {
        while (true) {
            var slot: m.inner.Slot = null;

            mbx.receive(&slot, a_second) catch |err| {
                self.outcome = err;
                self.done.store(true, .release);
                return;
            };

            self.got += 1;
            o.releaseSlot(&slot, alloc, std.testing.io);
        }
    }
};

/// Sends `count` parents of its own, one at a time.
fn sendSome(mbx: *m.Mbox, first: u32, count: u32, sent: *usize) void {
    var seq: u32 = 0;
    while (seq < count) : (seq += 1) {
        var slot: m.inner.Slot = null;

        o.newMsg(alloc, std.testing.io, &slot, first + seq) catch return;

        mbx.send(&slot) catch {
            o.releaseSlot(&slot, alloc, std.testing.io);
            return;
        };

        _ = @atomicRmw(usize, sent, .Add, 1, .monotonic);
    }
}

test "32 — a receive with no timeout waits, and another context sends" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var caught: Caught = .{};

    // null waits forever, so nothing but the send can end this.
    const waiter = try std.Thread.spawn(.{}, Caught.one, .{ &caught, f.mbx, null });

    var slot: m.inner.Slot = null;
    try o.newMsg(alloc, f.io, &slot, 32);
    try f.mbx.send(&slot);

    waiter.join();

    try expect(caught.outcome == null);
    try expect(caught.got == 1);
}

test "36 — out of band wakes a waiting receiver" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var caught: Caught = .{};
    const waiter = try std.Thread.spawn(.{}, Caught.one, .{ &caught, f.mbx, null });

    var slot: m.inner.Slot = null;
    try o.newMsg(alloc, f.io, &slot, 36);
    try f.mbx.sendOob(&slot);

    waiter.join();

    try expect(caught.outcome == null);
    try expect(caught.got == 1);
}

test "266 — a wake with no message releases every waiter" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var first: Caught = .{};
    var second: Caught = .{};

    const a = try std.Thread.spawn(.{}, Caught.one, .{ &first, f.mbx, null });
    const b = try std.Thread.spawn(.{}, Caught.one, .{ &second, f.mbx, null });

    // A wake does not outlive the call: a receiver that has not arrived yet
    // is not woken by it. So the wake is repeated until both have come back,
    // rather than sent once into a race. That is the scenario's own rule —
    // *receivers that start waiting later are not affected* — used instead
    // of worked around.
    while (!first.isDone() or !second.isDone()) {
        try f.mbx.wakeUpAll();
        std.Thread.yield() catch {};
    }

    a.join();
    b.join();

    // Both came back empty-handed, and both say why.
    try expect(first.outcome.? == error.Wakeup);
    try expect(second.outcome.? == error.Wakeup);
    try expect(first.got == 0 and second.got == 0);

    // The mailbox is still open. A wake is not a close and not a cancel.
    try expect(!f.mbx.isClosed());
}

test "50 — fan-in" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var sent: usize = 0;

    const one = try std.Thread.spawn(.{}, sendSome, .{ f.mbx, 100, 3, &sent });
    const two = try std.Thread.spawn(.{}, sendSome, .{ f.mbx, 200, 3, &sent });
    const three = try std.Thread.spawn(.{}, sendSome, .{ f.mbx, 300, 3, &sent });

    one.join();
    two.join();
    three.join();

    try expect(sent == 9);

    // Every one of them arrived, and the mailbox held them all.
    var got: usize = 0;
    while (got < 9) : (got += 1) {
        var slot: m.inner.Slot = null;
        try f.mbx.receive(&slot, a_second);
        o.releaseSlot(&slot, alloc, f.io);
    }

    try expect(f.mbx.len() == 0);
}

test "51 — fan-out: sent equals received plus what the close gave back" {
    var f: Fixture = undefined;
    try f.start();
    defer f.threaded.deinit();

    var first: Caught = .{};
    var second: Caught = .{};

    const a = try std.Thread.spawn(.{}, Caught.untilClosed, .{ &first, f.mbx });
    const b = try std.Thread.spawn(.{}, Caught.untilClosed, .{ &second, f.mbx });

    var sent: usize = 0;
    var seq: u32 = 0;
    while (seq < 20) : (seq += 1) {
        var slot: m.inner.Slot = null;
        try o.newMsg(alloc, f.io, &slot, seq);
        try f.mbx.send(&slot);
        sent += 1;
    }

    var rem: m.queue.Queue = f.mbx.close();
    const returned = rem.len();
    o.releaseAll(&rem, alloc, f.io);

    a.join();
    b.join();

    // Both loops ended because the mailbox closed, not because they gave up.
    try expect(first.outcome.? == error.Closed);
    try expect(second.outcome.? == error.Closed);

    // Nothing lost and nothing doubled.
    try expect(first.got + second.got + returned == sent);

    f.mbx.destroy();
}

test "52 — senders and receivers together, and the close ends it" {
    var f: Fixture = undefined;
    try f.start();
    defer f.threaded.deinit();

    var first: Caught = .{};
    var second: Caught = .{};

    const ra = try std.Thread.spawn(.{}, Caught.untilClosed, .{ &first, f.mbx });
    const rb = try std.Thread.spawn(.{}, Caught.untilClosed, .{ &second, f.mbx });

    var sent: usize = 0;

    const sa = try std.Thread.spawn(.{}, sendSome, .{ f.mbx, 100, 10, &sent });
    const sb = try std.Thread.spawn(.{}, sendSome, .{ f.mbx, 200, 10, &sent });
    const sc = try std.Thread.spawn(.{}, sendSome, .{ f.mbx, 300, 10, &sent });

    sa.join();
    sb.join();
    sc.join();

    var rem: m.queue.Queue = f.mbx.close();
    const returned = rem.len();
    o.releaseAll(&rem, alloc, f.io);

    ra.join();
    rb.join();

    try expect(first.got + second.got + returned == sent);
    try expect(sent == 30);

    // Closed and quiet, so it may be freed.
    try expect(f.mbx.isIdle());

    f.mbx.destroy();
}

const a_second: u64 = 1_000_000_000;

const alloc = std.testing.allocator;
const expect = std.testing.expect;
const m = @import("matryoshka");
const o = @import("parents.zig");
const std = @import("std");
const Io = std.Io;
