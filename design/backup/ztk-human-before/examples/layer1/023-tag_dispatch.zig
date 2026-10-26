// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Id-dispatch consume loop.
//!
//! - Append an Event and a Sensor to one queue.
//! - Pop each inner, and ask each type to cast it: fromAnchor.
//! - The cast that matches gives the typed pointer, the others give null.
//! - Release each parent as it is handled.
//!
//!
//! ```
//!  create (Event) ──► queue
//!  create (Sensor) ──► queue
//!       │ queue.popFirst
//!       ▼
//!  EventHelper.fromAnchor or SensorHelper.fromAnchor
//!       │ destroySlot per parent
//! ```
//!

pub fn id_dispatch_consume_loop(allocator: std.mem.Allocator, io: std.Io) !void {
    var queue: Queue = .{};

    defer parents.destroyQueue(&queue, allocator, io);

    {
        var slot: Slot = null;
        try parents.Event.EventHelper.create(allocator, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = 7;
        queue.appendFromSlot(&slot);
    }

    {
        var slot: Slot = null;
        try parents.Sensor.SensorHelper.create(allocator, io, &slot);
        parents.Sensor.SensorHelper.mustFromSlot(&slot).value = 2.71;
        queue.appendFromSlot(&slot);
    }

    var processed_events: usize = 0;
    var processed_sensors: usize = 0;

    while (queue.popFirst()) |anchor| {
        var slot: Slot = anchor;
        defer parents.destroySlot(&slot, allocator, io);

        if (parents.Event.EventHelper.fromAnchor(anchor)) |recovered_ev| {
            try helpers.expect(error.IdDispatchFailed, recovered_ev.code == 7, "wrong event code");
            processed_events += 1;
        } else if (parents.Sensor.SensorHelper.fromAnchor(anchor)) |recovered_sn| {
            try helpers.expect(error.IdDispatchFailed, recovered_sn.value == 2.71, "wrong sensor value");
            processed_sensors += 1;
        } else {
            return error.UnknownId;
        }
    }

    try helpers.expect(error.IdDispatchFailed, processed_events == 1, "wrong event count");
    try helpers.expect(error.IdDispatchFailed, processed_sensors == 1, "wrong sensor count");
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
const std = @import("std");
