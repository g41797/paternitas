// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Await a receive with a timeout
//!
//! The future returns whatever happens first: a timeout or a parent.
//!
//! - Await `receiveFuture` with a 50 ms timeout on an empty mailbox. It
//!   returns `.timeout`: `receiveWithTimeout`.
//! - Send one Event, then await `receiveFuture(null)`. It returns the parent:
//!   `sendAndReceiveItem`.
//!
//! ```
//!  mailbox (empty)
//!  │
//!  receiveFuture(50ms) ──► Future(Mbox.Result)
//!  fut.await ──► .timeout
//!  │
//!  EventHelper.create ──► Slot ──mbx.send──► mailbox
//!  receiveFuture(null) ──► fut.await ──► .anchor ──► destroySlot
//! ```
//!

pub fn await_a_receive_with_timeout(allocator: std.mem.Allocator, io: std.Io) !void {
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
        std.log.info("receiveFuture with a timeout: got .timeout as expected", .{});
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
                std.log.info("receiveFuture after the timeout: got Event code={d}", .{parents.Event.EventHelper.mustFromSlot(&received).code});
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
