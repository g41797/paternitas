// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: A Master with a pool
//!
//! Parents come from a pool, travel through a mailbox, and go back.
//!
//! - Keep a pool, with hooks, and a mailbox in the Master.
//! - Get three parents from the pool, set their Event data, and send each one:
//!   `sendItems`.
//! - Loop on `mbx.receive` in the worker, and put each parent back.
//! - Shut down: cancel the worker, then `destroy` closes the pool and the
//!   mailbox, in that order.
//!
//! ```
//!  master ──pl.get──► Slot ──mbx.send──► mailbox
//!                                            │ worker (io.concurrent)
//!                                            │ mbx.receive ──► Slot
//!                                            │ pl.put (defer) ──► pool
//!  fut.cancel ──► the worker stops at its next mbx.receive
//!  master.destroy ──► pl.close ──► mbx.close ──► release what is left
//! ```
//!

pub fn master_with_pool(allocator: std.mem.Allocator, io: std.Io) !void {
    const master = try MasterWithPool.init(allocator, io);
    defer master.destroy();
    try master.run();
}

const WorkerCtx = struct {
    mbx: *Mbox,
    pl: *Pool,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        defer ctx.pl.put(&slot) catch {};
        ctx.mbx.receive(&slot, null) catch return;
    }
}

const MasterWithPool = struct {
    fn run(self: *MasterWithPool) !void {
        try self.sendItems();
        var fut = try self.io.concurrent(workerFn, .{&self.worker_ctx});
        fut.cancel(self.io) catch {};
        std.log.info("master: worker stopped", .{});
    }

    fn sendItems(self: *MasterWithPool) !void {
        for (0..3) |i| {
            var slot: Slot = null;
            defer self.pl.put(&slot) catch {};
            try self.pl.get(parents.Event.EventHelper.ID, .available_or_new, &slot);
            const ev = parents.Event.EventHelper.mustFromSlot(&slot);
            ev.code = @intCast(i + 1);
            std.log.info("master: sending Event code={d}", .{ev.code});
            try self.mbx.send(&slot);
        }
    }

    allocator: std.mem.Allocator,
    io: std.Io,
    pool_ctx: hooks.AlwaysCreateHooks,
    ids: [1]matryoshka.inner.TypeId,
    pl: *Pool,
    mbx: *Mbox,
    worker_ctx: WorkerCtx,

    fn init(allocator: std.mem.Allocator, io: std.Io) !*MasterWithPool {
        const self = try allocator.create(MasterWithPool);
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

        var mbx_slot: Slot = null;
        try matryoshka.mbox.new(allocator, io, &mbx_slot);
        self.mbx = Mbox.moveFromSlot(&mbx_slot).?;

        self.worker_ctx = .{ .mbx = self.mbx, .pl = self.pl };
        return self;
    }

    fn destroy(self: *MasterWithPool) void {
        self.pl.close();
        self.pl.destroy();
        var rem: Queue = self.mbx.close();
        parents.destroyQueue(&rem, self.allocator, self.io);
        self.mbx.destroy();
        self.allocator.destroy(self);
    }
};

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Pool = matryoshka.Pool;
const Slot = matryoshka.inner.Slot;
const Queue = matryoshka.queue.Queue;
