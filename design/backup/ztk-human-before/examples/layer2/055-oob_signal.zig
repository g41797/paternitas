// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! OOB via sendOob.
//!
//! - Send 3 Events via mbx.send, queued in order.
//! - Send 1 Sensor via mbx.sendOob, jumps to queue front.
//! - Receive 4 items: OOB Sensor arrives first, then the 3 Events.
//! - Free every received item.
//!
//!
//! ```
//!  mbx.send (Event×3) ──► queue tail
//!  mbx.sendOob (Sensor) ──► queue front
//!       │ mbx.receive ×4
//!       ▼
//!  OOB Sensor arrives first, then Events in send order
//!  destroySlot per item
//! ```
//!

pub fn oob_via_sendOob(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: matryoshka.queue.Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    const codes = [_]i32{ 1, 2, 3 };
    for (codes) |code| {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(allocator, io, &slot);
        try parents.Event.EventHelper.create(allocator, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = code;
        try mbx.send(&slot);
    }

    {
        var slot: Slot = null;
        defer parents.Sensor.SensorHelper.destroy(allocator, io, &slot);
        try parents.Sensor.SensorHelper.create(allocator, io, &slot);
        parents.Sensor.SensorHelper.mustFromSlot(&slot).value = -1.0;
        try mbx.sendOob(&slot);
    }

    var received_oob: bool = false;
    var event_count: usize = 0;
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        try mbx.receive(&slot, 1_000_000_000);
        const anchor: *Anchor = slot.?;
        if (parents.Sensor.SensorHelper.fromAnchor(anchor)) |oob_sn| {
            std.log.info("OOB signal value={d:.1}", .{oob_sn.value});
            try helpers.expect(error.OobSignalFailed, !received_oob, "duplicate OOB");
            try helpers.expect(error.OobSignalFailed, event_count == 0, "OOB did not arrive first");
            received_oob = true;
            parents.destroySlot(&slot, allocator, io);
        } else if (parents.Event.EventHelper.fromAnchor(anchor)) |ev| {
            std.log.info("event code={d}", .{ev.code});
            event_count += 1;
            parents.destroySlot(&slot, allocator, io);
        }
    }

    try helpers.expect(error.OobSignalFailed, received_oob, "OOB not received");
    try helpers.expect(error.OobSignalFailed, event_count == 3, "wrong event count");
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Anchor = matryoshka.inner.Anchor;
const Slot = matryoshka.inner.Slot;
