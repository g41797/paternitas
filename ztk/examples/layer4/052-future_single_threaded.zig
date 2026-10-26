// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Futures need concurrency
//!
//! On a single-threaded `Io`, `receiveFuture` cannot start.
//!
//! - Call `mbx.receiveFuture` on a single-threaded `Io` backend. It returns
//!   `error.ConcurrencyUnavailable`. No task can run the future.
//! - Call `mbx.receive`. It still works. It needs no concurrency.
//!
//! ```
//!  mailbox (single-threaded Io)
//!  │
//!  receiveFuture ──► error.ConcurrencyUnavailable
//!  │
//!  mbx.receive still works
//! ```
//!

pub fn concurrencyunavailable_on_single_threaded(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    try testFutureUnavailable(mbx);
    try testSynchronousReceive(mbx, allocator, io);
}

fn testFutureUnavailable(mbx: *Mbox) !void {
    if (mbx.receiveFuture(null)) |_| {
        return error.FutureSingleThreadedFailed;
    } else |_| {}
    std.log.info("receiveFuture: ConcurrencyUnavailable on single-threaded backend as expected", .{});
}

fn testSynchronousReceive(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var slot: Slot = null;
    defer parents.Event.EventHelper.destroy(alloc, io, &slot);
    try parents.Event.EventHelper.create(alloc, io, &slot);
    parents.Event.EventHelper.mustFromSlot(&slot).code = 1;
    try mbx.send(&slot);

    var received: Slot = null;
    defer parents.destroySlot(&received, alloc, io);
    try mbx.receive(&received, null);
    std.log.info("synchronous receive still works: code={d}", .{parents.Event.EventHelper.mustFromSlot(&received).code});
}

const parents = @import("../parents/parents.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
