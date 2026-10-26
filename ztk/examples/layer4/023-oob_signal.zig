// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: A ShutdownCommand ahead of the queue
//!
//! A ShutdownCommand sent with `sendOob` comes out first.
//!
//! - Send three Events with `mbx.send`. They queue in order.
//! - Send a ShutdownCommand with `mbx.sendOob`. It goes ahead of them.
//! - Receive four parents in `processingLoop`: the ShutdownCommand first, then
//!   the Events.
//! - Release each one, and check the order.
//!
//! ```
//!  mbx.send (Event×3) ──► the ordinary queue
//!  mbx.sendOob (ShutdownCommand) ──► ahead of it
//!       │ mbx.receive ×4
//!       ▼
//!  the ShutdownCommand first, then the Events in send order
//!  destroySlot per parent
//! ```
//!

pub fn shutdown_ahead_of_the_queue(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    try sendItems(mbx, allocator, io);
    try sendOobItem(mbx, allocator, io);
    std.log.info("sent 3 Events (regular) + 1 ShutdownCommand (OOB)", .{});
    try processingLoop(mbx, allocator, io);
}

fn sendItems(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    for (0..3) |i| {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(alloc, io, &slot);
        try parents.Event.EventHelper.create(alloc, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 1);
        try mbx.send(&slot);
    }
}

fn sendOobItem(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var slot: Slot = null;
    defer parents.ShutdownCommand.ShutdownCommandHelper.destroy(alloc, io, &slot);
    try parents.ShutdownCommand.ShutdownCommandHelper.create(alloc, io, &slot);
    try mbx.sendOob(&slot);
}

fn processingLoop(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var shutdown_seen: bool = false;
    var event_count: usize = 0;

    for (0..4) |_| {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, alloc, io);
        try mbx.receive(&slot, null);
        const poly: *Anchor = slot.?;

        if (parents.ShutdownCommand.ShutdownCommandHelper.fromAnchor(poly)) |_| {
            try helpers.expect(error.OobOrderFailed, !shutdown_seen, "OOB ShutdownCommand must arrive before any Event");
            try helpers.expect(error.OobOrderFailed, event_count == 0, "OOB must be first item received");
            shutdown_seen = true;
            std.log.info("received OOB ShutdownCommand (first, as expected)", .{});
            parents.destroySlot(&slot, alloc, io);
        } else if (parents.Event.EventHelper.fromAnchor(poly)) |ev| {
            try helpers.expect(error.OobOrderFailed, shutdown_seen, "Events must arrive after the OOB item");
            event_count += 1;
            std.log.info("received Event code={d} (event {d}/3)", .{ ev.code, event_count });
            parents.destroySlot(&slot, alloc, io);
        } else {
            return error.OobOrderFailed;
        }
    }

    try helpers.expect(error.OobOrderFailed, shutdown_seen, "OOB item not received");
    try helpers.expect(error.OobOrderFailed, event_count == 3, "expected 3 Events");
    std.log.info("OOB ordering verified: shutdown came first, then {d} events", .{event_count});
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
const Queue = matryoshka.queue.Queue;
const Anchor = matryoshka.inner.Anchor;
