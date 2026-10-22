// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Pool fan-in: many workers return.
//!
//! - Seed the pool with N empty containers, one per worker mailbox.
//! - dispatch fills each container from the Master's job array, sends it to its worker.
//! - Each worker doubles the value, writes it to its results slot, returns the
//!   (now-processed) container to the pool for reuse.
//! - on_put resets the container's data on return — the pool lends reusable
//!   containers, it does not carry results back. Results travel through a
//!   dedicated results array instead, written before each worker's container
//!   goes back to the pool.
//! - collectResults sums the N results array entries after all workers finish.
//!
//!
//! ```
//!  Master jobs: [10, 20, 30]
//!  pool (N empty containers seeded)
//!  │
//!  master: pl.get ──► fill from jobs ──► mbx.send ──► mbx[0..N]
//!                                                              │ worker[i] (io.concurrent)
//!                                                              │ mbx.receive ──► process ──► results[i] ──► pl.put (on_put resets) ──► pool
//!  master: fut[i].await ──► all workers done
//!  master: sum results[0..N] ──► verify results
//!  pl.close ──► on_close ──► destroyQueue
//! ```
//!
//!  Transfers: Master jobs → pool containers → worker mailboxes → workers → pool → master.
//!  Pool parents are empty containers: Master fills from jobs, worker writes the result aside.
//!

pub fn pool_fan_in_many_workers_return(allocator: std.mem.Allocator, io: std.Io) !void {
    const master = try PoolFanInMaster.init(allocator, io);
    defer master.destroy();
    try master.run();
}

const N: usize = 3;

// Job values — the Master's own array, separate from pool containers.
const jobs = [N]i32{ 10, 20, 30 };

const WorkerCtx = struct {
    mbx: *Mbox,
    pl: *Pool,
    result: *i32,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    var slot: Slot = null;
    ctx.mbx.receive(&slot, null) catch return;
    defer ctx.pl.put(&slot) catch unreachable;
    const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
    ev.code *= 2;
    ctx.result.* = ev.code;
    std.log.info("worker: processed job, result code={d}", .{ev.code});
}

const PoolFanInMaster = struct {
    fn run(self: *PoolFanInMaster) !void {
        try self.seedPool();
        try self.dispatch();
        try self.awaitWorkers();
        const result_sum: i32 = self.collectResults();
        try helpers.expect(error.PoolFanInFailed, result_sum == 120, "wrong result sum");
        std.log.info("fan-in: {d} results — Master jobs → pool → worker mailboxes → results array → master", .{N});
    }

    fn seedPool(self: *PoolFanInMaster) !void {
        for (0..N) |_| {
            var slot: Slot = null;
            try self.pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
            try self.pl.put(&slot);
        }
    }

    fn dispatch(self: *PoolFanInMaster) !void {
        for (0..N) |i| {
            var slot: Slot = null;
            try self.pl.get(parents.Event.EventHelper.ID, .available_only, &slot);
            const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
            ev.code = jobs[i];
            std.log.info("master: filled container with job code={d}, sending to worker {d}", .{ ev.code, i });
            try self.mbxs[i].send(&slot);
        }
    }

    fn awaitWorkers(self: *PoolFanInMaster) !void {
        for (0..N) |i| try self.futs[i].await(self.io);
    }

    fn collectResults(self: *PoolFanInMaster) i32 {
        var result_sum: i32 = 0;
        for (self.results) |r| {
            result_sum += r;
            std.log.info("master: result code={d}", .{r});
        }
        return result_sum;
    }

    allocator: std.mem.Allocator,
    io: std.Io,
    pl: *Pool,
    pool_ctx: hooks.AlwaysCreateHooks,
    ids: [1]TypeId,
    mbxs: [N]*Mbox,
    ctxs: [N]WorkerCtx,
    futs: [N]std.Io.Future(anyerror!void),
    results: [N]i32,

    fn init(allocator: std.mem.Allocator, io: std.Io) !*PoolFanInMaster {
        const self = try allocator.create(PoolFanInMaster);
        errdefer allocator.destroy(self);
        self.allocator = allocator;
        self.io = io;
        self.pool_ctx = .{ .alloc = allocator, .io = io };
        self.ids = .{parents.Event.EventHelper.ID};
        self.results = .{0} ** N;

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
            self.ctxs[i] = .{ .mbx = self.mbxs[i], .pl = self.pl, .result = &self.results[i] };
            self.futs[i] = try io.concurrent(workerFn, .{&self.ctxs[i]});
        }
        return self;
    }

    fn destroy(self: *PoolFanInMaster) void {
        for (0..N) |i| {
            var rem: Queue = self.mbxs[i].close();
            parents.destroyQueue(&rem, self.allocator, self.io);
            self.mbxs[i].destroy();
        }
        self.pl.close();
        self.pl.destroy();
        self.allocator.destroy(self);
    }
};

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
