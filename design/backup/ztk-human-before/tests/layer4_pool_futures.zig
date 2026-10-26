// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Layer 4 — the pool's waiting get, packed into a `Pool.Result` and wrapped
//! in an `Io.Future`.
//!
//! The pool's counterpart of the mailbox's `receiveResult` and
//! `receiveFuture`. Every outcome of `getWait` has one variant.

const Fixture = struct {
    threaded: std.Io.Threaded,
    io: Io = undefined,
    rec: h.Recorder = undefined,
    pool: *m.Pool = undefined,

    fn start(self: *Fixture, ids: []const m.inner.TypeId) !void {
        self.threaded = std.Io.Threaded.init(alloc, .{});
        self.io = self.threaded.io();
        self.rec = .{ .alloc = alloc, .io = self.io };

        var slot: m.inner.Slot = null;
        try m.pool.new(alloc, self.io, ids, self.rec.hooks(), &slot);
        self.pool = m.Pool.moveFromSlot(&slot).?;
    }

    fn finish(self: *Fixture) void {
        self.pool.close();
        self.pool.destroy();
        self.threaded.deinit();
    }
};

test "getWaitResult: a stored parent is an item" {
    var f: Fixture = undefined;
    try f.start(&.{o.MSG.ID});
    defer f.finish();

    var slot: m.inner.Slot = null;
    try f.pool.get(o.MSG.ID, .new_only, &slot);
    try f.pool.put(&slot);

    const r = m.pool.getWaitResult(f.pool, o.MSG.ID, 0);
    try expect(r == .anchor);

    var back: m.inner.Slot = r.anchor;
    o.releaseSlot(&back, alloc, f.io);
}

test "getWaitResult: an empty pool times out" {
    var f: Fixture = undefined;
    try f.start(&.{o.MSG.ID});
    defer f.finish();

    try expect(m.pool.getWaitResult(f.pool, o.MSG.ID, 0) == .timeout);
}

test "getWaitResult: a closed pool is closed" {
    var f: Fixture = undefined;
    try f.start(&.{o.MSG.ID});
    defer f.finish();

    f.pool.close();
    try expect(m.pool.getWaitResult(f.pool, o.MSG.ID, null) == .closed);
}

test "getWaitResult: an unknown identity is its own variant" {
    var f: Fixture = undefined;
    try f.start(&.{o.MSG.ID});
    defer f.finish();

    try expect(m.pool.getWaitResult(f.pool, o.NOTE.ID, 0) == .unknown_identity);
}

test "getWaitFuture: await gives the item another context put" {
    var f: Fixture = undefined;
    try f.start(&.{o.MSG.ID});
    defer f.finish();

    var fut = try f.pool.getWaitFuture(o.MSG.ID, null);

    var slot: m.inner.Slot = null;
    try f.pool.get(o.MSG.ID, .new_only, &slot);
    try f.pool.put(&slot);

    const r = fut.await(f.io);
    try expect(r == .anchor);

    var back: m.inner.Slot = r.anchor;
    o.releaseSlot(&back, alloc, f.io);
}

test "getWaitFuture: a close ends the wait with closed" {
    var f: Fixture = undefined;
    try f.start(&.{o.MSG.ID});
    defer f.finish();

    var fut = try f.pool.getWaitFuture(o.MSG.ID, null);
    f.pool.close();

    try expect(fut.await(f.io) == .closed);
}

const alloc = std.testing.allocator;
const expect = std.testing.expect;
const h = @import("hooks.zig");
const m = @import("matryoshka");
const o = @import("parents.zig");
const Io = std.Io;
const std = @import("std");
