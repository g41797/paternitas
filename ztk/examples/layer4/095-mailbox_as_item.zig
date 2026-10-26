// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: A worker sends its mailbox back
//!
//! A mailbox is a parent too, so it can travel through another mailbox.
//!
//! - Start a worker with `io.concurrent`. Send it three Events and a
//!   ShutdownCommand.
//! - On the ShutdownCommand, the worker sends its own mailbox to the Master's
//!   inbox.
//! - Check in the Master that the parent is an `Mbox`, and the right one.
//! - Close and destroy the worker's mailbox, then wait for the worker.
//!
//! The mailbox goes in with `toAnchor` and comes out with `fromAnchor`. The id
//! says what it is. The pointer says which one.
//!
//! ```
//!  master ──Event×3 + ShutdownCommand──► worker_mbx ──► worker task
//!                                                          │ handle
//!                                                          │ send worker_mbx ──► master_inbox
//!                                                          ▼ stop
//!  master ◄──worker_mbx (as *Anchor)── master_inbox
//!  master: check the id and the pointer, then close + destroy worker_mbx
//! ```
//!

pub fn worker_finish_signal_via_mailbox_return(allocator: std.mem.Allocator, io: std.Io) !void {
    var master_inbox_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &master_inbox_slot);
    const master_inbox: *Mbox = Mbox.moveFromSlot(&master_inbox_slot).?;
    defer {
        var rem: Queue = master_inbox.close();
        releaseInbox(&rem, allocator, io);
        master_inbox.destroy();
    }

    var worker_mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &worker_mbx_slot);
    const worker_mbx: *Mbox = Mbox.moveFromSlot(&worker_mbx_slot).?;

    try sendJobsAndShutdown(worker_mbx, allocator, io);

    var worker_ctx: WorkerCtx = undefined;
    var fut = try spawnWorker(master_inbox, worker_mbx, &worker_ctx, allocator, io);

    try receiveAndVerify(master_inbox, worker_mbx, allocator, io);
    fut.await(io);
    std.log.info("master: received worker_mbx back — worker finished (processed={d})", .{worker_ctx.processed});
}

const WorkerCtx = struct {
    master_inbox: *Mbox,
    worker_mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
    processed: usize = 0,
};

fn cleanupReturnedMailbox(slot: *Slot, alloc: std.mem.Allocator, io: std.Io) void {
    const returned: *Mbox = Mbox.mustFromSlot(slot);
    slot.* = null;
    var rem: Queue = returned.close();
    parents.destroyQueue(&rem, alloc, io);
    returned.destroy();
}

/// Releases one parent from the master's inbox.
///
/// The inbox carries application parents *and* the worker's mailbox, so the
/// release has to ask which one it is. `Mbox.fromAnchor` is the checking
/// form — it returns null for an application parent instead of panicking.
fn releaseOne(anchor: *Anchor, alloc: std.mem.Allocator, io: std.Io) void {
    if (Mbox.fromAnchor(anchor)) |returned| {
        var left: Queue = returned.close();
        parents.destroyQueue(&left, alloc, io);
        returned.destroy();
    } else {
        var slot: Slot = anchor;
        parents.destroySlot(&slot, alloc, io);
    }
}

fn releaseInbox(rem: *Queue, alloc: std.mem.Allocator, io: std.Io) void {
    while (rem.popFirst()) |anchor| releaseOne(anchor, alloc, io);
}

fn workerFn(ctx: *WorkerCtx) void {
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        ctx.worker_mbx.receive(&slot, null) catch return;

        if (parents.ShutdownCommand.ShutdownCommandHelper.fromSlot(&slot) != null) {
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
            slot = Mbox.toAnchor(ctx.worker_mbx);
            ctx.master_inbox.send(&slot) catch {};
            return;
        }

        if (parents.Event.EventHelper.fromSlot(&slot)) |ev| {
            ctx.processed += 1;
            std.log.info("worker processed Event code={d}", .{ev.code});
        }
    }
}

fn sendJobsAndShutdown(worker_mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, alloc, io);
        try parents.Event.EventHelper.create(alloc, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @as(i32, @intCast(i + 1));
        try worker_mbx.send(&slot);
    }

    var slot: Slot = null;
    defer parents.destroySlot(&slot, alloc, io);
    try parents.ShutdownCommand.ShutdownCommandHelper.create(alloc, io, &slot);
    try worker_mbx.send(&slot);

    std.log.info("master: sent 3 Events + ShutdownCommand to worker", .{});
}

fn spawnWorker(master_inbox: *Mbox, worker_mbx: *Mbox, ctx: *WorkerCtx, alloc: std.mem.Allocator, io: std.Io) !std.Io.Future(void) {
    ctx.* = .{ .master_inbox = master_inbox, .worker_mbx = worker_mbx, .alloc = alloc, .io = io };
    return io.concurrent(workerFn, .{ctx});
}

fn receiveAndVerify(master_inbox: *Mbox, worker_mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var slot: Slot = null;
    defer if (slot) |anchor| {
        releaseOne(anchor, alloc, io);
        slot = null;
    };
    try master_inbox.receive(&slot, null);
    try helpers.expect(error.WorkerFinishFailed, Mbox.isIt(slot.?.typeId()), "expected an Mbox");
    try helpers.expect(error.WorkerFinishFailed, Mbox.mustFromSlot(&slot) == worker_mbx, "wrong mailbox returned");
    cleanupReturnedMailbox(&slot, alloc, io);
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Anchor = matryoshka.inner.Anchor;
const Mbox = matryoshka.Mbox;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
