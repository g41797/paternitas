// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! The small types everything else is written against.
//!
//! **Parent** means the struct that embeds the Link — the word Zig uses in
//! `@fieldParentPtr`. It is not a parent in a tree of tasks or mailboxes.
//! In the Matryoshka model it is the outer doll: parent, then Link, then
//! Anchor.
//!
//! An **item** is a parent while it is in a mailbox, a queue or a pool. The
//! word names that role, not a type. In code, what a container holds is an
//! `*Anchor`, and the names say `anchor`.
//!
//! - A parent embeds one `SLink` or `DLink`: a std Node and an `Anchor`.
//! - `Slot` is the place where one parent may be, or may not.
//! - The mailbox and the pool see an `*Anchor` and nothing else.
//!
//! The types come from Paternitas. This file adds what Matryoshka decides:
//! the chain convention, the Slot, and the borders out of the toolkit.
//!
//! A parent's id is an opaque pointer, compared by address, so an id says what
//! a thing is and never which one it is. An unstamped parent's id is null, so a
//! zeroed Link is a valid unstamped Link.
//!
//! Examples:
//! https://g41797.github.io/matryoshka-ztk/examples/inner/
const _doc_stub = void;

/// A parent's id. Opaque: a caller passes it and compares it, and reads
/// nothing out of it.
///
/// Two parents of one type answer the same id. Two types answer two ids. The
/// helper's `ID` is where one comes from, and the toolkit is what reads it.
///
/// **Null is the id of a parent that was never stamped.** So the zero value of
/// a Link is unstamped, and zeroed memory — `std.mem.zeroes`, a `@splat`
/// of `.{}` — is a valid unstamped parent rather than an accidental one.
pub const TypeId = paternitas.TypeId;

/// The stamped word inside every parent. `*Anchor` is what containers hold.
pub const Anchor = paternitas.Anchor;

/// Embedded in a parent, once. A `std.SinglyLinkedList.Node` and an Anchor.
pub const SLink = paternitas.SLink;

/// Embedded in a parent, once. A `std.DoublyLinkedList.Node` and an Anchor.
///
/// A parent with a DLink can also live in the application's own
/// `std.DoublyLinkedList` — a timeout list, an LRU — one place at a time.
pub const DLink = paternitas.DLink;

/// The dispatch view of a parent: its address and its id.
///
/// For a consumer that keeps a map from id to handler and wants no toolkit
/// calls in its hot path. A view, not an owner: a copy is an alias.
pub const AnyParent = paternitas.AnyParent;

/// Where one parent may be, or may not.
///
/// Empty means the caller has nothing. Full means the caller has that parent.
/// A call that takes the parent leaves the Slot empty, with no line left for
/// the caller to write.
pub const Slot = ?*Anchor;

/// The chain link of a parent: the `next` field of its std Node, holding an
/// Anchor.
///
/// - the next parent's Anchor on the chain
/// - the Anchor itself when it is the last one on a chain
/// - null when the parent is on no chain
///
/// So the link test is exact, and it costs one compare. A chain of one is
/// seen, which a null-or-not test cannot do.
///
/// The border with `std` — MUST:
///
/// - The `next` word is shared with std lists. A parent leaves this toolkit's
///   chains before it goes onto a std list. One item, one chain.
/// - The two chains disagree on the last link: ours points at itself, std's
///   is null. One field cannot hold both conventions at once.
/// - `std` does not clear the link it hands back. An item returning from a
///   std list arrives still pointing into it, and the crossing back refuses
///   it.
///
/// Panics in every build mode on an unstamped parent: without an id there is
/// no description, and so no `next`.
///
/// **The one type pun in the toolkit.** The word is declared by std as
/// `?*SinglyLinkedList.Node` or `?*DoublyLinkedList.Node`. While a parent is
/// on one of our chains, it holds an `*Anchor` instead. Paternitas only says
/// where the word is (`nextField`, typed `*?*anyopaque`); what it holds is
/// decided here. Same size, same alignment, and Zig does no type-based alias
/// analysis today, which this relies on. A debugger shows the word as a
/// "wrong" Node pointer while the parent is on a chain.
pub inline fn next(a: *Anchor) *?*Anchor {
    const ti = a.info() orelse @panic("the parent was never stamped: make it with create, or stamp it once");
    return @ptrCast(ti.nextField(a));
}

/// One parent, as a dispatch view. Leaves the Slot full.
///
/// Null when the Slot is empty.
pub fn anyFromSlot(slot: *const Slot) ?AnyParent {
    const anchor = slot.* orelse return null;
    return anchor.toAny();
}

/// Takes the bare Anchor out of a Slot, for a container of your own.
///
/// The way out of the toolkit — MUST:
///
/// - the parent is stamped
/// - it is unlinked as it crosses
/// - the Slot is cleared
///
/// It answers an `*Anchor`, whatever type the parent is. The way back is
/// `fillSlot`. A copied `*Anchor` is a second owner, as a copied Slot would
/// be.
pub fn takeFromSlot(slot: *Slot) *Anchor {
    const anchor = slot.* orelse @panic("takeFromSlot: the Slot is empty");

    check(anchor.type_id != null, "the parent was never stamped: make it with create, or stamp it once");
    check(!isLinked(anchor), "a parent crosses the border unlinked");

    slot.* = null;
    return anchor;
}

/// Puts a bare Anchor back into an empty Slot.
///
/// The way back in — MUST:
///
/// - the parent is stamped
/// - it is unlinked as it crosses
/// - the Slot is empty
///
/// A std list does not clear the link it hands back, so an item coming
/// straight from one is still pointing into it and is refused here.
pub fn fillSlot(slot: *Slot, anchor: *Anchor) void {
    check(slot.* == null, "never overwrite a full Slot");
    check(anchor.type_id != null, "the parent was never stamped: make it with create, or stamp it once");
    check(!isLinked(anchor), "a parent crosses the border unlinked: a std list leaves its link set");

    slot.* = anchor;
}

/// True when the parent is on a chain.
///
/// Exact. The only item of a chain points at itself, so it reads as linked.
/// An unstamped parent is on no chain: every insert refuses one.
pub inline fn isLinked(a: *Anchor) bool {
    if (a.type_id == null) return false;
    return next(a).* != null;
}

/// Clears the chain link.
///
/// Called for the caller by every removal. Nothing hands back a linked item.
pub inline fn unlink(a: *Anchor) void {
    next(a).* = null;
}

const check = @import("internal/check.zig").check;
const paternitas = @import("paternitas");
