// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Multiple event source types in one Select.
//!
//! - Inbox uses matryoshka.mbox.receiveResult, job pool uses matryoshka.pool.getWaitResult, timer uses Io.sleep.
//! - All three are event sources with uniform result handling in one switch.
//! - Loop re-spawns each source after handling it, exits once both targets are met.
//! - Timer just counts ticks; it drives no work in this example.
//!
//!
//! ```
//!  mailbox (Event items)    pool (Sensor items)    timer
//!  │ receiveResult           │ getWaitResult         │ sleepFn
//!  └──────────────────┬──────┘                        │
//!                     ▼                               │
//!             Select(MasterEvent) ◄───────────────────┘
//!                     │ sel.await() loop
//!                     ▼
//!  .inbox .item  ──► freeSlot             (count inbox)
//!  .pool_ev .item──► pl.put             (count pool)
//!  .timer        ──► re-spawn timer       (count ticks)
//!  exit when inbox_target + pool_target reached ──► sel.cancelDiscard()
//! ```
//!

pub fn multiple_event_source_types_in_one_select(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var pool_ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Sensor.SensorHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, pool_ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    try seedMailbox(mbx, allocator, io, INBOX_TARGET);
    try seedPool(pl, POOL_TARGET);

    var buf: [8]MasterEvent = undefined;
    var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);
    var ctx: Ctx = .{ .mbx = mbx, .pl = pl, .alloc = allocator, .io = io };
    try ctx.setupSelect(&sel);
    try ctx.runEventLoop(&sel);

    try helpers.expect(error.SelectMixedSourcesFailed, ctx.inbox_count == INBOX_TARGET, "inbox count mismatch");
    try helpers.expect(error.SelectMixedSourcesFailed, ctx.pool_count == POOL_TARGET, "pool count mismatch");
    std.log.info("done: inbox={d}, pool={d}, ticks={d}", .{ ctx.inbox_count, ctx.pool_count, ctx.ticks });
}

const TIMER_NS: i96 = 25_000_000; // 25 ms
const INBOX_TARGET: usize = 2;
const POOL_TARGET: usize = 2;

const MasterEvent = union(enum) {
    inbox: Mbox.Result,
    pool_ev: Pool.Result,
    timer: void,
};

fn sleepFn(sleep_t: std.Io.Timeout, io: std.Io) void {
    std.Io.Timeout.sleep(sleep_t, io) catch {};
}

fn seedMailbox(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io, count: usize) !void {
    for (0..count) |i| {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(alloc, io, &slot);
        try parents.Event.EventHelper.create(alloc, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 1);
        try mbx.send(&slot);
    }
}

fn seedPool(pl: *Pool, count: usize) !void {
    for (0..count) |i| {
        var slot: Slot = null;
        try pl.get(parents.Sensor.SensorHelper.ID, .new_only, &slot);
        parents.Sensor.SensorHelper.mustFromSlot(&slot).value = @floatFromInt(i + 10);
        try pl.put(&slot);
    }
}

const Ctx = struct {
    mbx: *Mbox,
    pl: *Pool,
    alloc: std.mem.Allocator,
    io: std.Io,
    inbox_count: usize = 0,
    pool_count: usize = 0,
    ticks: usize = 0,

    fn setupSelect(self: *Ctx, sel: *std.Io.Select(MasterEvent)) !void {
        const sleep_t: std.Io.Timeout = .{
            .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
        };
        try sel.concurrent(.inbox, matryoshka.mbox.receiveResult, .{ self.mbx, null });
        try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ self.pl, parents.Sensor.SensorHelper.ID, null });
        try sel.concurrent(.timer, sleepFn, .{ sleep_t, self.io });
    }

    fn runEventLoop(self: *Ctx, sel: *std.Io.Select(MasterEvent)) !void {
        while (self.inbox_count < INBOX_TARGET or self.pool_count < POOL_TARGET) {
            const event: MasterEvent = try sel.await();
            switch (event) {
                .inbox => |r| switch (r) {
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        defer parents.destroySlot(&slot, self.alloc, self.io);
                        self.inbox_count += 1;
                        std.log.info("inbox: Event code={d} ({d}/{d})", .{
                            parents.Event.EventHelper.mustFromSlot(&slot).code,
                            self.inbox_count,
                            INBOX_TARGET,
                        });
                        if (self.inbox_count < INBOX_TARGET) {
                            try sel.concurrent(.inbox, matryoshka.mbox.receiveResult, .{ self.mbx, null });
                        }
                    },
                    .closed, .canceled, .timeout, .wakeup => break,
                },
                .pool_ev => |r| switch (r) {
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        defer self.pl.put(&slot) catch unreachable;
                        self.pool_count += 1;
                        std.log.info("pool_ev: Sensor value={d} ({d}/{d})", .{
                            parents.Sensor.SensorHelper.mustFromSlot(&slot).value,
                            self.pool_count,
                            POOL_TARGET,
                        });
                        if (self.pool_count < POOL_TARGET) {
                            try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ self.pl, parents.Sensor.SensorHelper.ID, null });
                        }
                    },
                    .closed, .canceled, .timeout, .unknown_identity => break,
                },
                .timer => {
                    self.ticks += 1;
                    std.log.info("timer: tick {d}", .{self.ticks});
                    const sleep_t: std.Io.Timeout = .{
                        .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
                    };
                    try sel.concurrent(.timer, sleepFn, .{ sleep_t, self.io });
                },
            }
        }
        sel.cancelDiscard();
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
