// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: From your own timeout list and back
//!
//! A parent leaves your `std.DoublyLinkedList`, goes through a mailbox, and
//! comes back.
//!
//! - Put three Deadlines in your own `std.DoublyLinkedList`.
//! - Remove the middle one, in O(1). That is what the DoublyTypedNode is for.
//! - Clear its links, put it into a Slot, send it, and receive it into a Slot.
//! - Move it out, and append it to the timeout list.
//!
//! While the parent is on your list, the toolkit does not know it. std's
//! `remove` leaves both links set. Clear them before `fillSlot`, which refuses
//! a parent that still looks linked.
//!
//! ```
//!  timeouts ── remove + clear ──► toAnchor ── fillSlot ──► Slot ──mbx.send──► mailbox
//!     ▲                                                                         │ mbx.receive
//!     │                                                                         ▼
//!     └──────────── append ◄── node ◄── mustMoveFromSlot ◄─────────────────── Slot
//! ```
//!

pub fn dlink_timeout_list(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: matryoshka.queue.Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var timeouts: std.DoublyLinkedList = .{};
    defer drain(&timeouts, allocator, io);

    for ([_]u64{ 10, 20, 30 }) |due| {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        try DL.create(allocator, io, &slot);
        const d = DL.mustMoveFromSlot(&slot);
        d.due_ms = due;
        timeouts.append(DL.node(d));
    }

    // Out of the timeout list, from the middle.
    const mid = DL.fromNode(timeouts.first.?.next.?) orelse return error.WrongType;
    timeouts.remove(DL.node(mid));
    DL.node(mid).* = .{};

    {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        matryoshka.inner.fillSlot(&slot, DL.toAnchor(mid));
        try mbx.send(&slot);
    }

    {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        try mbx.receive(&slot, 1_000_000_000);
        const back = DL.moveFromSlot(&slot) orelse return error.WrongTag;
        try helpers.expect(error.DlinkTimeoutListFailed, back.due_ms == 20, "wrong deadline");

        // Into the timeout list again.
        timeouts.append(DL.node(back));
    }

    var want = [_]u64{ 10, 30, 20 };
    var it = timeouts.first;
    for (&want) |w| {
        const n = it orelse return error.DlinkTimeoutListFailed;
        const d = DL.fromNode(n) orelse return error.WrongType;
        try helpers.expect(error.DlinkTimeoutListFailed, d.due_ms == w, "wrong order");
        it = n.next;
    }
    try helpers.expect(error.DlinkTimeoutListFailed, it == null, "too many in the list");
}

/// Releases every Deadline still in the timeout list.
fn drain(timeouts: *std.DoublyLinkedList, allocator: std.mem.Allocator, io: std.Io) void {
    while (timeouts.popFirst()) |n| {
        n.* = .{};
        var slot: Slot = null;
        matryoshka.inner.fillSlot(&slot, DL.toAnchor(DL.fromNode(n).?));
        DL.destroy(allocator, io, &slot);
    }
}

const DL = parents.Deadline.DeadlineHelper;
const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
