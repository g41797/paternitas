// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Await a receive
//!
//! `receiveFuture` gives a future you can await. No Select is needed.
//!
//! - Send one Event into the mailbox.
//! - Get an `Io.Future(Mbox.Result)` with `mbx.receiveFuture`.
//! - Await it. It returns the parent, and you release it.
//!
//! ```
//!  master ──EventHelper.create──► Slot
//!         ──mbx.send──► mailbox
//!         │
//!  receiveFuture ──► Future(Mbox.Result)
//!  fut.await ──► .anchor ──► Slot (yours now)
//!         │
//!  destroySlot
//! ```
//!

pub fn await_a_receive(allocator: std.mem.Allocator, io: std.Io) !void {
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
            std.log.info("receiveFuture awaited: got Event code={d}", .{ev.code});
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
