// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Layer 1 — the chain.
//!
//! Scenarios 240 to 252, and the state transitions 11 to 14.

const MSG = m.helper.ParentHelper(o.Msg);
const CHUNK = m.helper.ParentHelper(o.Chunk);
const NOTE = m.helper.ParentHelper(o.Note);

/// Three parents with their type ids set, on the test's own stack.
const Three = struct {
    a: o.Msg = .{ .seq = 1 },
    b: o.Msg = .{ .seq = 2 },
    c: o.Msg = .{ .seq = 3 },

    fn setTypeIds(self: *Three) void {
        MSG.setTypeId(&self.a);
        MSG.setTypeId(&self.b);
        MSG.setTypeId(&self.c);
    }
};

test "240 — the chain is first in, first out" {
    var t: Three = .{};
    t.setTypeIds();

    var q: m.queue.Queue = .{};
    q.append(MSG.toAnchor(&t.a));
    q.append(MSG.toAnchor(&t.b));
    q.append(MSG.toAnchor(&t.c));

    try expect(MSG.fromAnchor(q.popFirst().?).?.seq == 1);
    try expect(MSG.fromAnchor(q.popFirst().?).?.seq == 2);
    try expect(MSG.fromAnchor(q.popFirst().?).?.seq == 3);
    try expect(q.popFirst() == null);
}

test "241 — an empty chain answers" {
    var q: m.queue.Queue = .{};

    try expect(q.isEmpty());
    try expect(q.len() == 0);
    try expect(q.popFirst() == null);
}

test "242 — the last item points at itself" {
    var t: Three = .{};
    t.setTypeIds();

    var q: m.queue.Queue = .{};
    q.append(MSG.toAnchor(&t.a));

    try expect(m.inner.next(MSG.toAnchor(&t.a)).*.? == MSG.toAnchor(&t.a));

    q.append(MSG.toAnchor(&t.b));

    try expect(m.inner.next(MSG.toAnchor(&t.a)).*.? == MSG.toAnchor(&t.b));
    try expect(m.inner.next(MSG.toAnchor(&t.b)).*.? == MSG.toAnchor(&t.b));
}

test "243 — the link test is exact, including a chain of one" {
    var t: Three = .{};
    t.setTypeIds();

    try expect(!MSG.isLinked(&t.a));

    var q: m.queue.Queue = .{};
    q.append(MSG.toAnchor(&t.a));

    // Alone on the chain, and seen. The old blind test could not.
    try expect(MSG.isLinked(&t.a));

    _ = q.popFirst();
    try expect(!MSG.isLinked(&t.a));
}

test "244 — the link test sees another container" {
    var t: Three = .{};
    t.setTypeIds();

    var first: m.queue.Queue = .{};
    first.append(MSG.toAnchor(&t.a));

    // A second queue reads the same field and sees the item is taken.
    try expect(m.inner.isLinked(MSG.toAnchor(&t.a)));

    _ = first.popFirst();

    var second: m.queue.Queue = .{};
    second.append(MSG.toAnchor(&t.a));
    try expect(second.len() == 1);
}

test "245 — every removal repairs the chain" {
    var t: Three = .{};
    t.setTypeIds();

    var q: m.queue.Queue = .{};
    q.append(MSG.toAnchor(&t.a));
    q.append(MSG.toAnchor(&t.b));

    var slot: m.inner.Slot = q.popFirst();

    // No repair step for the caller: it drops straight into a Slot and out.
    try expect(!m.inner.isLinked(slot.?));
    try expect(MSG.moveFromSlot(&slot).? == &t.a);
}

test "246 — length is a stored count" {
    var t: Three = .{};
    t.setTypeIds();

    var q: m.queue.Queue = .{};
    try expect(q.len() == 0);

    q.append(MSG.toAnchor(&t.a));
    try expect(q.len() == 1);

    q.append(MSG.toAnchor(&t.b));
    try expect(q.len() == 2);

    _ = q.popFirst();
    try expect(q.len() == 1);

    var other: m.queue.Queue = .{};
    other.append(MSG.toAnchor(&t.c));
    q.concat(&other);

    try expect(q.len() == 2);
    try expect(other.len() == 0);
}

test "247 — pop feeds append-from-Slot directly" {
    var t: Three = .{};
    t.setTypeIds();

    var source: m.queue.Queue = .{};
    source.append(MSG.toAnchor(&t.a));

    var slot: m.inner.Slot = source.popFirst();

    var target: m.queue.Queue = .{};
    target.appendFromSlot(&slot);

    try expect(slot == null);
    try expect(target.len() == 1);
}

test "248 — append-from-Slot takes the parent" {
    var t: Three = .{};
    t.setTypeIds();

    var slot: m.inner.Slot = MSG.toAnchor(&t.a);

    var q: m.queue.Queue = .{};
    q.appendFromSlot(&slot);

    try expect(slot == null);
    try expect(q.len() == 1);
}

test "249 — concat moves every item and empties the source" {
    var t: Three = .{};
    t.setTypeIds();

    var left: m.queue.Queue = .{};
    var right: m.queue.Queue = .{};

    left.append(MSG.toAnchor(&t.a));
    right.append(MSG.toAnchor(&t.b));
    right.append(MSG.toAnchor(&t.c));

    left.concat(&right);

    try expect(left.len() == 3);
    try expect(right.isEmpty());
    try expect(right.popFirst() == null);

    // The empty cases at either end.
    var empty: m.queue.Queue = .{};
    left.concat(&empty);
    try expect(left.len() == 3);

    empty.concat(&left);
    try expect(empty.len() == 3);
    try expect(left.isEmpty());

    while (empty.popFirst()) |_| {}
}

test "250 — concat keeps the chain walkable" {
    var t: Three = .{};
    t.setTypeIds();

    var left: m.queue.Queue = .{};
    var right: m.queue.Queue = .{};

    left.append(MSG.toAnchor(&t.a));
    right.append(MSG.toAnchor(&t.b));
    right.append(MSG.toAnchor(&t.c));

    left.concat(&right);

    // The joined chain still ends in an item pointing at itself.
    try expect(m.inner.next(MSG.toAnchor(&t.c)).*.? == MSG.toAnchor(&t.c));

    try expect(MSG.fromAnchor(left.popFirst().?).?.seq == 1);
    try expect(MSG.fromAnchor(left.popFirst().?).?.seq == 2);
    try expect(MSG.fromAnchor(left.popFirst().?).?.seq == 3);
    try expect(left.popFirst() == null);
}

test "251 — a chain onto itself does not destroy it" {
    if (std.debug.runtime_safety) return error.SkipZigTest;

    var t: Three = .{};
    t.setTypeIds();

    var q: m.queue.Queue = .{};
    q.append(MSG.toAnchor(&t.a));
    q.append(MSG.toAnchor(&t.b));

    // Where the check is compiled out, the early return is what saves it.
    q.concat(&q);

    try expect(q.len() == 2);
    try expect(MSG.fromAnchor(q.popFirst().?).?.seq == 1);
    try expect(MSG.fromAnchor(q.popFirst().?).?.seq == 2);
}

test "252 — one chain, three types" {
    var msg: o.Msg = .{ .seq = 4 };
    var chunk: o.Chunk = .{ .size = 16 };
    var note: o.Note = .{};

    MSG.setTypeId(&msg);
    CHUNK.setTypeId(&chunk);
    NOTE.setTypeId(&note);

    var q: m.queue.Queue = .{};
    q.append(MSG.toAnchor(&msg));
    q.append(CHUNK.toAnchor(&chunk));
    q.append(NOTE.toAnchor(&note));

    try expect(MSG.fromAnchor(q.popFirst().?).?.seq == 4);
    try expect(CHUNK.fromAnchor(q.popFirst().?).?.size == 16);
    try expect(NOTE.fromAnchor(q.popFirst().?).? == &note);
}

test "11 to 14 — the item states" {
    const alloc = std.testing.allocator;

    // 11. FREE to IN_FLIGHT.
    var slot: m.inner.Slot = null;
    try MSG.create(alloc, std.testing.io, &slot);

    try expect(slot != null);
    try expect(!m.inner.isLinked(slot.?));

    // 12. IN_FLIGHT to HELD.
    var q: m.queue.Queue = .{};
    q.appendFromSlot(&slot);

    try expect(slot == null);
    try expect(q.len() == 1);

    // 13. HELD to IN_FLIGHT.
    slot = q.popFirst();

    try expect(slot != null);
    try expect(!m.inner.isLinked(slot.?));

    // 14. IN_FLIGHT to FREE.
    MSG.destroy(alloc, std.testing.io, &slot);

    try expect(slot == null);
}

const expect = std.testing.expect;
const m = @import("matryoshka");
const o = @import("parents.zig");
const std = @import("std");
