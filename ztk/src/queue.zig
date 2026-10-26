// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! A first in, first out chain of parents.
//!
//! A queue links parents through their own TypedNode. It allocates nothing
//! and locks nothing. SinglyTypedNode and DoublyTypedNode parents mix freely.
//!
//! Five things you MUST know:
//!
//! - Walk it with `while (q.popFirst())`. There is no iterator.
//! - Each parent comes out with a clear link. You repair nothing.
//! - The parents are yours to release.
//! - It is not a `std.SinglyLinkedList`, and does not convert to one.
//! - Move a queue value. Never copy it.
//!   - `Mbox.close` returns one by value. The mailbox no longer has those
//!     parents.
//!   - Write `var rem = mbx.close();`.
//!   - A copy is a second queue over the same chain. Both would release it.
//!
//! You meet a queue in three places:
//!
//! - `Mbox.close` returns one.
//! - `Mbox.receiveAll` returns one.
//! - A pool's close hook gets one.
//!
//! Examples:
//! https://g41797.github.io/matryoshka-ztk/examples/queue/
const _doc_stub = void;

/// A chain of parents, linked through their Anchors.
///
/// It refuses these, where runtime safety is on:
///
/// - a parent whose setTypeId was never called
/// - a parent already on a chain, even a chain of one
/// - an append from an empty Slot
/// - a concat onto itself
pub const Queue = struct {
    /// True when the queue has no parents.
    pub inline fn isEmpty(self: *const Queue) bool {
        return self._count == 0;
    }

    /// The number of parents. O(1): the queue keeps a count.
    pub inline fn len(self: *const Queue) usize {
        return self._count;
    }

    /// Adds the parent at the end.
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
    /// Refuses an empty Slot, as `send` does.
    pub fn appendFromSlot(self: *Queue, slot: *Slot) void {
        check(slot.* != null, "appendFromSlot from an empty Slot");

        const anchor = slot.* orelse return;
        self.append(anchor);
        slot.* = null;
    }

    /// Takes the first parent out. Null when the queue is empty.
    ///
    /// The parent comes out with a clear link. You repair nothing.
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

    /// Moves every parent of `other` to the end of this queue.
    ///
    /// `other` ends up empty.
    ///
    /// Refuses a queue moved onto itself. With runtime safety off, it does
    /// nothing. The move would turn the chain into a ring and lose every
    /// parent.
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

    /// Counts the parents with this id. It stops at `stop_at`.
    ///
    /// `stop_at` of zero counts the whole chain.
    ///
    /// It walks the chain and returns a number. It is not an iterator.
    pub fn countOfId(self: *const Queue, id: TypeId, stop_at: usize) usize {
        var seen: usize = 0;
        var at: ?*Anchor = self._head;

        while (at) |anchor| {
            if (anchor.typeId() == id) {
                seen += 1;
                if (stop_at != 0 and seen >= stop_at) return seen;
            }

            const after = inner.next(anchor).*.?;
            if (after == anchor) break;
            at = after;
        }

        return seen;
    }

    /// The insert checks, in one place. Each costs one compare.
    inline fn _guardInsert(self: *const Queue, anchor: *Anchor) void {
        _ = self;
        check(anchor.typeId() != null, "setTypeId was never called on the parent: make it with create, or call setTypeId once");
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
