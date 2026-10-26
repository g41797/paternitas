// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Close the mailbox, then the pool
//!
//! What the mailbox returns can go back to a pool that is still open.
//!
//! - Put one parent in the pool, and one in the mailbox.
//! - Close the mailbox. It returns its queue: `closeMailbox`.
//! - Put each parent from that queue back into the open pool:
//!   `returnCloseQueueToPool`.
//! - Close the pool on `defer`. `on_close` releases both.
//!
//! ```
//!  pool (1 parent)    mailbox (1 parent)
//!  │
//!  mbx.close ──► Queue (1 parent)
//!  popFirst ──► Slot ──► pl.put (the pool is still open)
//!  │                         └──► the pool keeps 2 parents
//!  pl.close ──► on_close ──► destroyQueue (both released)
//! ```
//!

pub fn close_ordering_mailbox_then_pool(allocator: std.mem.Allocator, io: std.Io) !void {
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

    try seedPool(pl);
    try seedMailbox(mbx, allocator, io);
    std.log.info("before close: 1 parent in pool, 1 parent in mailbox", .{});

    var rem: Queue = closeMailbox(mbx);
    const returned = try returnCloseQueueToPool(pl, &rem);

    try helpers.expect(error.CrossLayerCloseOrderFailed, returned == 1, "expected 1 parent from mailbox close");
    std.log.info("pool now has 2 parents — Pool.close will release all via on_close", .{});
    // Deferred pl.close calls on_close with both parents.
}

fn seedPool(pl: *Pool) !void {
    var slot: Slot = null;
    try pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
    parents.Event.EventHelper.mustFromSlot(&slot).code = 1;
    try pl.put(&slot);
}

fn seedMailbox(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var slot: Slot = null;
    defer parents.Event.EventHelper.destroy(alloc, io, &slot);
    try parents.Event.EventHelper.create(alloc, io, &slot);
    parents.Event.EventHelper.mustFromSlot(&slot).code = 2;
    try mbx.send(&slot);
}

fn closeMailbox(mbx: *Mbox) Queue {
    const rem: Queue = mbx.close();
    mbx.destroy();
    return rem;
}

fn returnCloseQueueToPool(pl: *Pool, rem: *Queue) !usize {
    var returned: usize = 0;
    while (rem.popFirst()) |anchor| {
        var slot: Slot = anchor;
        std.log.info("mailbox close queue: returning parent to pool (code={d})", .{parents.Event.EventHelper.mustFromSlot(&slot).code});
        try pl.put(&slot);
        returned += 1;
    }
    return returned;
}

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
