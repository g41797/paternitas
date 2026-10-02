// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! For container authors.
//!
//! The type description behind a `TypeId`, and the layout facts a container
//! needs: where an Anchor's Node `next` word is, where its Parent starts,
//! which Node kind it carries.
//!
//! Application code does not need this namespace. It uses `Info(P)`, the
//! Link types, `*Anchor`, `AnyParent` and `Anchor.toAny()`.
//!
//! Reach it through `Anchor.info()`.

const std = @import("std");
const root = @import("paternitas.zig");
const Anchor = root.Anchor;
const AnyParent = root.AnyParent;
const SLink = root.SLink;
const DLink = root.DLink;

/// Which std Node a Link carries.
pub const NodeKind = enum { single, double };

/// One Parent type's description. One `const` per type, built by `Info`.
///
/// Its address is the `TypeId`, so `name` also keeps descriptors distinct:
/// the compiler may merge identical constants, and two types never share a
/// name. Do not remove `name` to save bytes.
pub const TypeInfo = struct {
    /// `@typeName(Parent)`, for panic and log messages.
    name: []const u8,
    /// From the Parent start to its Anchor.
    anchor_offset: usize,
    /// From the Anchor to the Node's `next` field. Signed: the Node may sit
    /// before the Anchor.
    node_next_offset: isize,
    /// SLink or DLink.
    node_kind: NodeKind,

    /// Address of the Node's `next` field, for either Node kind.
    ///
    /// Location only. Paternitas never reads or writes this word. What goes
    /// in it is the container's decision.
    ///
    /// MUST: the word is shared. A std list writes it while the item is in
    /// that list. A container that chains through it does not use the item
    /// while it is in a std list, and the other way round.
    pub inline fn nextField(ti: *const TypeInfo, a: *Anchor) *?*anyopaque {
        const off: isize = if (uniform_next_offset) |u| u else ti.node_next_offset;
        return @ptrCast(@alignCast(shift(a, off)));
    }

    /// The Parent address, erased.
    pub inline fn parent(ti: *const TypeInfo, a: *Anchor) *anyopaque {
        return shift(a, -@as(isize, @intCast(ti.anchor_offset)));
    }

    /// The dispatch view of the Parent behind this Anchor.
    pub inline fn toAny(ti: *const TypeInfo, a: *Anchor) AnyParent {
        return .{ .ptr = ti.parent(a), .type_id = a.type_id };
    }

    /// The Node, typed.
    ///
    /// Panics in every build mode when `N` is not this type's Node kind. A
    /// wrong kind would read memory as the wrong Node type.
    pub inline fn node(ti: *const TypeInfo, a: *Anchor, comptime N: type) *N {
        const L = comptime linkFor(N);
        if (ti.node_kind != L.kind)
            std.debug.panic("TypeInfo.node: {s} has another Node kind", .{ti.name});
        const l: *L = @fieldParentPtr("anchor", a);
        return &l.node;
    }
};

/// The Node's `next` is at the same distance from the Anchor in both Links.
///
/// `next` is the last word of both std Nodes, and the Anchor follows the
/// Node. When the compiler keeps that order, `nextField` adds a constant and
/// loads nothing. When it does not, this is null and `nextField` reads
/// `node_next_offset`: still correct, one load slower.
pub const uniform_next_offset: ?isize =
    if (SLink.node_next_offset == DLink.node_next_offset) SLink.node_next_offset else null;

fn linkFor(comptime N: type) type {
    if (N == std.SinglyLinkedList.Node) return SLink;
    if (N == std.DoublyLinkedList.Node) return DLink;
    @compileError("paternitas: " ++ @typeName(N) ++ " is not a supported Node type");
}

inline fn shift(a: *Anchor, off: isize) *anyopaque {
    return @ptrFromInt(@intFromPtr(a) +% @as(usize, @bitCast(off)));
}

