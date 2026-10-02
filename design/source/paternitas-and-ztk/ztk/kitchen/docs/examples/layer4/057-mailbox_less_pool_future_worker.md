# Pool + Future: simple worker

## Description

Pool + Future: simple worker.

- Master seeds the pool with 1 empty container, spawns one worker with N passed at spawn time.
- Worker loops N times: pl.getWait, writes its own counter into the container, pl.put.
- fut.await blocks until the worker finishes all N cycles.
- No mailbox needed — pool is the only coordination point.

Transfers (mailbox-less):

## Diagram

```
 pool (1 empty container seeded — code=0)
 │ io.concurrent (n=3 passed at spawn time)
 ▼
 worker loop (n cycles):
   pl.getWait ──► slot ──► ev.code = worker counter ──► pl.put ──► pool
 │
 fut.await ──► master reads ctx.counter (= n after all cycles)
 pl.close ──► on_close ──► freed
```

## Source

```zig
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
```
