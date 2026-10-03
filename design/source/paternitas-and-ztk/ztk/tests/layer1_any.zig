// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Layer 1 — parents outside the toolkit: the bare Anchor, the dispatch view,
//! and the DoublyTypedNode.
//!
//! Scenarios 320 to 329.

const MSG = m.helper.ParentHelper(o.Msg);
const CHUNK = m.helper.ParentHelper(o.Chunk);

test "320 — takeFromSlot and fillSlot carry one parent out and back" {
    var msg: o.Msg = .{ .seq = 7 };
    MSG.setTypeId(&msg);

    var slot: m.inner.Slot = MSG.toAnchor(&msg);
    const bare: *m.inner.Anchor = m.inner.takeFromSlot(&slot);

    try expect(slot == null);
    try expect(MSG.fromAnchor(bare).? == &msg);

    m.inner.fillSlot(&slot, bare);
    try expect(MSG.fromSlot(&slot).? == &msg);
}

test "321 — anyFromSlot is a view: the parent's address and id, and the Slot stays full" {
    var msg: o.Msg = .{ .seq = 9 };
    MSG.setTypeId(&msg);

    var slot: m.inner.Slot = MSG.toAnchor(&msg);
    const any = m.inner.anyFromSlot(&slot).?;

    try expect(slot != null);
    try expect(any.ptr == @as(*anyopaque, &msg));
    try expect(any.type_id == MSG.ID);
}

test "322 — toAny and fromAny round-trip" {
    var msg: o.Msg = .{};
    MSG.setTypeId(&msg);

    try expect(MSG.fromAny(MSG.toAny(&msg)).? == &msg);
}

test "323 — fromAny answers null for a wrong type; anyFromSlot for an empty Slot" {
    var msg: o.Msg = .{};
    MSG.setTypeId(&msg);

    try expect(CHUNK.fromAny(MSG.toAny(&msg)) == null);

    const empty: m.inner.Slot = null;
    try expect(m.inner.anyFromSlot(&empty) == null);
}

test "324 — a TypedNode at a nonzero and a zero offset both round-trip" {
    var chunk: o.Chunk = .{};
    CHUNK.setTypeId(&chunk);

    var slot: m.inner.Slot = CHUNK.toAnchor(&chunk);
    try expect(CHUNK.fromAny(m.inner.anyFromSlot(&slot).?).? == &chunk);

    const bare = m.inner.takeFromSlot(&slot);
    m.inner.fillSlot(&slot, bare);
    try expect(CHUNK.fromSlot(&slot).? == &chunk);
}

test "325 — a bare Anchor travels through a std queue" {
    const Item = union(enum) { parent: *m.inner.Anchor, quit };

    var buf: [2]Item = undefined;
    var q: std.Io.Queue(Item) = .init(&buf);
    const io = std.testing.io;

    var msg: o.Msg = .{ .seq = 42 };
    MSG.setTypeId(&msg);

    var slot: m.inner.Slot = MSG.toAnchor(&msg);
    try q.putOne(io, .{ .parent = m.inner.takeFromSlot(&slot) });

    const got = try q.getOne(io);
    m.inner.fillSlot(&slot, got.parent);
    try expect(MSG.fromSlot(&slot).?.seq == 42);
}

test "326 — dispatch by id: a handler map, no helper at the call" {
    const H = struct {
        var seq: u32 = 0;
        var size: usize = 0;
        fn onMsg(p: *anyopaque) void {
            const msg: *o.Msg = @ptrCast(@alignCast(p));
            seq = msg.seq;
        }
        fn onChunk(p: *anyopaque) void {
            const chunk: *o.Chunk = @ptrCast(@alignCast(p));
            size = chunk.size;
        }
    };
    const Handler = *const fn (*anyopaque) void;

    var handlers = std.AutoHashMap(m.inner.TypeId, Handler).init(std.testing.allocator);
    defer handlers.deinit();
    try handlers.put(MSG.ID, H.onMsg);
    try handlers.put(CHUNK.ID, H.onChunk);

    var msg: o.Msg = .{ .seq = 5 };
    var chunk: o.Chunk = .{ .size = 64 };
    MSG.setTypeId(&msg);
    CHUNK.setTypeId(&chunk);

    var q: m.queue.Queue = .{};
    q.append(MSG.toAnchor(&msg));
    q.append(CHUNK.toAnchor(&chunk));

    while (q.popFirst()) |anchor| {
        const slot: m.inner.Slot = anchor;
        const any = m.inner.anyFromSlot(&slot).?;
        (handlers.get(any.type_id).?)(any.ptr);
    }

    try expect(H.seq == 5);
    try expect(H.size == 64);
}

/// A parent with a DoublyTypedNode: it can also live in a `std.DoublyLinkedList`.
const Timed = struct {
    deadline: u64 = 0,
    tnode: m.inner.DoublyTypedNode = .{},
};

const TIMED = m.helper.ParentHelper(Timed);

test "327 — a DoublyTypedNode parent shares a queue with SinglyTypedNode parents, then goes onto a std list" {
    var msg: o.Msg = .{ .seq = 1 };
    var timed: Timed = .{ .deadline = 99 };
    MSG.setTypeId(&msg);
    TIMED.setTypeId(&timed);

    var q: m.queue.Queue = .{};
    q.append(MSG.toAnchor(&msg));
    q.append(TIMED.toAnchor(&timed));
    try expect(TIMED.isLinked(&timed));

    try expect(MSG.fromAnchor(q.popFirst().?).? == &msg);
    const t = TIMED.fromAnchor(q.popFirst().?).?;
    try expect(!TIMED.isLinked(t));

    var timeouts: std.DoublyLinkedList = .{};
    timeouts.append(TIMED.node(t));

    const back = TIMED.fromNode(timeouts.popFirst().?).?;
    try expect(back.deadline == 99);

    // std leaves both words set. Clear them before the toolkit takes it back.
    TIMED.node(back).* = .{};
    q.append(TIMED.toAnchor(back));
    try expect(q.len() == 1);
}

test "328 — a DoublyTypedNode parent goes from a std list to a queue and back to the std list" {
    var a: Timed = .{ .deadline = 1 };
    var b: Timed = .{ .deadline = 2 };
    TIMED.setTypeId(&a);
    TIMED.setTypeId(&b);

    var timeouts: std.DoublyLinkedList = .{};
    timeouts.append(TIMED.node(&a));
    timeouts.append(TIMED.node(&b));

    // Out of the application's list. O(1) removal from the middle is what
    // the DoublyTypedNode is for.
    timeouts.remove(TIMED.node(&b));
    TIMED.node(&b).* = .{};

    var q: m.queue.Queue = .{};
    q.append(TIMED.toAnchor(&b));
    try expect(TIMED.isLinked(&b));

    const back = TIMED.fromAnchor(q.popFirst().?).?;
    try expect(back == &b);
    try expect(!TIMED.isLinked(back));

    // Into the application's list again.
    timeouts.append(TIMED.node(back));
    try expect(TIMED.fromNode(timeouts.popFirst().?).?.deadline == 1);
    try expect(TIMED.fromNode(timeouts.popFirst().?).?.deadline == 2);
    try expect(timeouts.first == null);
}

test "329 — on a chain, the Node's next word holds an Anchor" {
    var msg: o.Msg = .{};
    var timed: Timed = .{};
    MSG.setTypeId(&msg);
    TIMED.setTypeId(&timed);

    const ma = MSG.toAnchor(&msg);
    const ta = TIMED.toAnchor(&timed);

    var q: m.queue.Queue = .{};
    q.append(ma);
    q.append(ta);

    // The raw word, read through Paternitas's location only, and through
    // the std field it overlays.
    const m_raw: *?*anyopaque = ma.info().?.nextField(ma);
    const t_raw: *?*anyopaque = ta.info().?.nextField(ta);
    try expect(m_raw.*.? == @as(*anyopaque, ta));
    try expect(t_raw.*.? == @as(*anyopaque, ta));
    try expect(@intFromPtr(m_raw) == @intFromPtr(&MSG.node(&msg).next));
    try expect(@intFromPtr(t_raw) == @intFromPtr(&TIMED.node(&timed).next));

    _ = q.popFirst();
    _ = q.popFirst();
    try expect(m_raw.* == null);
    try expect(t_raw.* == null);
}

const expect = std.testing.expect;
const m = @import("matryoshka");
const o = @import("parents.zig");
const std = @import("std");
