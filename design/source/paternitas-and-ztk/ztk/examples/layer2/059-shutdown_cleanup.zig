// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Shutdown with remaining item cleanup.
//!
//! - Send 5 Events and 3 Sensors into a mailbox, none received.
//! - Close the mailbox — all items come back in the returned queue.
//! - Walk the list with popFirst, free every item.
//!
//!
//! ```
//!  alloc.create × (n_events + n_sensors) ──► mailbox
//!       │ mbx.close (no receive — all items returned)
//!       ▼
//!  Queue ──► destroyItem × N
//! ```
//!

pub fn shutdown_with_remaining_item_cleanup(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer mbx.destroy();

    const n_events: usize = 5;
    const n_sensors: usize = 3;

    var i: usize = 0;
    while (i < n_events) : (i += 1) {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(allocator, io, &slot);
        try parents.Event.EventHelper.create(allocator, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i);
        try mbx.send(&slot);
    }

    i = 0;
    while (i < n_sensors) : (i += 1) {
        var slot: Slot = null;
        defer parents.Sensor.SensorHelper.destroy(allocator, io, &slot);
        try parents.Sensor.SensorHelper.create(allocator, io, &slot);
        parents.Sensor.SensorHelper.mustFromSlot(&slot).value = @as(f64, @floatFromInt(i)) * 1.1;
        try mbx.send(&slot);
    }

    // Close without receiving — all items come back in the returned queue.
    var remaining: matryoshka.queue.Queue = mbx.close();
    var freed: usize = 0;
    while (remaining.popFirst()) |anchor| {
        {
            var s: Slot = anchor;
            parents.destroySlot(&s, allocator, io);
        }
        freed += 1;
    }

    std.log.info("shutdown cleanup: freed {d} items", .{freed});
    try helpers.expect(error.ShutdownCleanupFailed, freed == n_events + n_sensors, "wrong freed count");
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
