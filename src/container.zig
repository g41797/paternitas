// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! For you, if you write your own container: a queue, a stack, a pool.
//!
//! Your container keeps `*Anchor`s of many Parent types.
//!
//! You do not need to know their types.
//!
//! For any of them, this part gives you three things:
//!
//! - A pointer-sized word to chain through. Your container needs no extra
//!   memory per item.
//! - The std Node, as its own type.
//! - The Parent's address.
//!
//! Start from `anchor.info()`.
//!
//! It gives you the `TypeInfo` of that Parent.
//!
//! Application code does not need this part.
//!
//! `Typed(P)` covers it.

const _doc_stub = void;

/// What Paternitas knows about one Parent type.
///
/// Get it with `anchor.info()`.
///
/// - There is one per Parent type, and it lives as long as the program.
/// - Paternitas makes it. You do not make one.
pub const TypeInfo = struct {
    /// Do not use.
    _tag: *const u8,
    /// The Parent's type name.
    ///
    /// Use it in logs and panic messages.
    name: []const u8,
    /// The distance from the start of the Parent to its Anchor.
    anchor_offset: usize,
    /// The distance from the Anchor to the Node's `next` field.
    ///
    /// It can be negative.
    node_next_offset: isize,
    /// `.single` for `SinglyTypedNode`, `.double` for `DoublyTypedNode`.
    node_kind: NodeKind,

    /// Returns a pointer to the Node's `next` field.
    ///
    /// Chain your items through it.
    ///
    /// - It works for both Node kinds.
    /// - Paternitas never reads or writes this word. What you put in it is
    ///   up to your container.
    /// - A std list uses the same word. A Parent MUST NOT be in your
    ///   container and in a std list at the same time.
    ///
    /// ```zig
    /// info.nextField(anchor).* = next_anchor;
    /// ```
    pub inline fn nextField(ti: *const TypeInfo, a: *Anchor) *?*anyopaque {
        const off: isize = if (uniform_next_offset) |u| u else ti.*.node_next_offset;
        return _nextFieldAt(a, off);
    }

    /// Returns the std Node of the Parent, as type `N`.
    ///
    /// It panics in every build mode when `N` is the wrong Node type for this
    /// Parent.
    ///
    /// ```zig
    /// const n: *std.DoublyLinkedList.Node = info.node(anchor, std.DoublyLinkedList.Node);
    /// ```
    pub inline fn node(ti: *const TypeInfo, a: *Anchor, comptime N: type) *N {
        const TN: type = TypedNode(N);
        if (ti.*.node_kind != TN.kind)
            std.debug.panic("TypeInfo.node: {s} has another Node kind", .{ti.*.name});
        const tn: *TN = @fieldParentPtr("anchor", a);
        return &tn.*.node;
    }

    /// Returns the Parent's address, with no type.
    ///
    /// Give it to code that knows nothing of Paternitas, such as a C callback's
    /// `void*`.
    pub inline fn parent(ti: *const TypeInfo, a: *Anchor) *anyopaque {
        return addOffset(a, -@as(isize, @intCast(ti.*.anchor_offset)));
    }

    /// Returns an `AnyParent` for the Parent: its address and its type id.
    pub inline fn toAny(ti: *const TypeInfo, a: *Anchor) AnyParent {
        return .{ .ptr = ti.parent(a), .type_id = a.typeId() };
    }
};

/// Not null when the `next` field sits at the same distance from the Anchor
/// in every Parent.
///
/// You do not need it to use `nextField`.
pub const uniform_next_offset: ?isize =
    if (SinglyTypedNode.node_next_offset == DoublyTypedNode.node_next_offset) SinglyTypedNode.node_next_offset else null;

/// Which std Node a Parent has: `.single` for `SinglyTypedNode`, `.double`
/// for `DoublyTypedNode`.
pub const NodeKind = enum { single, double };

/// Do not use.
///
/// It is `pub` only for a test.
///
/// Call `nextField` instead.
pub inline fn _nextFieldAt(a: *Anchor, off: isize) *?*anyopaque {
    return @ptrCast(@alignCast(addOffset(a, off)));
}

inline fn addOffset(a: *Anchor, off: isize) *anyopaque {
    return @ptrFromInt(@intFromPtr(a) +% @as(usize, @bitCast(off)));
}

const root = @import("paternitas.zig");
const Anchor = root.Anchor;
const AnyParent = root.AnyParent;
const TypedNode = root.TypedNode;
const SinglyTypedNode = root.SinglyTypedNode;
const DoublyTypedNode = root.DoublyTypedNode;
const std = @import("std");
