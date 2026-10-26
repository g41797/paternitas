// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Wake a receiver with no message
//!
//! `wakeUpAll` wakes a waiting receiver. Nothing is sent.
//!
//! - Let a worker wait in `mbx.receive`. Nothing is ever sent.
//! - Set a shutdown flag in the coordinator, then call `mbx.wakeUpAll`.
//! - The worker wakes with `error.Wakeup`, reads the flag, and stops.
//!
//! ```
//!  worker thread
//!  mbx.receive (waits: the mailbox stays empty)
//!       │
//!  coordinator: shutdown.store(true) ──► mbx.wakeUpAll
//!       │ error.Wakeup
//!       ▼
//!  worker reads the flag ──► stops
//! ```
//!

pub fn wake_blocked_receiver_without_a_message(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: matryoshka.queue.Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var ctx: WorkerCtx = .{ .mbx = mbx };
    var fut = try io.concurrent(workerFn, .{&ctx});

    // Give the worker time to reach mbx.receive and block.
    std.Io.Timeout.sleep(.{ .duration = .{ .raw = .{ .nanoseconds = 50_000_000 }, .clock = .real } }, io) catch {};

    ctx.shutdown.store(true, .release);
    try mbx.wakeUpAll();

    fut.await(io);

    std.log.info("wake up all: worker woke on error.Wakeup, saw shutdown flag, exited", .{});
    try helpers.expect(error.WakeUpAllFailed, ctx.woke_on_wakeup, "worker did not see error.Wakeup");
}

const WorkerCtx = struct {
    mbx: *Mbox,
    shutdown: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    woke_on_wakeup: bool = false,
};

fn workerFn(ctx: *WorkerCtx) void {
    var slot: Slot = null;
    ctx.mbx.receive(&slot, null) catch |err| {
        if (err == error.Wakeup and ctx.shutdown.load(.acquire)) {
            ctx.woke_on_wakeup = true;
        }
        return;
    };
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
