// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: A Master with several workers
//!
//! Three workers share one mailbox.
//!
//! - Start three workers in an `Io.Group`.
//! - Send three Events. The workers race for them: `sendItems`.
//! - Close the mailbox, release what is left, and wait for the group:
//!   `awaitAll`.
//! - Cancel the group on `defer`, in case a worker still runs.
//!
//! ```
//!  master ──Event×3──► mailbox ──► worker A (Io.Group)
//!                            ├──► worker B  (each parent goes to one)
//!                            └──► worker C
//!  mbx.close ──► destroyQueue ──► group.await
//! ```
//!

pub fn multi_worker_master(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var worker_ctxs: [3]WorkerCtx = undefined;
    var group: Io.Group = .init;
    defer group.cancel(io);
    try spawnWorkers(mbx, allocator, io, &group, &worker_ctxs);
    try sendItems(mbx, allocator, io);
    try awaitAll(mbx, allocator, io, &group);
    std.log.info("master: all workers done", .{});
}

const WorkerCtx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
};

fn workerFn(ctx: *WorkerCtx) error{Canceled}!void {
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        ctx.mbx.receive(&slot, null) catch |err| switch (err) {
            error.Canceled => return error.Canceled,
            error.Closed, error.Timeout, error.Wakeup => return,
        };
    }
}

fn spawnWorkers(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io, group: *Io.Group, ctxs: *[3]WorkerCtx) !void {
    for (ctxs) |*ctx| {
        ctx.* = .{ .mbx = mbx, .alloc = alloc, .io = io };
        try group.concurrent(io, workerFn, .{ctx});
    }
}

fn sendItems(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    for (0..3) |i| {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(alloc, io, &slot);
        try parents.Event.EventHelper.create(alloc, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 1);
        try mbx.send(&slot);
        std.log.info("master: sent Event code={d}", .{i + 1});
    }
}

fn awaitAll(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io, group: *Io.Group) !void {
    var remaining: Queue = mbx.close();
    parents.destroyQueue(&remaining, alloc, io);
    try group.await(io);
}

const parents = @import("../parents/parents.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
const Io = std.Io;
const Queue = matryoshka.queue.Queue;
