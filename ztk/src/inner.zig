// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! The small types the rest of the toolkit is built on.
//!
//! A **parent** is your struct, the one that embeds the TypedNode. Zig uses
//! the same word in `@fieldParentPtr`. It is not a parent in a tree of tasks
//! or mailboxes. In the Matryoshka model it is the outer doll: parent, then
//! TypedNode, then Anchor.
//!
//! An **item** is a parent while it is in a mailbox, a queue or a pool. The
//! word names a role, not a type. In code a container has an `*Anchor`, and
//! the names say `anchor`.
//!
//! - A parent embeds one `SinglyTypedNode` or `DoublyTypedNode`. Each is a
//!   std Node and an `Anchor`.
//! - A `Slot` is a place where one parent is, or is not.
//! - The mailbox and the pool see an `*Anchor` and nothing else.
//!
//! A parent's id says what type a parent is, never which parent it is. You
//! compare ids. You read nothing out of one.
//!
//! The id is null until setTypeId is called. So a zeroed TypedNode is valid,
//! with no type.
//!
//! Examples:
//! https://g41797.github.io/matryoshka-ztk/examples/inner/
const _doc_stub = void;

/// A parent's type id. You pass it and compare it. You read nothing out of
/// it.
///
/// Two parents of one type have the same id. Two types have two ids. The
/// helper's `ID` gives you one.
///
/// **Null is the id of a parent whose setTypeId was never called.** So zeroed
/// memory, such as `std.mem.zeroes` or a `@splat` of `.{}`, is a valid parent
/// with no type. It does not become some type by accident.
pub const TypeId = paternitas.TypeId;

/// The word inside every parent that setTypeId writes. Containers keep an
/// `*Anchor`.
pub const Anchor = paternitas.Anchor;

/// Embedded in a parent, once. A `std.SinglyLinkedList.Node` and an Anchor.
pub const SinglyTypedNode = paternitas.SinglyTypedNode;

/// Embedded in a parent, once. A `std.DoublyLinkedList.Node` and an Anchor.
///
/// A parent with a DoublyTypedNode can also live in your own
/// `std.DoublyLinkedList`, such as a timeout list or an LRU. It is in one
/// place at a time.
pub const DoublyTypedNode = paternitas.DoublyTypedNode;

/// The dispatch view of a parent: its address and its id.
///
/// Use it to keep a map from id to handler, with no toolkit calls in the hot
/// path.
///
/// It is only a view. A copy points at the same parent.
///
/// A ztk parent always has a TypedNode. So `fromAny` on a view of anything
/// else returns null.
pub const AnyParent = paternitas.Any;

/// A place where one parent is, or is not.
///
/// Empty means you have nothing. Full means you have that parent.
///
/// A call that takes the parent empties the Slot itself. You have no line to
/// write.
pub const Slot = ?*Anchor;

/// The chain link of a parent: the `next` field of its std Node. On a
/// toolkit chain it has an Anchor:
///
/// - the next parent's Anchor
/// - the Anchor itself, when it is the last one
/// - null, when the parent is on no chain
///
/// So the link test is exact. It costs one compare, and it sees a chain of
/// one.
///
/// Std lists share the `next` word. You MUST know three things:
///
/// - Take a parent off the toolkit's chains before it goes onto a std list.
///   One parent, one chain.
/// - The last link differs. Ours points at itself. Std's is null.
/// - Std does not clear the link when a parent leaves its list. A parent
///   straight from a std list still points into it, and `fillSlot` refuses
///   it.
///
/// Panics in every build mode when setTypeId was never called on the
/// parent. Without an id there is no `next`.
///
/// While a parent is on a toolkit chain, the word has an `*Anchor`, not a
/// std Node pointer. A debugger then shows it as a wrong Node pointer.
pub inline fn next(a: *Anchor) *?*Anchor {
    const ti = a.info() orelse @panic("setTypeId was never called on the parent: make it with create, or call setTypeId once");
    return @ptrCast(ti.nextField(a));
}

/// The parent in the Slot, as a dispatch view. The Slot stays full.
///
/// Null when the Slot is empty, or when setTypeId was never called on the
/// parent.
pub fn anyFromSlot(slot: *const Slot) ?AnyParent {
    const anchor = slot.* orelse return null;
    return anchor.toAny();
}

/// Takes the bare Anchor out of a Slot, for a container of your own. The
/// Slot ends up empty.
///
/// It returns an `*Anchor`, whatever type the parent is. `fillSlot` puts it
/// back.
///
/// It refuses:
///
/// - an empty Slot, in every build mode
/// - a parent whose setTypeId was never called
/// - a parent still on a chain
///
/// Do not copy the `*Anchor`. Two copies are two places for one parent, as
/// two copies of a Slot would be.
pub fn takeFromSlot(slot: *Slot) *Anchor {
    const anchor = slot.* orelse @panic("takeFromSlot: the Slot is empty");

    check(anchor.typeId() != null, "setTypeId was never called on the parent: make it with create, or call setTypeId once");
    check(!isLinked(anchor), "a parent crosses the border unlinked");

    slot.* = null;
    return anchor;
}

/// Puts a bare Anchor back into an empty Slot.
///
/// It refuses:
///
/// - a full Slot
/// - a parent whose setTypeId was never called
/// - a parent still on a chain
///
/// Is the parent coming from a std list? std does not clear the link when it
/// takes a parent off its list. The parent still points at its old
/// neighbour. So `fillSlot` takes it for a parent on a chain, and refuses
/// it. Call `unlink` on it first.
pub fn fillSlot(slot: *Slot, anchor: *Anchor) void {
    check(slot.* == null, "never overwrite a full Slot");
    check(anchor.typeId() != null, "setTypeId was never called on the parent: make it with create, or call setTypeId once");
    check(!isLinked(anchor), "a parent crosses the border unlinked: a std list leaves its link set");

    slot.* = anchor;
}

/// True when the parent is on a chain.
///
/// It is exact. The only parent of a chain points at itself, so it reads as
/// linked.
///
/// A parent with no type id is on no chain. Every insert refuses one.
pub inline fn isLinked(a: *Anchor) bool {
    if (a.typeId() == null) return false;
    return next(a).* != null;
}

/// Clears the chain link.
///
/// Every toolkit removal calls it for you. Nothing in the toolkit returns a
/// linked parent.
pub inline fn unlink(a: *Anchor) void {
    next(a).* = null;
}

const check = @import("internal/check.zig").check;
const paternitas = @import("paternitas");
