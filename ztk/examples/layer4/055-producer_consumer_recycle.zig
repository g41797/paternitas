// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Producer and consumer, with reuse
//!
//! The consumer gives the parent back to the pool. The producer gets it again.
//!
//! - Get a parent, fill it, and send it: `produce`.
//! - Receive it, check it is the same pointer, and put it back: `consume`.
//! - Get with `.available_only`. It is the same parent, but `on_put` reset its
//!   data: `verifyRecycle`.
//!
//! ```
//!  pl.get ──► Slot ──► the producer fills it (code=1)
//!  mbx.send ──► mailbox
//!  │
//!  consumer: mbx.receive ──► Slot (the same pointer)
//!            check code==1
//!            pl.put ──► on_put resets the data ──► pool
//!  │
//!  pl.get ──► Slot (the same pointer, data reset)
//!  check the reset ──► pl.put ──► pool
//!  pl.close ──► on_close ──► destroyQueue
//! ```
//!

pub fn producer_consumer_with_recycling(allocator: std.mem.Allocator, io: std.Io) !void {
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
    const sent_ptr = try ctx.produce();
    try ctx.consume(sent_ptr);
    try ctx.verifyRecycle();
}

const Ctx = struct {
    pl: *Pool,
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,

    fn produce(self: *Ctx) !*parents.Event {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, self.alloc, self.io);
        try self.pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
        ev.code = 1;
        std.log.info("producer: get from pool, fill code={d}", .{ev.code});
        try self.mbx.send(&slot);
        return ev;
    }

    fn consume(self: *Ctx, sent_ptr: *parents.Event) !void {
        var slot: Slot = null;
        try self.mbx.receive(&slot, null);
        defer self.pl.put(&slot) catch unreachable;
        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
        try helpers.expect(error.ProducerConsumerFailed, ev.code == 1, "wrong code after receive");
        try helpers.expect(error.ProducerConsumerFailed, ev == sent_ptr, "not same pointer");
        std.log.info("consumer: received code={d}, same pointer={}", .{ ev.code, ev == sent_ptr });
    }

    fn verifyRecycle(self: *Ctx) !void {
        var slot: Slot = null;
        defer self.pl.put(&slot) catch unreachable;
        try self.pl.get(parents.Event.EventHelper.ID, .available_only, &slot);
        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
        try helpers.expect(error.ProducerConsumerFailed, ev.code == 0, "expected reset default, not the producer's value");
        std.log.info("recycled parent: code={d} (reset by on_put) — pool → producer → mailbox → consumer → pool cycle complete", .{ev.code});
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
