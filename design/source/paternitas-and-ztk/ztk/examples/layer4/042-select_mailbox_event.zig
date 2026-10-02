// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Mailbox receive as Select event source.
//!
//! - Mailbox pre-loaded with 3 Events; a timer runs alongside it in Select.
//! - runEventLoop re-spawns matryoshka.mbox.receiveResult after each item, re-spawns the timer per tick.
//! - Loop exits once all 3 items are received; sel.cancelDiscard cleans up the rest.
//!
//!
//! ```
//!  mailbox (pre-loaded: Event×3)
//!     │ receiveResult
//!     ▼
//!  Select(MasterEvent) ◄── sleepFn (timer, re-spawned each tick)
//!     │ sel.await()
//!     ▼
//!  .inbox .item ──► freeSlot (re-spawn receiveResult)
//!  .timer        ──► re-spawn sleepFn
//!  .inbox .closed ──► exit loop
//!  │
//!  sel.cancelDiscard()
//! ```
//!

pub fn mailbox_receive_as_select_event_source(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var ctx: Ctx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    try ctx.seedMailbox();

    var buf: [4]MasterEvent = undefined;
    var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);
    try ctx.setupSelect(&sel);
    try ctx.runEventLoop(&sel);

    try helpers.expect(error.SelectMailboxEventFailed, ctx.received == N_ITEMS, "did not receive all items");
    std.log.info("done: {d} items, {d} timer ticks", .{ ctx.received, ctx.ticks });
}

const TIMER_NS: i96 = 20_000_000; // 20 ms
const N_ITEMS: usize = 3;

const MasterEvent = union(enum) {
    inbox: Mbox.Result,
    timer: void,
};

fn sleepFn(sleep_t: std.Io.Timeout, io: std.Io) void {
    std.Io.Timeout.sleep(sleep_t, io) catch {};
}

const Ctx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
    received: usize = 0,
    ticks: usize = 0,

    fn seedMailbox(self: *Ctx) !void {
        for (0..N_ITEMS) |i| {
            var slot: Slot = null;
            defer parents.Event.EventHelper.destroy(self.alloc, self.io, &slot);
            try parents.Event.EventHelper.create(self.alloc, self.io, &slot);
            parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 1);
            try self.mbx.send(&slot);
        }
    }

    fn setupSelect(self: *Ctx, sel: *std.Io.Select(MasterEvent)) !void {
        const sleep_t: std.Io.Timeout = .{
            .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
        };
        try sel.concurrent(.inbox, matryoshka.mbox.receiveResult, .{ self.mbx, null });
        try sel.concurrent(.timer, sleepFn, .{ sleep_t, self.io });
    }

    fn runEventLoop(self: *Ctx, sel: *std.Io.Select(MasterEvent)) !void {
        while (self.received < N_ITEMS) {
            const event: MasterEvent = try sel.await();
            switch (event) {
                .inbox => |r| switch (r) {
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        defer parents.destroySlot(&slot, self.alloc, self.io);
                        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
                        self.received += 1;
                        std.log.info("inbox: Event code={d} ({d}/{d})", .{ ev.code, self.received, N_ITEMS });
                        if (self.received < N_ITEMS) {
                            try sel.concurrent(.inbox, matryoshka.mbox.receiveResult, .{ self.mbx, null });
                        }
                    },
                    .closed, .canceled, .timeout, .wakeup => break,
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
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
