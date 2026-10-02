// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Mixed types through shared mailbox.
//!
//! - Send one Event and one Sensor into the same mailbox.
//! - receiveAndDispatch pops both, dispatches on the type with fromSlot.
//! - Verifies each payload, releases each parent.
//!
//!
//! ```
//!  EventHelper.create ──► slot ──► mbx.send ──► mailbox
//!  SensorHelper.create ──► slot ──► mbx.send ──► mailbox
//!  │
//!  mbx.receive ──► slot (Event or Sensor)
//!    dispatch on the id:
//!    EventHelper.fromSlot  ──► *Event  ──► verify code==10 ──► destroySlot
//!    SensorHelper.fromSlot ──► *Sensor ──► verify value==3.14 ──► destroySlot
//!  │
//!  mbx.close ──► destroyQueue (empty: all received)
//! ```
//!

pub fn mixed_types_through_shared_mailbox(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    try sendEvent(mbx, allocator, io);
    try sendSensor(mbx, allocator, io);
    try receiveAndDispatch(mbx, allocator, io);
}

fn sendEvent(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var slot: Slot = null;
    defer parents.Event.EventHelper.destroy(alloc, io, &slot);
    try parents.Event.EventHelper.create(alloc, io, &slot);
    parents.Event.EventHelper.mustFromSlot(&slot).code = 10;
    std.log.info("send: Event code={d}", .{10});
    try mbx.send(&slot);
}

fn sendSensor(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var slot: Slot = null;
    defer parents.Sensor.SensorHelper.destroy(alloc, io, &slot);
    try parents.Sensor.SensorHelper.create(alloc, io, &slot);
    parents.Sensor.SensorHelper.mustFromSlot(&slot).value = 3.14;
    std.log.info("send: Sensor value={d}", .{3.14});
    try mbx.send(&slot);
}

fn receiveAndDispatch(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var event_ok: bool = false;
    var sensor_ok: bool = false;

    for (0..2) |_| {
        var slot: Slot = null;
        try mbx.receive(&slot, null);
        defer parents.destroySlot(&slot, alloc, io);
        if (parents.Event.EventHelper.fromSlot(&slot)) |ev| {
            try helpers.expect(error.CrossLayerMixedTypesFailed, ev.code == 10, "wrong Event code");
            std.log.info("received: Event code={d}", .{ev.code});
            event_ok = true;
        } else if (parents.Sensor.SensorHelper.fromSlot(&slot)) |sn| {
            try helpers.expect(error.CrossLayerMixedTypesFailed, sn.value == 3.14, "wrong Sensor value");
            std.log.info("received: Sensor value={d}", .{sn.value});
            sensor_ok = true;
        } else {
            return error.CrossLayerMixedTypesFailed;
        }
    }

    try helpers.expect(error.CrossLayerMixedTypesFailed, event_ok, "Event not received");
    try helpers.expect(error.CrossLayerMixedTypesFailed, sensor_ok, "Sensor not received");
    std.log.info("done: Event + Sensor through shared mailbox, dispatched on the id", .{});
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
