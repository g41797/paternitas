// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: A parent on a std list
//!
//! A parent leaves the toolkit for a plain std list, and comes back.
//!
//! - Move the parent out of its Slot, and get its std Node.
//! - Put the Node onto a plain `std.SinglyLinkedList`.
//! - Pop the Node, and clear its link.
//! - Turn the Node back into the parent with `fromNode`. It checks the type.
//! - Put the parent's Anchor into an empty Slot with `fillSlot`.
//!
//! While the parent is on the std list, the toolkit does not know it. std's
//! `popFirst` leaves the link set. Clear it before `fillSlot`, which refuses a
//! parent that still looks linked.
//!
//! ```
//!  Slot ── mustMoveFromSlot ──► *Event ── node ──► list.prepend
//!                                                       │
//!                                                       ▼
//!                                               std.SinglyLinkedList
//!                                                       │ popFirst + clear link
//!                                                       ▼
//!  Slot ◄── fillSlot ── toAnchor ◄── fromNode ◄──── *Node
//! ```
//!

pub fn border_pair(allocator: std.mem.Allocator, io: std.Io) !void {
    var slot: Slot = null;
    defer parents.destroySlot(&slot, allocator, io);

    try parents.Event.EventHelper.create(allocator, io, &slot);
    parents.Event.EventHelper.mustFromSlot(&slot).code = 98;

    // Out of the Slot, onto the std list.
    var list: std.SinglyLinkedList = .{};
    const out = parents.Event.EventHelper.mustMoveFromSlot(&slot);
    list.prepend(parents.Event.EventHelper.node(out));
    try helpers.expect(error.BorderPairFailed, slot == null, "slot should be empty after take");

    // Back from the std list. popFirst leaves the link pointing into the
    // list it left, so the crossing clears it first.
    const node = list.popFirst() orelse return error.EmptyList;
    node.next = null;
    const ev_back = parents.Event.EventHelper.fromNode(node) orelse return error.WrongType;
    const back: *Anchor = parents.Event.EventHelper.toAnchor(ev_back);

    matryoshka.inner.fillSlot(&slot, back);
    const ev = parents.Event.EventHelper.mustFromSlot(&slot);
    try helpers.expect(error.BorderPairFailed, ev.code == 98, "wrong event code");
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const Anchor = matryoshka.inner.Anchor;
const Slot = matryoshka.inner.Slot;
const std = @import("std");
