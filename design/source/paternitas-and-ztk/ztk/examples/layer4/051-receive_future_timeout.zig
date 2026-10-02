// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! receive_future with timeout.
//!
//! - receiveWithTimeout: receive_future on an empty mailbox with a 50ms timeout, resolves .timeout.
//! - sendAndReceiveItem: sends one Event, then receiveFuture(null) resolves .item.
//! - Confirms the future resolves to whichever result actually occurs.
//!
//!
//! ```
//!  mailbox (empty)
//!  │
//!  receiveFuture(50ms) ──► Future(Mbox.Result)
//!  fut.await ──► Mbox.Result .timeout
//!  │
//!  EventHelper.create ──► slot ──mbx.send──► mailbox
//!  receiveFuture(null) ──► fut.await ──► Mbox.Result .item ──► freeSlot
//! ```
//!

pub fn receive_future_with_timeout(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var ctx: Ctx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    try ctx.receiveWithTimeout();
    try ctx.sendAndReceiveItem();
}

const TIMEOUT_NS: u64 = 50_000_000; // 50 ms

const Ctx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,

    fn receiveWithTimeout(self: *Ctx) !void {
        var fut_t: std.Io.Future(Mbox.Result) = try self.mbx.receiveFuture(TIMEOUT_NS);
        const r_timeout: Mbox.Result = fut_t.await(self.io);
        try helpers.expect(error.ReceiveFutureTimeoutFailed, r_timeout == .timeout, "expected .timeout");
        std.log.info("receive_future timeout: got .timeout as expected", .{});
    }

    fn sendAndReceiveItem(self: *Ctx) !void {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(self.alloc, self.io, &slot);
        try parents.Event.EventHelper.create(self.alloc, self.io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = 5;
        try self.mbx.send(&slot);

        var fut_item: std.Io.Future(Mbox.Result) = try self.mbx.receiveFuture(null);
        const r_item: Mbox.Result = fut_item.await(self.io);
        switch (r_item) {
            .anchor => |handle| {
                var received: Slot = handle;
                defer parents.destroySlot(&received, self.alloc, self.io);
                std.log.info("receive_future after timeout: got Event code={d}", .{parents.Event.EventHelper.mustFromSlot(&received).code});
            },
            else => return error.ReceiveFutureTimeoutFailed,
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
