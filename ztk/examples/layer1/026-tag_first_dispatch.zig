// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Id-first dispatch, the other way round from 023.
//!
//! - 023 has the parent. It asks each type to cast: fromAnchor.
//! - This one starts from the id alone. It asks each type to confirm: isIt.
//! - Only after an id is confirmed does mustFromAnchor reach the parent.
//! - A pool hook works this way because it has no parent — see AlwaysCreateHooks.
//!
//! - Append an Event, a Sensor and a Timer to one mixed queue.
//! - Read each id once, confirm it, then reach the parent.
//! - The last branch handles an id nobody claimed. Always write it.
//!
//!
//! ```
//!  queue.popFirst ──► inner
//!       │ inner.id (one read)
//!       ▼
//!  id ──► isIt ──► mustFromAnchor ──► parent
//!       │ destroySlot per parent
//! ```
//!

pub fn id_first_dispatch_loop(allocator: std.mem.Allocator, io: std.Io) !void {
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

    {
        var slot: Slot = null;
        try parents.Timer.TimerHelper.create(allocator, io, &slot);
        queue.appendFromSlot(&slot);
    }

    var events: usize = 0;
    var sensors: usize = 0;
    var timers: usize = 0;

    while (queue.popFirst()) |anchor| {
        var slot: Slot = anchor;
        defer parents.destroySlot(&slot, allocator, io);

        // One read. Every branch below asks about this id.
        const id: TypeId = anchor.typeId();

        if (parents.Event.EventHelper.isIt(id)) {
            // The id is proven, so this cast cannot fail.
            const ev = parents.Event.EventHelper.mustFromAnchor(anchor);
            try helpers.expect(error.IdFirstDispatchFailed, ev.code == 7, "wrong event code");
            events += 1;
        } else if (parents.Sensor.SensorHelper.isIt(id)) {
            const sn = parents.Sensor.SensorHelper.mustFromAnchor(anchor);
            try helpers.expect(error.IdFirstDispatchFailed, sn.value == 2.71, "wrong sensor value");
            sensors += 1;
        } else if (parents.Timer.TimerHelper.isIt(id)) {
            // A branch that never reaches the parent. The id was enough.
            timers += 1;
        } else {
            // Nobody claimed the id. This branch has no type to release
            // the parent with, so it returns and the defer above does it.
            return error.UnknownId;
        }
    }

    try helpers.expect(error.IdFirstDispatchFailed, events == 1, "wrong event count");
    try helpers.expect(error.IdFirstDispatchFailed, sensors == 1, "wrong sensor count");
    try helpers.expect(error.IdFirstDispatchFailed, timers == 1, "wrong timer count");
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const TypeId = matryoshka.inner.TypeId;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
const std = @import("std");
