// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Pool → Mailbox → Pool roundtrip.
//!
//! - getAndSend: pl.get fills a parent, mbx.send transfers it.
//! - receiveAndVerify: mbx.receive gets it back, verifies same pointer and data.
//! - verifyRecycle: pl.put then available_only get confirms the same pointer recycles.
//! - Single-threaded — no concurrency needed to prove the transfer path.
//!
//!
//! ```
//!  pl.get ──► slot (code=42, ptr=P)
//!  mbx.send ──► mailbox holds P
//!  mbx.receive ──► slot (same ptr P, code still 42)
//!  verify code==42, ptr==P
//!  pl.put ──► pool store (P recycled)
//!  pl.get (.available_only) ──► slot (same ptr P)
//!  verify ptr==P ──► pl.put ──► pool
//!  pl.close ──► on_close ──► released
//! ```
//!

pub fn pool_mailbox_pool_roundtrip(allocator: std.mem.Allocator, io: std.Io) !void {
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
    const sent_ptr = try ctx.getAndSend();
    try ctx.receiveAndVerify(sent_ptr);
    try ctx.verifyRecycle(sent_ptr);
}

const Ctx = struct {
    pl: *Pool,
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,

    fn getAndSend(self: *Ctx) !*parents.Event {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, self.alloc, self.io);
        try self.pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
        ev.code = 42;
        std.log.info("Pool.get: code={d} ptr={*}", .{ ev.code, ev });
        try self.mbx.send(&slot);
        return ev;
    }

    fn receiveAndVerify(self: *Ctx, sent_ptr: *parents.Event) !void {
        var slot: Slot = null;
        try self.mbx.receive(&slot, null);
        defer self.pl.put(&slot) catch {};
        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
        try helpers.expect(error.CrossLayerRoundtripFailed, ev.code == 42, "wrong code after receive");
        try helpers.expect(error.CrossLayerRoundtripFailed, ev == sent_ptr, "not same pointer after receive");
        std.log.info("Mbox.receive: code={d} same_ptr={}", .{ ev.code, ev == sent_ptr });
    }

    fn verifyRecycle(self: *Ctx, sent_ptr: *parents.Event) !void {
        var slot: Slot = null;
        defer self.pl.put(&slot) catch {};
        try self.pl.get(parents.Event.EventHelper.ID, .available_only, &slot);
        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
        try helpers.expect(error.CrossLayerRoundtripFailed, ev == sent_ptr, "not same pointer on second get");
        std.log.info("Pool.get (recycled): same_ptr={} — pool→mailbox→pool roundtrip complete", .{ev == sent_ptr});
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
