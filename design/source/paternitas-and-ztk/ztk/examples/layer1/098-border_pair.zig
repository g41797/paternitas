// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! The border pair: a Slot and a std list, one parent at a time.
//!
//! - The helper moves the parent out of the Slot, and gives its std Node.
//! - The Node goes onto a plain std.SinglyLinkedList.
//! - fromNode turns a popped Node back into the parent, checked by type.
//! - fillSlot puts the parent's Anchor into an empty Slot.
//!
//! A std list is a border, not a second home. While a parent sits on it the
//! toolkit does not know about it. std's popFirst leaves the Node's link
//! set, so the link must be cleared before fillSlot, which refuses a parent
//! that still looks linked.
//!
//!
//! ```
//!  slot ── mustMoveFromSlot ──► *Event ── node ──► list.prepend
//!                                                       │
//!                                                       ▼
//!                                               std.SinglyLinkedList
//!                                                       │ popFirst + clear link
//!                                                       ▼
//!  slot ◄── fillSlot ── toAnchor ◄── fromNode ◄──── *Node
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
