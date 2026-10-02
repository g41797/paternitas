// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! getWaitFuture awaited directly.
//!
//! - Seed the pool with one Event.
//! - pl.getWaitFuture returns an Io.Future(Pool.Result), no Select needed.
//! - fut.await blocks until the item is available.
//! - on_put already reset it to defaults when it was seeded — no fixed
//!   value survives a put/get pass, regardless of what was set before put.
//!
//!
//! ```
//!  pl.get ──► slot ──► pl.put ──► on_put resets data ──► pool
//!  │
//!  getWaitFuture ──► Future(Pool.Result)
//!  fut.await ──► Pool.Result .item ──► slot (default data, master owns)
//!  │
//!  pl.put ──► pool ──pl.close──► on_close ──► freeList
//! ```
//!

pub fn get_wait_future_awaited_directly(allocator: std.mem.Allocator, io: std.Io) !void {
    var pool_ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, pool_ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    try seedPool(pl);
    try receiveViaFuture(pl, io);
}

fn seedPool(pl: *Pool) !void {
    var slot: Slot = null;
    try pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
    parents.Event.EventHelper.mustFromSlot(&slot).code = 7;
    try pl.put(&slot); // on_put resets code back to 0 — set value doesn't survive
}

fn receiveViaFuture(pl: *Pool, io: std.Io) !void {
    var fut: std.Io.Future(Pool.Result) = try pl.getWaitFuture(parents.Event.EventHelper.ID, null);
    const result: Pool.Result = fut.await(io);

    switch (result) {
        .anchor => |handle| {
            var slot: Slot = handle;
            defer pl.put(&slot) catch unreachable;
            const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
            try helpers.expect(error.GetWaitFutureDirectFailed, ev.code == 0, "expected reset default, not the pre-put value");
            std.log.info("getWaitFuture direct: got Event code={d} (reset by on_put)", .{ev.code});
        },
        else => return error.GetWaitFutureDirectFailed,
    }
}

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Pool = matryoshka.Pool;
const TypeId = matryoshka.inner.TypeId;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
