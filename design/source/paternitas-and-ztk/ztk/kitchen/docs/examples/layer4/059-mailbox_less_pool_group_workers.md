# Pool + Group: worker pool

## Description

Pool + Group: worker pool.

- Pool seeded with N empty containers, N workers spawned via Io.Group with a task index each.
- Each worker gets its own container, writes its index, returns it.
- group.cancel stops any workers still running, then pl.close frees the rest.
- No mailbox — each worker's own container is the coordination surface.

Transfers (mailbox-less):

## Diagram

```
 pool (N_WORKERS empty containers seeded — code=0)
 │ Io.Group (N_WORKERS workers, each with own task index at spawn time)
 ├──► worker 0 ──pl.get──► slot ──► ev.code = 0 ──► pl.put ──► pool
 ├──► worker 1 ──pl.get──► slot ──► ev.code = 1 ──► pl.put ──► pool
 └──► worker 2 ──pl.get──► slot ──► ev.code = 2 ──► pl.put ──► pool
 │
 group.cancel ──► any worker that has not yet returned exits (all likely done)
 pl.close ──► on_close ──► destroyQueue (remaining parents freed)
```

## Source

```zig
pub fn pool_group_worker_pool(allocator: std.mem.Allocator, io: std.Io) !void {
    var pool_ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, pool_ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;

    try seedContainers(pl);

    var worker_ctxs: [N_WORKERS]WorkerCtx = undefined;
    var group: Io.Group = .init;
    try spawnWorkers(pl, io, &group, &worker_ctxs);

    std.log.info("master: {d} workers running, {d} empty containers in pool", .{ N_WORKERS, N_WORKERS });
    stopAndClosePool(pl, io, &group);
}

const N_WORKERS: usize = 3;

const WorkerCtx = struct {
    pl: *Pool,
    id: usize,
};

fn seedContainers(pl: *Pool) !void {
    for (0..N_WORKERS) |_| {
        var slot: Slot = null;
        try pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
        try pl.put(&slot);
    }
}

fn workerFn(ctx: *WorkerCtx) error{Canceled}!void {
    var slot: Slot = null;
    defer ctx.pl.put(&slot) catch unreachable;
    ctx.pl.get(parents.Event.EventHelper.ID, .available_or_new, &slot) catch return;
    const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
    ev.code = @intCast(ctx.id);
    std.log.info("worker {d}: wrote task index into empty container (code={d})", .{ ctx.id, ev.code });
}

fn spawnWorkers(pl: *Pool, io: std.Io, group: *Io.Group, ctxs: *[N_WORKERS]WorkerCtx) !void {
    for (ctxs, 0..) |*ctx, i| {
        ctx.* = .{ .pl = pl, .id = i };
        try group.concurrent(io, workerFn, .{ctx});
    }
}

fn stopAndClosePool(pl: *Pool, io: std.Io, group: *Io.Group) void {
    group.cancel(io);
    std.log.info("master: all workers stopped via group.cancel", .{});
    pl.close();
    pl.destroy();
    std.log.info("pool closed: on_close freed any remaining containers — no mailbox needed", .{});
}

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Io = std.Io;
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Slot = matryoshka.inner.Slot;
```
