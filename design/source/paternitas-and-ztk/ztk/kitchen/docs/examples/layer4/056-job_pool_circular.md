# Job pool circular flow

## Description

Job pool circular flow.

- Master pre-loads a job list, seeds the pool with 1 container.
- runEventLoop: pool availability triggers the next dispatch from the job list.
- Worker doubles the value, returns the container — which triggers the next dispatch.
- Loop ends once all jobs are dispatched and the last result returns.

Transfers (circular):

## Diagram

```
 Master job list: [{code=10},{code=20},{code=30}]
 pool (1 empty container seeded)
 │ getWaitResult drives pace
 ▼
 master: fill container from job list ──► mbx.send ──► mbx
                                                             │ worker
                                                             │ process (code *= 2) ──► pl.put ──► pool
 pool triggers again ──► master dispatches next job (or breaks when all N sent + last returned)
```

## Source

```zig
pub fn job_pool_circular_flow(allocator: std.mem.Allocator, io: std.Io) !void {
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
    defer mbx.destroy();

    try seedContainer(pl);

    var ctx: Ctx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    var worker_ctx: WorkerCtx = .{ .mbx = mbx, .pl = pl };
    var buf: [4]MasterEvent = undefined;
    var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);
    var worker_fut = try ctx.spawnWorkerAndSetupSelect(pl, &worker_ctx, &sel);

    var job_idx: usize = 0;
    var completed: usize = 0;
    try ctx.runEventLoop(pl, &sel, &job_idx, &completed);

    try ctx.closeMailboxAndAwait(&worker_fut);

    try helpers.expect(error.JobPoolCircularFailed, completed == N, "did not complete all jobs");
    std.log.info("done: {d} jobs — Master list → pool container → mailbox → worker → pool (circular)", .{completed});
}

const N: usize = 3;

const jobs = [N]i32{ 10, 20, 30 };

const MasterEvent = union(enum) {
    pool_ev: Pool.Result,
};

const WorkerCtx = struct {
    mbx: *Mbox,
    pl: *Pool,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        ctx.mbx.receive(&slot, null) catch return;
        defer ctx.pl.put(&slot) catch unreachable;
        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
        ev.code *= 2;
        std.log.info("worker: processed job, result code={d}", .{ev.code});
    }
}

const Ctx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,

    fn spawnWorkerAndSetupSelect(self: *Ctx, pl: *Pool, worker_ctx: *WorkerCtx, sel: *std.Io.Select(MasterEvent)) !Io.Future(anyerror!void) {
        const fut = try self.io.concurrent(workerFn, .{worker_ctx});
        try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ pl, parents.Event.EventHelper.ID, null });
        return fut;
    }

    fn runEventLoop(self: *Ctx, pl: *Pool, sel: *std.Io.Select(MasterEvent), job_idx: *usize, completed: *usize) !void {
        while (true) {
            const event: MasterEvent = try sel.await();
            switch (event) {
                .pool_ev => |r| switch (r) {
                    .anchor => |handle| {
                        if (job_idx.* < N) {
                            var slot: Slot = handle;
                            const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
                            ev.code = jobs[job_idx.*];
                            std.log.info("master: dispatching job {d} (code={d})", .{ job_idx.*, ev.code });
                            job_idx.* += 1;
                            // A refused send leaves the item in the slot.
                            // It came from the pool, so it goes back there.
                            self.mbx.send(&slot) catch |err| {
                                try pl.put(&slot);
                                return err;
                            };
                            try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ pl, parents.Event.EventHelper.ID, null });
                        } else {
                            const ev: *parents.Event = parents.Event.EventHelper.mustFromAnchor(handle);
                            completed.* = job_idx.*;
                            std.log.info("master: last result code={d}, all {d} jobs complete", .{ ev.code, completed.* });
                            var slot: Slot = handle;
                            try pl.put(&slot);
                            break;
                        }
                    },
                    .closed, .canceled, .timeout, .unknown_identity => break,
                },
            }
        }
        sel.cancelDiscard();
    }

    fn closeMailboxAndAwait(self: *Ctx, worker_fut: *Io.Future(anyerror!void)) !void {
        var rem: Queue = self.mbx.close();
        parents.destroyQueue(&rem, self.alloc, self.io);
        try worker_fut.await(self.io);
    }
};

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
const Mbox = matryoshka.Mbox;
const Pool = matryoshka.Pool;
const TypeId = matryoshka.inner.TypeId;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
const Io = std.Io;
```
