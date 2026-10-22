// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Layer 1 — the helper, and the border.
//!
//! Scenarios 210 to 219, and 253.

const MSG = m.helper.ParentHelper(o.Msg);
const CHUNK = m.helper.ParentHelper(o.Chunk);
const BUF = m.helper.ParentHelper(o.Buf);
const BAD = m.helper.ParentHelper(o.BadInit);
const MBOX = m.helper.ParentHelper(o.FakeMbox);

test "210 — a parent declares init and finish" {
    // The requirement is a compile error at the create and release sites, so
    // what is checked here is that the declarations are there and typed as
    // the helper calls them.
    try expect(@hasDecl(o.Msg, "init"));
    try expect(@hasDecl(o.Msg, "finish"));
    try expect(@hasDecl(o.Buf, "init"));
    try expect(@hasDecl(o.Buf, "finish"));
}

test "211 — create runs the parent's init" {
    const alloc = std.testing.allocator;

    var slot: m.inner.Slot = null;
    try BUF.create(alloc, std.testing.io, &slot);
    defer BUF.destroy(alloc, std.testing.io, &slot);

    const buf = BUF.fromSlot(&slot).?;
    try expect(buf.bytes.len == o.Buf.size);
}

test "212 — a failing init frees the parent and passes the failure on" {
    const alloc = std.testing.allocator;

    var slot: m.inner.Slot = null;
    const failed = BAD.create(alloc, std.testing.io, &slot);

    try std.testing.expectError(o.BadInit.Failed.InitRefused, failed);
    try expect(slot == null);

    // The allocator checks the rest: the testing allocator fails the test if
    // the parent was not freed again.
}

test "213 — destroy runs the parent's finish before freeing" {
    const alloc = std.testing.allocator;

    var slot: m.inner.Slot = null;
    try BUF.create(alloc, std.testing.io, &slot);

    BUF.destroy(alloc, std.testing.io, &slot);
    try expect(slot == null);

    // What `finish` freed is what the testing allocator would report.
}

test "214 — destroy on an empty Slot does nothing" {
    const alloc = std.testing.allocator;

    var slot: m.inner.Slot = null;
    MSG.destroy(alloc, std.testing.io, &slot);

    try expect(slot == null);

    // So one defer covers the path where the parent was never created.
    var early: m.inner.Slot = null;
    defer MSG.destroy(alloc, std.testing.io, &early);
}

test "215 — create and destroy, repeatedly" {
    const alloc = std.testing.allocator;

    var slot: m.inner.Slot = null;
    var round: usize = 0;

    while (round < 16) : (round += 1) {
        try MSG.create(alloc, std.testing.io, &slot);
        try expect(slot != null);

        MSG.destroy(alloc, std.testing.io, &slot);
        try expect(slot == null);
    }
}

test "216 — a created parent is an ordinary parent" {
    const alloc = std.testing.allocator;

    var slot: m.inner.Slot = null;
    try MSG.create(alloc, std.testing.io, &slot);

    var q: m.queue.Queue = .{};
    q.appendFromSlot(&slot);

    try expect(q.len() == 1);

    slot = q.popFirst();
    const msg = MSG.fromSlot(&slot).?;

    // Nothing marks it as having been made by the helper.
    try expect(msg.hdr.anchor.typeId() == MSG.ID);

    MSG.destroy(alloc, std.testing.io, &slot);
}

test "217 — the panicking take answers on a match" {
    const alloc = std.testing.allocator;

    var slot: m.inner.Slot = null;
    try MSG.create(alloc, std.testing.io, &slot);

    const msg = MSG.mustMoveFromSlot(&slot);
    try expect(slot == null);

    // The wrong-type and empty-Slot halves panic. They are scenarios 301 and
    // 303, and they run outside the test binary.
    var back: m.inner.Slot = MSG.toAnchor(msg);
    MSG.destroy(alloc, std.testing.io, &back);
}

test "218 — the border pair, out and back" {
    var msg: o.Msg = .{ .seq = 8 };
    MSG.setTypeId(&msg);

    var slot: m.inner.Slot = MSG.toAnchor(&msg);

    const anchor = m.inner.takeFromSlot(&slot);

    try expect(slot == null);
    try expect(!m.inner.isLinked(anchor));
    try expect(MSG.fromAnchor(anchor) != null);

    m.inner.fillSlot(&slot, anchor);

    try expect(slot.? == anchor);
    try expect(MSG.fromSlot(&slot).? == &msg);
}

test "219 — the border pair round trip through a std list" {
    var a: o.Msg = .{ .seq = 1 };
    var b: o.Msg = .{ .seq = 2 };
    MSG.setTypeId(&a);
    MSG.setTypeId(&b);

    var slot: m.inner.Slot = MSG.toAnchor(&a);
    var list: std.SinglyLinkedList = .{};

    // Out of the toolkit, one item at a time, into a container of the
    // caller's own.
    list.prepend(MSG.node(MSG.mustMoveFromSlot(&slot)));

    slot = MSG.toAnchor(&b);
    list.prepend(MSG.node(MSG.mustMoveFromSlot(&slot)));

    try expect(slot == null);
    try expect(list.len() == 2);

    // Back again. std leaves its link set, so the caller clears it — which
    // is the line the toolkit's own queue does not make anyone write.
    var seen: usize = 0;
    while (list.popFirst()) |node| : (seen += 1) {
        node.next = null;

        const anchor = MSG.toAnchor(MSG.fromNode(node).?);
        m.inner.fillSlot(&slot, anchor);

        const msg = MSG.moveFromSlot(&slot).?;
        try expect(msg.seq == 2 - seen);
    }

    try expect(seen == 2);
}

test "253 — a container declares no create and no destroy" {
    // FakeMbox has neither hook, and it is still a parent: it has an id and
    // the crossings work. Asking for create or destroy does not compile, and
    // that is scenarios 308 and 309.
    var fake: o.FakeMbox = .{};
    MBOX.setTypeId(&fake);

    try expect(!@hasDecl(o.FakeMbox, "init"));
    try expect(!@hasDecl(o.FakeMbox, "finish"));

    try expect(MBOX.fromAnchor(MBOX.toAnchor(&fake)).? == &fake);
    try expect(CHUNK.fromAnchor(MBOX.toAnchor(&fake)) == null);
}

const expect = std.testing.expect;
const m = @import("matryoshka");
const o = @import("parents.zig");
const std = @import("std");
