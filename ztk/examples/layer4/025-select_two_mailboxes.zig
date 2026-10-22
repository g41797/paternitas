// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Two mailboxes + timer in Select.
//!
//! - Both mailboxes use matryoshka.mbox.receiveResult as Select event sources.
//! - A short timer triggers first, before either mailbox has an item.
//! - Timer seeds both mailboxes, re-spawns itself with a longer duration.
//! - Loop exits once both mailboxes have delivered one item each.
//!
//!
//! ```
//!  mbx1 (empty)    mbx2 (empty)
//!  │ receiveResult  │ receiveResult
//!  └────────┬───────┘
//!           ▼
//!  Select(MasterEvent) ◄── sleepFn (short timer triggers first)
//!  │
//!  .timer ──► send item to mbx1, send item to mbx2
//!             re-spawn timer (longer)
//!  .inbox1 .item ──► freeSlot, re-spawn inbox1
//!  .inbox2 .item ──► freeSlot
//!  sel.cancelDiscard()
//! ```
//!

pub fn two_mailboxes_timer_in_select(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx1_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx1_slot);
    const mbx1: *Mbox = Mbox.moveFromSlot(&mbx1_slot).?;
    defer {
        var rem: Queue = mbx1.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx1.destroy();
    }

    var mbx2_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx2_slot);
    const mbx2: *Mbox = Mbox.moveFromSlot(&mbx2_slot).?;
    defer {
        var rem: Queue = mbx2.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx2.destroy();
    }

    var buf: [8]MasterEvent = undefined;
    var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);
    var ctx: Ctx = .{ .mbx1 = mbx1, .mbx2 = mbx2, .alloc = allocator, .io = io };
    try ctx.setupSelect(&sel);
    try ctx.runEventLoop(&sel);

    try helpers.expect(error.SelectTwoMailboxesFailed, ctx.got1 and ctx.got2, "did not receive from both mailboxes");
    std.log.info("done: timer triggered first; then received from both mailboxes", .{});
}

const SHORT_NS: i96 = 5_000_000; // 5 ms — triggers before mailboxes have items
const LONG_NS: i96 = 50_000_000; // 50 ms — runs while mailboxes are being emptied

const MasterEvent = union(enum) {
    inbox1: Mbox.Result,
    inbox2: Mbox.Result,
    timer: void,
};

fn sleepFn(sleep_t: std.Io.Timeout, io: std.Io) void {
    std.Io.Timeout.sleep(sleep_t, io) catch {};
}

const Ctx = struct {
    mbx1: *Mbox,
    mbx2: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
    got1: bool = false,
    got2: bool = false,

    fn seedMailboxes(self: *Ctx, sel: *std.Io.Select(MasterEvent)) !void {
        var s1: Slot = null;
        defer parents.Event.EventHelper.destroy(self.alloc, self.io, &s1);
        try parents.Event.EventHelper.create(self.alloc, self.io, &s1);
        parents.Event.EventHelper.mustFromSlot(&s1).code = 1;
        try self.mbx1.send(&s1);

        var s2: Slot = null;
        defer parents.Event.EventHelper.destroy(self.alloc, self.io, &s2);
        try parents.Event.EventHelper.create(self.alloc, self.io, &s2);
        parents.Event.EventHelper.mustFromSlot(&s2).code = 2;
        try self.mbx2.send(&s2);

        const long_t: std.Io.Timeout = .{
            .duration = .{ .raw = .{ .nanoseconds = LONG_NS }, .clock = .real },
        };
        try sel.concurrent(.timer, sleepFn, .{ long_t, self.io });
    }

    fn setupSelect(self: *Ctx, sel: *std.Io.Select(MasterEvent)) !void {
        const short_t: std.Io.Timeout = .{
            .duration = .{ .raw = .{ .nanoseconds = SHORT_NS }, .clock = .real },
        };
        try sel.concurrent(.inbox1, matryoshka.mbox.receiveResult, .{ self.mbx1, null });
        try sel.concurrent(.inbox2, matryoshka.mbox.receiveResult, .{ self.mbx2, null });
        try sel.concurrent(.timer, sleepFn, .{ short_t, self.io });
    }

    fn runEventLoop(self: *Ctx, sel: *std.Io.Select(MasterEvent)) !void {
        loop: while (true) {
            const event: MasterEvent = try sel.await();
            switch (event) {
                .timer => {
                    std.log.info("timer: triggered — seeding both mailboxes and re-spawning longer timer", .{});
                    try self.seedMailboxes(sel);
                },
                .inbox1 => |r| switch (r) {
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        defer parents.destroySlot(&slot, self.alloc, self.io);
                        std.log.info("inbox1: Event code={d}", .{parents.Event.EventHelper.mustFromSlot(&slot).code});
                        self.got1 = true;
                        if (!self.got2) {
                            try sel.concurrent(.inbox1, matryoshka.mbox.receiveResult, .{ self.mbx1, null });
                        }
                    },
                    .closed, .canceled, .timeout, .wakeup => break :loop,
                },
                .inbox2 => |r| switch (r) {
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        defer parents.destroySlot(&slot, self.alloc, self.io);
                        std.log.info("inbox2: Event code={d}", .{parents.Event.EventHelper.mustFromSlot(&slot).code});
                        self.got2 = true;
                    },
                    .closed, .canceled, .timeout, .wakeup => break :loop,
                },
            }
            if (self.got1 and self.got2) break :loop;
        }
        sel.cancelDiscard();
    }
};

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
const Queue = matryoshka.queue.Queue;
