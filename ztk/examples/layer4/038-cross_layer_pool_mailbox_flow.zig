// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Pool and mailbox, the smallest flow
//!
//! One parent out of the pool, through a mailbox, and back. One thread.
//!
//! - Get a parent from the pool, and send it: `getAndSend`.
//! - Receive it, and put it back: `receiveAndVerify`.
//!
//! ```
//!  pl.get ──► Slot (code=7)
//!  mbx.send ──► the mailbox has it
//!  mbx.receive ──► Slot (the same parent)
//!  pl.put ──► the pool keeps it
//!  pl.close ──► on_close ──► released
//! ```
//!

pub fn pool_mailbox_flow(allocator: std.mem.Allocator, io: std.Io) !void {
    var pool_ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, pool_ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var ctx: Ctx = .{ .pl = pl, .mbx = mbx, .alloc = allocator, .io = io };
    try ctx.getAndSend();
    try ctx.receiveAndVerify();
}

const Ctx = struct {
    pl: *Pool,
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,

    fn getAndSend(self: *Ctx) !void {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(self.alloc, self.io, &slot);
        try self.pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = 7;
        std.log.info("Pool.get: code={d}", .{7});
        try self.mbx.send(&slot);
    }

    fn receiveAndVerify(self: *Ctx) !void {
        var slot: Slot = null;
        try self.mbx.receive(&slot, null);
        defer self.pl.put(&slot) catch {};
        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
        try helpers.expect(error.CrossLayerFlowFailed, ev.code == 7, "wrong code after receive");
        std.log.info("Mbox.receive: code={d} — pool→mailbox→pool flow complete", .{ev.code});
    }
};

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
