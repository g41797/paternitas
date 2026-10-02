// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Layer 1 — the id, the stamp and the Slot.
//!
//! Scenarios 1 to 5, 9, 200 to 209, 317.

const MSG = m.helper.ParentHelper(o.Msg);
const CHUNK = m.helper.ParentHelper(o.Chunk);
const NOTE = m.helper.ParentHelper(o.Note);

test "1 — an id is per type" {
    try expect(MSG.ID != CHUNK.ID);
    try expect(MSG.ID != NOTE.ID);
    try expect(CHUNK.ID != NOTE.ID);

    // The same type answers the same address every time.
    try expect(MSG.ID == m.helper.ParentHelper(o.Msg).ID);
}

test "2 — the stamp writes the id once" {
    var msg: o.Msg = .{};
    MSG.stamp(&msg);

    try expect(msg.hdr.anchor.type_id == MSG.ID);
    try expect(MSG.toAnchor(&msg).type_id == MSG.ID);
}

test "3 — an id answers what, never which" {
    var a: o.Msg = .{};
    var b: o.Msg = .{};
    MSG.stamp(&a);
    MSG.stamp(&b);

    // Two instances of one type share an id.
    try expect(MSG.toAnchor(&a).type_id == MSG.toAnchor(&b).type_id);

    // Which one it is, is a different question, and a different answer.
    try expect(&a != &b);
    try expect(MSG.isIt(MSG.toAnchor(&a).type_id));
}

test "4 — the crossing back, with the type known" {
    var msg: o.Msg = .{ .seq = 7, .payload = 99 };
    MSG.stamp(&msg);

    const back = MSG.fromAnchor(MSG.toAnchor(&msg)).?;

    try expect(back == &msg);
    try expect(back.seq == 7);
    try expect(back.payload == 99);
}

test "5 — the crossing back is refused on the wrong id" {
    var msg: o.Msg = .{};
    MSG.stamp(&msg);

    try expect(CHUNK.fromAnchor(MSG.toAnchor(&msg)) == null);
    try expect(NOTE.fromAnchor(MSG.toAnchor(&msg)) == null);
}

test "200 — the inner is found by type, not by name" {
    // Msg.hdr, Chunk.mtk, Note.chain. None of them is called `inner`.
    var msg: o.Msg = .{};
    var chunk: o.Chunk = .{};
    var note: o.Note = .{};

    MSG.stamp(&msg);
    CHUNK.stamp(&chunk);
    NOTE.stamp(&note);

    try expect(MSG.fromAnchor(&msg.hdr.anchor).? == &msg);
    try expect(CHUNK.fromAnchor(&chunk.mtk.anchor).? == &chunk);
    try expect(NOTE.fromAnchor(&note.chain.anchor).? == &note);
}

test "201 — the inner may sit anywhere in the parent" {
    // Msg has fields before its inner and Chunk has none, so the two offsets
    // differ. The offset itself is the toolkit's to know; what a caller sees is
    // that the crossing back lands on the parent either way.
    var chunk: o.Chunk = .{};
    CHUNK.stamp(&chunk);
    try expect(CHUNK.fromAnchor(CHUNK.toAnchor(&chunk)).? == &chunk);

    var msg: o.Msg = .{ .seq = 3 };
    MSG.stamp(&msg);

    try expect(MSG.fromAnchor(MSG.toAnchor(&msg)).?.seq == 3);
}

test "203 — an unstamped inner reads as unstamped" {
    var msg: o.Msg = .{};

    // Null is the unstamped id, so a declared parent is unstamped with nothing
    // written into it, and a zeroed one is too.
    try expect(msg.hdr.anchor.type_id == null);
    try expect(std.mem.zeroes(o.Msg).hdr.anchor.type_id == null);

    // The typed read is what a caller has: it answers null for an unstamped
    // inner exactly as it does for another type's.
    try expect(MSG.fromAnchor(&msg.hdr.anchor) == null);
}

test "205 — a mixed walk claims correctly" {
    var msg: o.Msg = .{};
    var chunk: o.Chunk = .{};
    var note: o.Note = .{};

    MSG.stamp(&msg);
    CHUNK.stamp(&chunk);
    NOTE.stamp(&note);

    var q: m.queue.Queue = .{};
    q.append(MSG.toAnchor(&msg));
    q.append(CHUNK.toAnchor(&chunk));
    q.append(NOTE.toAnchor(&note));

    var seen: usize = 0;
    while (q.popFirst()) |anchor| : (seen += 1) {
        const claims: usize = @as(usize, @intFromBool(MSG.fromAnchor(anchor) != null)) +
            @as(usize, @intFromBool(CHUNK.fromAnchor(anchor) != null)) +
            @as(usize, @intFromBool(NOTE.fromAnchor(anchor) != null));

        // Each item is claimed by its own type and refused by the other two.
        try expect(claims == 1);
    }

    try expect(seen == 3);
}

test "9 — a Slot holds one parent, or nothing" {
    var msg: o.Msg = .{ .seq = 1 };
    MSG.stamp(&msg);

    var slot: m.inner.Slot = null;
    try expect(slot == null);

    slot = MSG.toAnchor(&msg);
    try expect(MSG.fromSlot(&slot).? == &msg);

    _ = MSG.moveFromSlot(&slot);
    try expect(slot == null);
}

test "206 — a Slot starts empty" {
    const alloc = std.testing.allocator;

    var slot: m.inner.Slot = null;
    try MSG.create(alloc, std.testing.io, &slot);
    defer MSG.destroy(alloc, std.testing.io, &slot);

    // The acquiring call asserted it on entry. Here it is full afterwards.
    try expect(slot != null);
}

test "207 — a transfer clears the Slot" {
    var msg: o.Msg = .{};
    MSG.stamp(&msg);

    var slot: m.inner.Slot = MSG.toAnchor(&msg);
    var q: m.queue.Queue = .{};

    q.appendFromSlot(&slot);
    try expect(slot == null);

    slot = q.popFirst();
    try expect(slot != null);

    _ = MSG.mustMoveFromSlot(&slot);
    try expect(slot == null);
}

test "208 — a failed move leaves the Slot untouched" {
    var msg: o.Msg = .{};
    MSG.stamp(&msg);

    var slot: m.inner.Slot = MSG.toAnchor(&msg);

    try expect(CHUNK.moveFromSlot(&slot) == null);
    try expect(slot != null);
    try expect(MSG.fromSlot(&slot).? == &msg);
}

test "209 — a look is not a take" {
    var msg: o.Msg = .{};
    MSG.stamp(&msg);

    var slot: m.inner.Slot = MSG.toAnchor(&msg);

    try expect(MSG.fromSlot(&slot).? == &msg);
    try expect(MSG.mustFromSlot(&slot) == &msg);
    try expect(slot != null);

    try expect(MSG.moveFromSlot(&slot).? == &msg);
    try expect(slot == null);
}

test "317 — the toolkit states its version" {
    try expect(m.VERSION.len > 0);
}

const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const m = @import("matryoshka");
const o = @import("parents.zig");
const std = @import("std");
