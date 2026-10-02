// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Worker loop pattern.
//!
//! - Main sends 3 Events and 2 Sensors into a mailbox.
//! - Worker thread loops on mbx.receive, dispatches on tag.
//! - Worker exits on error.Closed.
//! - Main closes the mailbox, frees any items left unreceived.
//!
//!
//! ```
//!  main ──alloc.create──► slot ──mbx.send──► mailbox
//!                                                    │
//!                                              worker thread
//!                                              mbx.receive
//!                                                    │ destroySlot
//!  mbx.close ──► remaining queue ──► destroyQueue (main)
//! ```
//!

pub fn worker_loop_pattern(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: matryoshka.queue.Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var ctx: WorkerCtx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    var fut = try io.concurrent(workerFn, .{&ctx});

    const codes = [_]i32{ 1, 2, 3 };
    for (codes) |code| {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(allocator, io, &slot);
        try parents.Event.EventHelper.create(allocator, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = code;
        try mbx.send(&slot);
    }

    const values = [_]f64{ 1.5, 2.5 };
    for (values) |value| {
        var slot: Slot = null;
        defer parents.Sensor.SensorHelper.destroy(allocator, io, &slot);
        try parents.Sensor.SensorHelper.create(allocator, io, &slot);
        parents.Sensor.SensorHelper.mustFromSlot(&slot).value = value;
        try mbx.send(&slot);
    }

    var rem: matryoshka.queue.Queue = mbx.close();
    var remaining: usize = 0;
    while (rem.popFirst()) |anchor| {
        {
            var s: Slot = anchor;
            parents.destroySlot(&s, allocator, io);
        }
        remaining += 1;
    }
    fut.await(io);

    std.log.info("worker loop: processed={d} remaining={d} event_sum={d} sensor_sum={d:.1}", .{
        ctx.count, remaining, ctx.event_sum, ctx.sensor_sum,
    });
    try helpers.expect(error.WorkerLoopFailed, ctx.count + remaining == 5, "wrong total");
}

const WorkerCtx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
    event_sum: i32 = 0,
    sensor_sum: f64 = 0.0,
    count: usize = 0,
};

fn workerFn(ctx: *WorkerCtx) void {
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        ctx.mbx.receive(&slot, null) catch return;
        const anchor: *Anchor = slot.?;
        if (parents.Event.EventHelper.fromAnchor(anchor)) |ev| {
            std.log.debug("worker: Event code={d}", .{ev.*.code});
            ctx.event_sum += ev.*.code;
            ctx.count += 1;
        } else if (parents.Sensor.SensorHelper.fromAnchor(anchor)) |sn| {
            std.log.debug("worker: Sensor value={d:.1}", .{sn.*.value});
            ctx.sensor_sum += sn.*.value;
            ctx.count += 1;
        }
    }
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Anchor = matryoshka.inner.Anchor;
const Slot = matryoshka.inner.Slot;
