// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! receive_future awaited directly.
//!
//! - Send one Event into the mailbox.
//! - mbx.receive_future returns an Io.Future(Mbox.Result), no Select needed.
//! - fut.await blocks until the item arrives, then it's freed.
//!
//!
//! ```
//!  master ──EventHelper.create──► slot
//!          ──mbx.send──► mailbox
//!          │
//!  receive_future ──► Future(Mbox.Result)
//!  fut.await ──► Mbox.Result .item ──► slot (master owns)
//!          │
//!  freeSlot
//! ```
//!

pub fn receive_future_awaited_directly(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    try sendItem(mbx, allocator, io);
    try receiveAndVerify(mbx, allocator, io);
}

fn sendItem(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var slot: Slot = null;
    defer parents.Event.EventHelper.destroy(alloc, io, &slot);
    try parents.Event.EventHelper.create(alloc, io, &slot);
    parents.Event.EventHelper.mustFromSlot(&slot).code = 42;
    try mbx.send(&slot);
}

fn receiveAndVerify(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var fut: std.Io.Future(Mbox.Result) = try mbx.receiveFuture(null);
    const result: Mbox.Result = fut.await(io);

    switch (result) {
        .anchor => |handle| {
            var received: Slot = handle;
            defer parents.destroySlot(&received, alloc, io);
            const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&received);
            try helpers.expect(error.ReceiveFutureDirectFailed, ev.code == 42, "wrong code");
            std.log.info("receive_future direct: got Event code={d}", .{ev.code});
        },
        else => return error.ReceiveFutureDirectFailed,
    }
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
