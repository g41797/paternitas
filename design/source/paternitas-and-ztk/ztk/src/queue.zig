// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! A first in, first out chain of parents.
//!
//! The link is the `next` field of each parent's std Node, so a queue
//! allocates nothing and locks nothing. SLink and DLink parents mix freely.
//!
//! What a caller does with one — MUST:
//!
//! - Walk it with `while (q.popFirst())`. There is no iterator.
//! - Every item comes out with a clear link. No repair call.
//! - The items are the caller's to release.
//! - It is not a `std.SinglyLinkedList` and does not convert to one.
//! - A queue value is **moved, never copied**. `Mbox.close` hands one back by
//!   value, and the mailbox no longer has those items. Write
//!   `var rem = mbx.close();`. A second copy of that value is a second owner
//!   of one chain, and both would free it.
//!
//! Where a caller meets one: `Mbox.close` and `Mbox.receiveAll` hand one
//! back, and a pool's close hook is handed one.
//!
//! Examples:
//! https://g41797.github.io/matryoshka-ztk/examples/queue/
const _doc_stub = void;

/// A chain of parents, held by their Anchors.
///
/// The operation set is what a real behaviour needs: append, append from a
/// Slot, pop the first, is-empty, length, concat, and one counting read.
///
/// What it refuses, where runtime safety is on:
///
/// - a parent that was never stamped
/// - a parent already on a chain, including a chain of one
/// - an append from an empty Slot
/// - a concat onto itself
pub const Queue = struct {
    /// True when the queue holds no items.
    pub inline fn isEmpty(self: *const Queue) bool {
        return self._count == 0;
    }

    /// Number of items. A stored count, so O(1).
    pub inline fn len(self: *const Queue) usize {
        return self._count;
    }

    /// Adds the parent at the end.
    ///
    /// The new last item points at itself, which is what makes the link test
    /// exact.
    pub fn append(self: *Queue, anchor: *Anchor) void {
        self._guardInsert(anchor);

        inner.next(anchor).* = anchor;

        if (self._tail) |tail| {
            inner.next(tail).* = anchor;
        } else {
            self._head = anchor;
        }

        self._tail = anchor;
        self._count += 1;
    }

    /// Adds the parent at the end and empties the Slot.
    ///
    /// Refuses an empty Slot. An append is not a defer target, so it follows
    /// a send rather than a put.
    pub fn appendFromSlot(self: *Queue, slot: *Slot) void {
        check(slot.* != null, "appendFromSlot from an empty Slot");

        const anchor = slot.* orelse return;
        self.append(anchor);
        slot.* = null;
    }

    /// Takes the first parent out, or null when the queue is empty.
    ///
    /// The item comes back with a clear link. The caller repairs nothing.
    pub fn popFirst(self: *Queue) ?*Anchor {
        const anchor = self._head orelse return null;

        if (anchor == self._tail) {
            self._head = null;
            self._tail = null;
        } else {
            self._head = inner.next(anchor).*.?;
        }

        self._count -= 1;
        inner.unlink(anchor);

        return anchor;
    }

    /// Moves every item of `other` onto the end of this queue.
    ///
    /// `other` is left empty.
    ///
    /// Refuses a queue moved onto itself, and returns early where the check
    /// is compiled out — the move would otherwise ring the chain and lose
    /// every item on it.
    pub fn concat(self: *Queue, other: *Queue) void {
        check(self != other, "a queue cannot be moved onto itself");
        if (self == other) return;
        if (other.isEmpty()) return;

        const head = other._head.?;

        if (self._tail) |tail| {
            inner.next(tail).* = head;
        } else {
            self._head = head;
        }

        self._tail = other._tail;
        self._count += other._count;

        other._head = null;
        other._tail = null;
        other._count = 0;
    }

    /// How many parents on the chain carry this id, counting no further than
    /// `stop_at`.
    ///
    /// The one read that walks. It exists for the mailbox's send with a
    /// limit, which asks *are there already this many of the sender's own
    /// type* and does not care how many more there are.
    ///
    /// `stop_at` of zero counts the whole chain.
    ///
    /// This is not an iterator and does not become one. The walk stays
    /// inside the queue, and what a caller gets back is a number.
    pub fn countOfId(self: *const Queue, id: TypeId, stop_at: usize) usize {
        var seen: usize = 0;
        var at: ?*Anchor = self._head;

        while (at) |anchor| {
            if (anchor.type_id == id) {
                seen += 1;
                if (stop_at != 0 and seen >= stop_at) return seen;
            }

            const after = inner.next(anchor).*.?;
            if (after == anchor) break;
            at = after;
        }

        return seen;
    }

    /// The insert guard, stated once.
    ///
    /// Both checks read the item and cost one compare each.
    inline fn _guardInsert(self: *const Queue, anchor: *Anchor) void {
        _ = self;
        check(anchor.type_id != null, "the parent was never stamped: make it with create, or stamp it once");
        check(!inner.isLinked(anchor), "the parent is already on a chain");
    }

    _head: ?*Anchor = null,
    _tail: ?*Anchor = null,
    _count: usize = 0,
};

const check = @import("internal/check.zig").check;
const inner = @import("inner.zig");
const Anchor = inner.Anchor;
const TypeId = inner.TypeId;
const Slot = inner.Slot;
