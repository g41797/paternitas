// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! A last in, first out chain of parents. The pool keeps its parents here.
//!
//! A stack links parents through their own TypedNode. It allocates nothing
//! and locks nothing. It uses the same chain and the same insert checks as
//! the queue, with the other end open.
//!
//! The pool uses a stack, not a queue, to catch broken parents early.
//!
//! - The parent that came back last goes out first.
//! - A parent that went bad comes back out at once, and the next user sees
//!   it.
//! - A queue would give out the oldest parent first. A broken one could wait
//!   at the end for as long as the pool stays busy.
//!
//! Internal. Only `pool.zig` uses it.
//!
//! - `matryoshka.zig` does not export it.
//! - No public call takes one or returns one.
//! - A caller gets a `Queue` instead: a pool's close empties every store
//!   into one.
const _doc_stub = void;

/// A chain of parents, linked through their Anchors. The last one in is on
/// top.
///
/// The top parent points at itself, as the last parent of a queue does. So
/// `isLinked` is exact here too, even on a stack of one.
///
/// It refuses these, where runtime safety is on:
///
/// - a parent whose setTypeId was never called
/// - a parent already on a chain, even a chain of one
pub const AnchorStack = struct {
    /// True when the stack has no parents.
    pub inline fn isEmpty(self: *const AnchorStack) bool {
        return self._count == 0;
    }

    /// The number of parents. O(1): the stack keeps a count.
    ///
    /// The pool's `in_pool` reads this count. The pool keeps no second count.
    pub inline fn len(self: *const AnchorStack) usize {
        return self._count;
    }

    /// Puts the parent on top.
    pub fn push(self: *AnchorStack, anchor: *Anchor) void {
        self._guardInsert(anchor);

        inner.next(anchor).* = self._top orelse anchor;

        self._top = anchor;
        self._count += 1;
    }

    /// Takes the top parent off. Null when the stack is empty.
    ///
    /// The parent comes out with a clear link. The caller repairs nothing.
    pub fn pop(self: *AnchorStack) ?*Anchor {
        const anchor = self._top orelse return null;

        const after = inner.next(anchor).*.?;
        self._top = if (after == anchor) null else after;

        self._count -= 1;
        inner.unlink(anchor);

        return anchor;
    }

    /// The insert checks, the same as the queue's.
    inline fn _guardInsert(self: *const AnchorStack, anchor: *Anchor) void {
        _ = self;
        check(anchor.typeId() != null, "setTypeId was never called on the parent: make it with create, or call setTypeId once");
        check(!inner.isLinked(anchor), "the parent is already on a chain");
    }

    _top: ?*Anchor = null,
    _count: usize = 0,
};

const check = @import("check.zig").check;
const inner = @import("../inner.zig");
const Anchor = inner.Anchor;
