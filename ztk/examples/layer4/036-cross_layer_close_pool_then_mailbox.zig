// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Close the pool, then the mailbox
//!
//! Close in this order, and every parent is still released.
//!
//! - Put two parents in the pool, and one in the mailbox.
//! - Close the pool. `on_close` releases its two: `closePool`.
//! - Close the mailbox. Release the one parent it returns:
//!   `closeMailboxAndRelease`.
//! - Check that all three were released.
//!
//! ```
//!  pool (2 parents)    mailbox (1 parent)
//!  │
//!  pl.close ──► on_close ──► destroyQueue (2 released)
//!  mbx.close ──► Queue (1 parent)
//!  popFirst ──► destroySlot
//!  │
//!  All 3 parents released.
//! ```
//!

pub fn close_ordering_pool_then_mailbox(allocator: std.mem.Allocator, io: std.Io) !void {
    var pool_ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, pool_ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;

    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;

    try seedPool(pl, N_POOL);
    try seedMailbox(mbx, allocator, io, N_MAILBOX);

    std.log.info("before close: {d} in pool, {d} in mailbox", .{ N_POOL, N_MAILBOX });

    closePool(pl);

    const released = closeMailboxAndRelease(mbx, allocator, io);
    std.log.info("Mbox.close: walked queue, released {d} mailbox parents", .{released});

    try helpers.expect(error.CrossLayerCloseOrderFailed, released == N_MAILBOX, "mailbox parent count mismatch");
    std.log.info("done: close pool-then-mailbox — {d}+{d} parents cleaned up, no leaks", .{ N_POOL, N_MAILBOX });
}

const N_POOL: usize = 2;
const N_MAILBOX: usize = 1;

fn seedPool(pl: *Pool, count: usize) !void {
    var slots: [N_POOL]Slot = @splat(null);
    for (0..count) |i| {
        try pl.get(parents.Event.EventHelper.ID, .new_only, &slots[i]);
        parents.Event.EventHelper.mustFromSlot(&slots[i]).code = @intCast(i + 1);
    }
    for (0..count) |i| try pl.put(&slots[i]);
}

fn seedMailbox(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io, count: usize) !void {
    for (0..count) |i| {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(alloc, io, &slot);
        try parents.Event.EventHelper.create(alloc, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(100 + i);
        try mbx.send(&slot);
    }
}

fn closePool(pl: *Pool) void {
    pl.close();
    pl.destroy();
    std.log.info("Pool.close: on_close released {d} pool parents", .{N_POOL});
}

fn closeMailboxAndRelease(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) usize {
    var rem: Queue = mbx.close();
    var released: usize = 0;
    while (rem.popFirst()) |anchor| {
        var slot: Slot = anchor;
        parents.destroySlot(&slot, alloc, io);
        released += 1;
    }
    mbx.destroy();
    return released;
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
