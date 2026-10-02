// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Backpressure pool.
//!
//! - 4 tasks concurrently pl.get and pl.put, 8 iterations each.
//! - on_put caps the pool at 2 parents, releases anything past the cap.
//! - After all tasks finish, empty the pool and count what remains.
//! - Verify the remaining count never exceeds the cap.
//!
//!
//! ```
//!  CappedPool (cap=2)
//!       │ pl.get (available_or_new) — 4 tasks concurrently
//!       ▼
//!  worker task (processes)
//!       │ pl.put (defer) — on_put releases excess above cap
//!       ▼
//!  CappedPool (≤ cap parents retained)
//! ```
//!

pub fn backpressure_pool(allocator: std.mem.Allocator, io: std.Io) !void {
    const cap: usize = 2;
    var pool_ctx: hooks.CappedPoolHooks = .{ .alloc = allocator, .cap = cap, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, pool_ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    var workers: [task_count]WorkerCtx = undefined;
    var futures: [task_count]std.Io.Future(void) = undefined;

    for (&workers, &futures) |*wctx, *f| {
        wctx.* = .{ .pl = pl };
        f.* = try io.concurrent(workerFn, .{wctx});
    }

    for (&futures) |*f| f.await(io);

    // Take what remains, to count it.
    var in_pool: usize = 0;
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        pl.get(parents.Event.EventHelper.ID, .available_only, &slot) catch break;
        in_pool += 1;
    }

    std.log.info("capped pool (cap={d}): {d} parents remain after {d} tasks x {d} iterations", .{
        cap, in_pool, task_count, iterations,
    });
    try helpers.expect(error.CappedPoolFailed, in_pool <= cap, "pool exceeded cap");
}

const task_count = 4;
const iterations = 8;

const WorkerCtx = struct {
    pl: *Pool,
};

fn workerFn(ctx: *WorkerCtx) void {
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        var slot: Slot = null;
        defer ctx.pl.put(&slot) catch {};
        ctx.pl.get(parents.Event.EventHelper.ID, .available_or_new, &slot) catch return;
        std.log.debug("worker: got parent", .{});
    }
}

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Slot = matryoshka.inner.Slot;
