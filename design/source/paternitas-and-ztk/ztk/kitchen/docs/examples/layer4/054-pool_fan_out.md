# Pool fan-out: many workers acquire

## Description

Pool fan-out: many workers acquire.

- Seed the pool with 3 parents.
- Spawn 3 workers, each calls get with available_only — no parent is shared.
- Verify all 3 workers got a parent, then all 3 put it back.

## Diagram

```
 master: pl.get (×3, new_only) ──► pool (3 parents seeded)
 │
 worker1 ──pl.get (.available_only)──► slot ──► verify ──► pl.put
 worker2 ──pl.get (.available_only)──► slot ──► verify ──► pl.put
 worker3 ──pl.get (.available_only)──► slot ──► verify ──► pl.put
 │
 fut1.await + fut2.await + fut3.await
 pl.close ──► on_close ──► destroyQueue
```

## Source

```zig
pub fn pool_fan_out_many_workers_acquire(allocator: std.mem.Allocator, io: std.Io) !void {
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
    try spawnAndAwaitWorkers(pl, allocator, io);
    std.log.info("fan-out: 1 pool seeded with 3 parents → 3 workers each got 1", .{});
}

const WorkerCtx = struct {
    pl: *Pool,
    alloc: std.mem.Allocator,
    got: bool = false,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    var slot: Slot = null;
    defer ctx.pl.put(&slot) catch unreachable;
    try ctx.pl.get(parents.Event.EventHelper.ID, .available_only, &slot);
    const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
    std.log.info("worker: got Event code={d}", .{ev.code});
    ctx.got = true;
}

fn seedPool(pl: *Pool) !void {
    for (0..3) |i| {
        var slot: Slot = null;
        try pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 10);
        try pl.put(&slot);
    }
}

fn spawnAndAwaitWorkers(pl: *Pool, alloc: std.mem.Allocator, io: std.Io) !void {
    var ctx1: WorkerCtx = .{ .pl = pl, .alloc = alloc };
    var ctx2: WorkerCtx = .{ .pl = pl, .alloc = alloc };
    var ctx3: WorkerCtx = .{ .pl = pl, .alloc = alloc };
    var fut1 = try io.concurrent(workerFn, .{&ctx1});
    var fut2 = try io.concurrent(workerFn, .{&ctx2});
    var fut3 = try io.concurrent(workerFn, .{&ctx3});
    try fut1.await(io);
    try fut2.await(io);
    try fut3.await(io);
    const all_got = ctx1.got and ctx2.got and ctx3.got;
    try helpers.expect(error.PoolFanOutFailed, all_got, "not all workers got a parent");
}

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Slot = matryoshka.inner.Slot;
```
