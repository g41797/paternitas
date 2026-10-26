// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: A minimal Master
//!
//! A Master runs one worker and shuts it down.
//!
//! - Start one worker with `io.concurrent`.
//! - Send three Events into the shared mailbox: `sendItems`.
//! - Close the mailbox, release what is left, and wait for the worker:
//!   `awaitWorker`.
//!
//! The cleanup needs no special call. A plain loop over the returned queue
//! does it.
//!
//! ```
//!  master ──create──► Slot ──mbx.send──► mailbox
//!                                            │ worker (io.concurrent)
//!                                            │ mbx.receive ──► destroySlot
//!  mbx.close ──► remaining queue ──► destroyQueue
//!  fut.await ──► the worker is done
//! ```
//!

pub fn minimal_master(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var ctx: WorkerCtx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    var fut = try io.concurrent(workerFn, .{&ctx});
    try sendItems(mbx, allocator, io);
    try awaitWorker(mbx, allocator, io, &fut);
    std.log.info("master: worker done", .{});
}

const WorkerCtx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        ctx.mbx.receive(&slot, null) catch return;
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

fn awaitWorker(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io, fut: *Io.Future(anyerror!void)) !void {
    var remaining: Queue = mbx.close();
    parents.destroyQueue(&remaining, alloc, io);
    try fut.await(io);
}

const parents = @import("../parents/parents.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
const Io = std.Io;
const Queue = matryoshka.queue.Queue;
