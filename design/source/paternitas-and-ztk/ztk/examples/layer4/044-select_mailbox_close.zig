// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Select mailbox close propagation.
//!
//! - Mailbox is empty; receiveResult blocks as a Select event source.
//! - A timer triggers first, closes the mailbox while receiveResult is running.
//! - The blocked receive unblocks with .closed, propagated through sel.await().
//!
//!
//! ```
//!  mailbox (empty)
//!  │ receiveResult (blocking)
//!  ▼
//!  Select(MasterEvent) ◄── sleepFn (timer triggers first)
//!  │
//!  .timer ──► mbx.close() ──► destroyQueue(rem)
//!             (running receiveResult unblocks with .closed)
//!  │
//!  sel.await() ──► .inbox .closed
//!  sel.cancelDiscard()
//! ```
//!

pub fn select_mailbox_close_propagation(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    var ctx: Ctx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    defer {
        if (!ctx.mbx_closed) {
            var rem: Queue = ctx.mbx.close();
            parents.destroyQueue(&rem, ctx.alloc, ctx.io);
        }
        ctx.mbx.destroy();
    }

    var buf: [4]MasterEvent = undefined;
    var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);
    try ctx.setupSelect(&sel);
    try ctx.runEventLoop(&sel);

    try helpers.expect(error.SelectMailboxCloseFailed, ctx.got_closed, "expected .closed from Select inbox");
    std.log.info("done: Mbox.close propagated .closed through Select", .{});
}

const TIMER_NS: i96 = 10_000_000; // 10 ms

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
    mbx_closed: bool = false,
    got_closed: bool = false,

    fn setupSelect(self: *Ctx, sel: *std.Io.Select(MasterEvent)) !void {
        const sleep_t: std.Io.Timeout = .{
            .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
        };
        try sel.concurrent(.inbox, matryoshka.mbox.receiveResult, .{ self.mbx, null });
        try sel.concurrent(.timer, sleepFn, .{ sleep_t, self.io });
    }

    fn runEventLoop(self: *Ctx, sel: *std.Io.Select(MasterEvent)) !void {
        loop: while (true) {
            const event: MasterEvent = try sel.await();
            switch (event) {
                .timer => {
                    std.log.info("timer: closing mailbox while receiveResult is running", .{});
                    var rem: Queue = self.mbx.close();
                    parents.destroyQueue(&rem, self.alloc, self.io);
                    self.mbx_closed = true;
                },
                .inbox => |r| switch (r) {
                    .closed => {
                        std.log.info("inbox: .closed — Mbox.close propagated into Select", .{});
                        self.got_closed = true;
                        break :loop;
                    },
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        parents.destroySlot(&slot, self.alloc, self.io);
                    },
                    .canceled, .timeout, .wakeup => break :loop,
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
