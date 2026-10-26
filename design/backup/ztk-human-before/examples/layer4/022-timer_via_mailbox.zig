// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Timer via mailbox.
//!
//! - Separate timer task sends 2 Timer ticks into the master's inbox.
//! - Main sends 2 Events into the same inbox.
//! - Worker dispatches on id: counts Events separately from Timer ticks.
//! - Worker exits after receiving the expected total — no Select needed.
//!
//!
//! ```
//!  main ──Event×2──►
//!  timerFn ──Timer×2──► mailbox ──► workerFn (id dispatch; fixed count)
//!  (workerFn exits after receiving N_EVENTS + N_TICKS items)
//!  fut_timer.await → fut_worker.await
//! ```
//!

pub fn timer_via_mailbox(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    try sendEvents(mbx, allocator, io, N_EVENTS);

    var worker_ctx: WorkerCtx = .{
        .mbx = mbx,
        .alloc = allocator,
        .io = io,
        .expected = N_EVENTS + N_TICKS,
    };
    try spawnAndAwait(mbx, allocator, io, &worker_ctx);

    try helpers.expect(error.TimerViaMailboxFailed, worker_ctx.event_count == N_EVENTS, "expected 2 Events");
    try helpers.expect(error.TimerViaMailboxFailed, worker_ctx.timer_count == N_TICKS, "expected 2 timer ticks");

    std.log.info("done: {d} events, {d} timer ticks — id dispatch via single mailbox", .{
        worker_ctx.event_count,
        worker_ctx.timer_count,
    });
}

const TICK_NS: i96 = 50_000_000; // 50 ms
const N_EVENTS: usize = 2;
const N_TICKS: usize = 2;

const TimerCtx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
};

fn timerFn(ctx: *TimerCtx) anyerror!void {
    const sleep_t: std.Io.Timeout = .{
        .duration = .{ .raw = .{ .nanoseconds = TICK_NS }, .clock = .real },
    };
    for (0..N_TICKS) |_| {
        try std.Io.Timeout.sleep(sleep_t, ctx.io);
        var slot: Slot = null;
        try parents.Timer.TimerHelper.create(ctx.alloc, ctx.io, &slot);
        ctx.mbx.send(&slot) catch {
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
            return;
        };
    }
}

const WorkerCtx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
    expected: usize,
    timer_count: usize = 0,
    event_count: usize = 0,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    var received: usize = 0;
    while (received < ctx.expected) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        try ctx.mbx.receive(&slot, null);
        received += 1;

        if (parents.Timer.TimerHelper.fromSlot(&slot)) |_| {
            ctx.timer_count += 1;
            std.log.info("worker: timer tick {d}", .{ctx.timer_count});
        } else if (parents.Event.EventHelper.fromSlot(&slot)) |ev| {
            ctx.event_count += 1;
            std.log.info("worker: Event code={d} (event {d})", .{ ev.code, ctx.event_count });
        }
    }
}

fn sendEvents(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io, count: usize) !void {
    for (0..count) |i| {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(alloc, io, &slot);
        try parents.Event.EventHelper.create(alloc, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 1);
        try mbx.send(&slot);
    }
}

fn spawnAndAwait(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io, worker_ctx: *WorkerCtx) !void {
    var timer_ctx: TimerCtx = .{ .mbx = mbx, .alloc = alloc, .io = io };
    var fut_timer = try io.concurrent(timerFn, .{&timer_ctx});
    var fut_worker = try io.concurrent(workerFn, .{worker_ctx});
    errdefer fut_worker.cancel(io) catch {};
    try fut_timer.await(io);
    try fut_worker.await(io);
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
const Queue = matryoshka.queue.Queue;
