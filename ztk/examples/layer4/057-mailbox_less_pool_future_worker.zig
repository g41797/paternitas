// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: A pool and a future, no mailbox
//!
//! One worker and one pool. The pool is all the coordination there is.
//!
//! - Put one empty container in the pool, and start one worker. Pass it N.
//! - Loop N times in the worker: `pl.getWait`, write its counter into the
//!   container, `pl.put`.
//! - Wait for the worker with `fut.await`.
//!
//! The container is a place to work, not a carrier of data.
//!
//! ```
//!  pool (1 empty container: code=0)
//!  │ io.concurrent (n=3, passed at the start)
//!  ▼
//!  worker loop (n times):
//!    pl.getWait ──► Slot ──► ev.code = the counter ──► pl.put ──► pool
//!  │
//!  fut.await ──► the master reads ctx.counter (= n)
//!  pl.close ──► on_close ──► released
//! ```
//!

pub fn pool_future_simple_worker(allocator: std.mem.Allocator, io: std.Io) !void {
    var pool_ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, pool_ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    try seedContainer(pl);

    var ctx: WorkerCtx = .{ .pl = pl, .id = parents.Event.EventHelper.ID, .n = N };
    var fut: std.Io.Future(anyerror!void) = try io.concurrent(workerFn, .{&ctx});
    try fut.await(io);

    try helpers.expect(error.MailboxLessPoolFutureFailed, ctx.counter == N, "wrong cycle count");
    std.log.info("done: worker completed {d} cycles — counter={d}, pool parent was an empty container, no mailbox needed", .{ N, ctx.counter });
}

const N: usize = 3; // iteration count passed to worker at spawn time

const WorkerCtx = struct {
    pl: *Pool,
    id: TypeId,
    n: usize,
    counter: usize = 0,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    for (0..ctx.n) |_| {
        var slot: Slot = null;
        try ctx.pl.getWait(ctx.id, &slot, null);
        defer ctx.pl.put(&slot) catch unreachable;
        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
        ev.code = @intCast(ctx.counter);
        ctx.counter += 1;
        std.log.info("worker: cycle {d} — wrote counter into empty container (code={d})", .{ ctx.counter, ev.code });
    }
}

fn seedContainer(pl: *Pool) !void {
    var slot: Slot = null;
    try pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
    try pl.put(&slot);
}

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Slot = matryoshka.inner.Slot;
