// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Send with a limit.
//!
//! - sendLimited counts the queued parents of the sender's own type.
//! - Two Events fit under a limit of 2. The third is refused with error.Limit.
//! - The refused Slot is untouched, so the caller releases it.
//! - A Sensor is a different type and is not counted against the Events.
//!
//!
//! ```
//!  Event ──sendLimited(2)──► queued (1)
//!  Event ──sendLimited(2)──► queued (2)
//!  Event ──sendLimited(2)──► error.Limit, slot still full ──► destroySlot
//!  Sensor ─sendLimited(2)──► queued (other type)
//! ```
//!

pub fn send_limit(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer mbx.destroy();
    defer {
        var rem: matryoshka.queue.Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
    }

    const limit: usize = 2;

    var i: i32 = 0;
    while (i < limit) : (i += 1) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        try parents.Event.EventHelper.create(allocator, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = i;
        try mbx.sendLimited(&slot, limit);
        try helpers.expect(error.SendLimitFailed, slot == null, "an accepted send empties the Slot");
    }

    {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        try parents.Event.EventHelper.create(allocator, io, &slot);

        const refused = mbx.sendLimited(&slot, limit);
        try helpers.expect(error.SendLimitFailed, refused == error.Limit, "expected error.Limit");
        try helpers.expect(error.SendLimitFailed, slot != null, "a refused send must leave the parent in the Slot");
        std.log.info("third Event refused: limit {d} reached", .{limit});
    }

    {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        try parents.Sensor.SensorHelper.create(allocator, io, &slot);
        try mbx.sendLimited(&slot, limit);
    }

    try helpers.expect(error.SendLimitFailed, mbx.len() == 3, "wrong queued count");
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
