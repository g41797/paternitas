// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Select cancel propagation.
//!
//! - Mailbox is empty; receiveResult blocks as a Select event source.
//! - A timer triggers first, calls sel.cancel().
//! - The blocked receive reports .canceled, propagated through the cancel loop.
//!
//!
//! ```
//!  mailbox (empty)
//!  │ receiveResult (blocking)
//!  ▼
//!  Select(MasterEvent) ◄── sleepFn (timer)
//!  │
//!  .timer ──► sel.cancel() loop ──► .inbox .canceled
//!             (group.cancel signals receiveResult to stop)
//!  │
//!  mbx.close ──► destroyQueue ──► mbx.destroy
//! ```
//!

pub fn select_cancel_propagation(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var buf: [4]MasterEvent = undefined;
    var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);
    var ctx: Ctx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    try ctx.setupSelect(&sel);
    try Ctx.awaitTimerFirst(&sel);
    ctx.clearCanceled(&sel);

    try helpers.expect(error.SelectMailboxCancelFailed, ctx.got_canceled, "expected .canceled from inbox");
    std.log.info("done: sel.cancel() propagated .canceled through matryoshka.mbox.receiveResult", .{});
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
    got_canceled: bool = false,

    fn setupSelect(self: *Ctx, sel: *std.Io.Select(MasterEvent)) !void {
        const sleep_t: std.Io.Timeout = .{
            .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
        };
        try sel.concurrent(.inbox, matryoshka.mbox.receiveResult, .{ self.mbx, null });
        try sel.concurrent(.timer, sleepFn, .{ sleep_t, self.io });
    }

    fn awaitTimerFirst(sel: *std.Io.Select(MasterEvent)) !void {
        const first: MasterEvent = try sel.await();
        switch (first) {
            .timer => std.log.info("timer: canceling Select", .{}),
            else => return error.SelectMailboxCancelFailed,
        }
    }

    fn clearCanceled(self: *Ctx, sel: *std.Io.Select(MasterEvent)) void {
        while (sel.cancel()) |event| {
            switch (event) {
                .inbox => |r| switch (r) {
                    .canceled => {
                        std.log.info("inbox: .canceled — select.cancel propagated through mailbox", .{});
                        self.got_canceled = true;
                    },
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        parents.destroySlot(&slot, self.alloc, self.io);
                    },
                    .closed, .timeout, .wakeup => {},
                },
                .timer => {},
            }
        }
    }
};

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
