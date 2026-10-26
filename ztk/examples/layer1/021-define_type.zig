// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Define a parent type
//!
//! A struct becomes a parent: one TypedNode field and a helper.
//!
//! - Embed a SinglyTypedNode in `Message`. The field's name is yours.
//! - Make the helper: `ParentHelper(Message)`.
//! - Call setTypeId on a `Message` on the stack. No heap.
//! - Check the id with `isIt`.
//! - Get the embedded Anchor with `toAnchor`.
//!
//! The parent now has its id, and is on no chain. The way back, `fromAnchor`,
//! needs a parent whose type you do not know yet. Example 023 shows it.
//!
//! ```
//!  stack: var msg: Message
//!       │
//!  MessageHelper.setTypeId ──► the id is written (no allocation)
//!       │
//!  MessageHelper.toAnchor ──► *Anchor
//!       │
//!  the parent has its id, on no chain
//!  (on the stack: nothing to release)
//! ```
//!

pub fn define_a_parent_type(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = .{ allocator, io };

    // A Message on the stack. No allocator involved.
    var msg: Message = .{ .text = "hello", .priority = 1 };
    MessageHelper.setTypeId(&msg);

    // The id identifies the type at runtime.
    try helpers.expect(error.DefineTypeFailed, MessageHelper.isIt(msg.hdr.anchor.typeId()), "expected Message id");
    try helpers.expect(error.DefineTypeFailed, !parents.Event.EventHelper.isIt(msg.hdr.anchor.typeId()), "unexpected Event id");

    // toAnchor reaches the embedded Anchor. Nothing else needs to know
    // the field is called hdr.
    const inner: *Anchor = MessageHelper.toAnchor(&msg);

    // The inner travels with its id, so a holder can identify it later.
    try helpers.expect(error.DefineTypeFailed, MessageHelper.isIt(inner.typeId()), "inner must carry the Message id");

    // A fresh parent sits on no chain yet.
    try helpers.expect(error.DefineTypeFailed, !matryoshka.inner.isLinked(inner), "new parent must be unlinked");
}

pub const Message = struct {
    hdr: SinglyTypedNode = .{},
    text: []const u8 = "",
    priority: u8 = 0,
};

pub const MessageHelper = matryoshka.helper.ParentHelper(Message);

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const Anchor = matryoshka.inner.Anchor;
const SinglyTypedNode = matryoshka.inner.SinglyTypedNode;
const std = @import("std");
