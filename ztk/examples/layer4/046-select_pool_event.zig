// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: A pool as a Select source
//!
//! `getWaitResult` turns a pool into one source of a Select.
//!
//! - Fill the pool with three empty Events first. Each is only a container.
//! - Wait on it with `getWaitResult`, next to a timer.
//! - Write the Master's cycle counter into each parent you get, and put it
//!   back: `runEventLoop`.
//! - Restart `getWaitResult` until the target count, then stop.
//!
//! At the target, `getWaitResult` is not restarted. So `cancelDiscard`
//! cancels only the timer. No parent is in flight, and nothing leaks.
//!
//! ```
//!  pool (Event×3, empty: code=0)
//!  │ getWaitResult (waits for a parent)
//!  ▼
//!  Select(MasterEvent) ◄── sleepFn (timer)
//!  │
//!  .pool_ev .anchor ──► write the counter into ev.code ──► put back
//!                   ──► restart getWaitResult (while cycle < target)
//!                   ──► stop (at the target; the timer still runs)
//!  .timer           ──► log the counter ──► restart the timer
//!  │
//!  sel.cancelDiscard() ──► cancels the timer (no parent in flight)
//!  pl.close ──► on_close ──► released
//! ```
//!

pub fn pool_get_wait_as_select_event_source(allocator: std.mem.Allocator, io: std.Io) !void {
    var pool_ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, pool_ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    try seedPool(pl);

    var buf: [4]MasterEvent = undefined;
    var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);
    try setupSelect(pl, io, &sel);
    const cycle = try runEventLoop(pl, io, &sel);

    try helpers.expect(error.SelectPoolEventFailed, cycle == TARGET, "wrong cycle count");
    std.log.info("done: {d} cycles driven by Master counter — pool items were empty containers", .{cycle});
}

const N_ITEMS: usize = 3;
const TARGET: usize = N_ITEMS * 2; // process each container twice
const TIMER_NS: i96 = 30_000_000; // 30 ms

const MasterEvent = union(enum) {
    pool_ev: Pool.Result,
    timer: void,
};

fn sleepFn(sleep_t: std.Io.Timeout, io: std.Io) void {
    std.Io.Timeout.sleep(sleep_t, io) catch {};
}

fn seedPool(pl: *Pool) !void {
    for (0..N_ITEMS) |_| {
        var slot: Slot = null;
        try pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
        try pl.put(&slot);
    }
}

fn setupSelect(pl: *Pool, io: std.Io, sel: *std.Io.Select(MasterEvent)) !void {
    const sleep_t: std.Io.Timeout = .{
        .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
    };
    try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ pl, parents.Event.EventHelper.ID, null });
    try sel.concurrent(.timer, sleepFn, .{ sleep_t, io });
}

fn runEventLoop(pl: *Pool, io: std.Io, sel: *std.Io.Select(MasterEvent)) !usize {
    var cycle: usize = 0;
    while (true) {
        const event: MasterEvent = try sel.await();
        switch (event) {
            .pool_ev => |r| switch (r) {
                .anchor => |handle| {
                    var slot: Slot = handle;
                    defer pl.put(&slot) catch unreachable;
                    const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
                    ev.code = @intCast(cycle);
                    cycle += 1;
                    std.log.info("pool_ev: filled container with cycle={d}", .{ev.code});
                    if (cycle < TARGET) {
                        try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ pl, parents.Event.EventHelper.ID, null });
                    } else {
                        break;
                    }
                },
                .closed, .canceled, .timeout, .unknown_identity => break,
            },
            .timer => {
                std.log.info("timer: maintenance — cycles completed so far: {d}", .{cycle});
                const sleep_t: std.Io.Timeout = .{
                    .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
                };
                try sel.concurrent(.timer, sleepFn, .{ sleep_t, io });
            },
        }
    }
    sel.cancelDiscard();
    return cycle;
}

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Pool = matryoshka.Pool;
const TypeId = matryoshka.inner.TypeId;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
