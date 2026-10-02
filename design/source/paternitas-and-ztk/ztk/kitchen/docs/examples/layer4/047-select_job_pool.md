# Job pool pattern

## Description

Job pool pattern.

- Master pre-loads a job queue, seeds the pool with N empty containers.
- dispatchJobs: pool availability (getWaitResult) gates dispatch to N workers.
- Each worker doubles its job's code, returns the container via pl.put.
- shutdown closes all worker mailboxes, awaits every worker future.

## Diagram

```
 Master job queue: [{code=10},{code=20},{code=30}] (pre-loaded before loop)
 pool (N empty containers seeded)
 │ getWaitResult — triggers when a container is returned by a worker (or initially available)
 ▼
 Select(MasterEvent)
 │
 .pool_ev .item ──► pop job from Master queue ──► fill container ──► mbx.send ──► mbx[worker_i]
                ──► re-spawn getWaitResult (until queue exhausted)
                ──► break (queue empty — no more jobs to dispatch)
 │
 worker[i]: mbx.receive ──► process (code *= 2) ──► pl.put ──► pool (triggers next pool_ev)
 │
 master: mbx.close (×N) ──► workers exit ──► futs.await
 pl.close ──► on_close ──► freeList (returns all remaining containers)
```

## Source

```zig
pub fn job_pool_pattern(allocator: std.mem.Allocator, io: std.Io) !void {
    const master = try JobPoolMaster.init(allocator, io);
    defer master.destroy();
    try master.run();
}

const N: usize = 3;

// Master's pre-loaded job queue — separate from pool containers.
const jobs = [N]i32{ 10, 20, 30 };

const WorkerCtx = struct {
    mbx: *Mbox,
    pl: *Pool,
    id: usize,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        ctx.mbx.receive(&slot, null) catch return;
        defer ctx.pl.put(&slot) catch unreachable; // return container to pool — triggers next pool_ev
        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
        ev.code *= 2; // process: double the job value
        std.log.info("worker {d}: processed job, result code={d}", .{ ctx.id, ev.code });
    }
}

const MasterEvent = union(enum) {
    pool_ev: Pool.Result,
};

const JobPoolMaster = struct {
    fn run(self: *JobPoolMaster) !void {
        try self.seedPool();
        const job_idx: usize = try self.dispatchJobs();
        try self.shutdown();
        try helpers.expect(error.SelectJobPoolFailed, job_idx == N, "not all jobs dispatched");
        std.log.info("done: {d} jobs dispatched — Master queue → pool containers → worker mailboxes (pool gated)", .{job_idx});
    }

    fn seedPool(self: *JobPoolMaster) !void {
        for (0..N) |_| {
            var slot: Slot = null;
            try self.pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
            try self.pl.put(&slot);
        }
    }

    fn dispatchJobs(self: *JobPoolMaster) !usize {
        var buf: [N + 1]MasterEvent = undefined;
        var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(self.io, &buf);
        try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ self.pl, parents.Event.EventHelper.ID, null });

        var job_idx: usize = 0;
        var worker_i: usize = 0;

        while (job_idx < N) {
            const event: MasterEvent = try sel.await();
            switch (event) {
                .pool_ev => |r| switch (r) {
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
                        ev.code = jobs[job_idx];
                        std.log.info("master: dispatching job {d} (code={d}) to worker {d}", .{ job_idx, ev.code, worker_i });
                        try self.mbxs[worker_i].send(&slot);
                        job_idx += 1;
                        worker_i = (worker_i + 1) % N;
                        if (job_idx < N) {
                            try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ self.pl, parents.Event.EventHelper.ID, null });
                        }
                    },
                    .closed, .canceled, .timeout, .unknown_identity => break,
                },
            }
        }
        sel.cancelDiscard();
        return job_idx;
    }

    fn shutdown(self: *JobPoolMaster) !void {
        for (0..N) |i| {
            var rem: Queue = self.mbxs[i].close();
            parents.destroyQueue(&rem, self.allocator, self.io);
        }
        for (0..N) |i| try self.futs[i].await(self.io);
    }

    allocator: std.mem.Allocator,
    io: std.Io,
    pl: *Pool,
    pool_ctx: hooks.AlwaysCreateHooks,
    ids: [1]TypeId,
    mbxs: [N]*Mbox,
    ctxs: [N]WorkerCtx,
    futs: [N]std.Io.Future(anyerror!void),

    fn init(allocator: std.mem.Allocator, io: std.Io) !*JobPoolMaster {
        const self = try allocator.create(JobPoolMaster);
        errdefer allocator.destroy(self);
        self.allocator = allocator;
        self.io = io;
        self.pool_ctx = .{ .alloc = allocator, .io = io };
        self.ids = .{parents.Event.EventHelper.ID};

        var pl_slot: Slot = null;
        try matryoshka.pool.new(allocator, io, &self.ids, self.pool_ctx.poolHooks(), &pl_slot);
        self.pl = Pool.moveFromSlot(&pl_slot).?;
        errdefer {
            self.pl.close();
            self.pl.destroy();
        }
        var created: usize = 0;
        errdefer for (0..created) |i| {
            var rem: Queue = self.mbxs[i].close();
            parents.destroyQueue(&rem, allocator, io);
            self.mbxs[i].destroy();
        };
        for (0..N) |i| {
            var mbx_slot: Slot = null;
            try matryoshka.mbox.new(allocator, io, &mbx_slot);
            self.mbxs[i] = Mbox.moveFromSlot(&mbx_slot).?;
            created += 1;
            self.ctxs[i] = .{ .mbx = self.mbxs[i], .pl = self.pl, .id = i };
            self.futs[i] = try io.concurrent(workerFn, .{&self.ctxs[i]});
        }
        return self;
    }

    fn destroy(self: *JobPoolMaster) void {
        self.pl.close();
        self.pl.destroy();
        for (0..N) |i| self.mbxs[i].destroy();
        self.allocator.destroy(self);
    }
};

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
```
