// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Move a parent through a Slot
//!
//! A parent moves from a Slot to a queue and back.
//!
//! - Create an Event into a Slot.
//! - Take it out with `moveFromSlot`, and append it to a queue.
//! - Pop it from the queue, and put it back into a Slot.
//! - Check its data, then release it.
//!
//! `moveFromSlot` checks the type and empties the Slot in one step. `fromSlot`
//! leaves the Slot full. That is the difference.
//!
//! ```
//!  create ──► Slot (full)
//!       │ moveFromSlot + queue.append
//!       ▼
//!  queue (has the parent)
//!       │ queue.popFirst, into the Slot
//!       ▼
//!  Slot (has the parent again)
//!       │ destroySlot
//!       ▼
//!  released
//! ```
//!

pub fn parent_transfer_via_slot(allocator: std.mem.Allocator, io: std.Io) !void {
    var slot: Slot = null;
    defer parents.Event.EventHelper.destroy(allocator, io, &slot);
    try parents.Event.EventHelper.create(allocator, io, &slot);
    const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
    ev.code = 42;
    try helpers.expect(error.ParentTransferFailed, slot != null, "slot should be non-null after create");

    // Transfer to the queue — moveFromSlot checks the id and empties the slot.
    var queue: Queue = .{};
    const moved: *parents.Event = parents.Event.EventHelper.moveFromSlot(&slot) orelse return error.WrongId;
    queue.append(parents.Event.EventHelper.toAnchor(moved));
    try helpers.expect(error.ParentTransferFailed, slot == null, "slot should be null after transfer");

    // Recover from the queue — assign back to slot.
    slot = queue.popFirst() orelse return error.EmptyQueue;
    try helpers.expect(error.ParentTransferFailed, slot != null, "slot should be non-null after recovery");

    const recovered: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
    try helpers.expect(error.ParentTransferFailed, recovered.code == 42, "wrong event code");

    parents.destroySlot(&slot, allocator, io);
    try helpers.expect(error.ParentTransferFailed, slot == null, "slot should be null after destroy");
    // defer runs as no-op
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
const std = @import("std");
