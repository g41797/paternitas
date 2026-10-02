// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! paternitas: intrusive, type-erased programming for Zig.
//!
//! A std Node does not say which Parent it lives in. paternitas says.
//!
//! ```zig
//! const Message = struct {
//!     text: []const u8,
//!     link: paternitas.DLink = .{},
//! };
//! const TypedMessage = paternitas.Typed(Message);
//!
//! var message: Message = .{ .text = "hello" };
//! TypedMessage.stamp(&message);
//! list.append(TypedMessage.node(&message));
//!
//! // Null when the Node belongs to another Parent type.
//! const m: ?*Message = TypedMessage.parentFromNode(list.popFirst().?);
//! ```
//!
//! - `Link` pairs a std Node with an `Anchor`. A Parent embeds one.
//! - `Anchor` is one stamped word. Its address is the erased reference.
//! - `Typed(P)` is the typed helper, built at comptime.
//! - `AnyParent` is the dispatch view: the Parent address and its TypeId.
//! - `container.TypeInfo` describes one Parent type. Its address is the
//!   `TypeId`. For container authors only.
//!
//! Mechanism, not policy.
//!
//! - paternitas says where things are, and what type they belong to.
//! - Containers built on top decide who frees a Parent.
//! - They also decide chain conventions and allocation.

const _doc_stub = void;

/// A Parent type's identity: the address of its `TypeInfo`.
///
/// - Null is the id of an Anchor that was never stamped. It matches no Parent.
/// - Zeroed memory is a valid unstamped Anchor.
/// - Valid inside one running binary only. Not persistent, not serialized.
pub const TypeId = ?*const anyopaque;

/// One stamped word inside every Parent, in its Link.
///
/// The Anchor is not the Parent. It is a small marker inside it.
///
/// - `*Anchor` is the erased reference to the Parent.
/// - The address says where the Parent is.
/// - The stamped value says what it is.
pub const Anchor = struct {
    /// Written by `Typed(P).stamp` only. Read it through `typeId()`.
    ///
    /// Zig has no private fields. A hand-written value passes every id check.
    _type_id: TypeId = null,

    /// The stamped id. Null when unstamped.
    pub inline fn typeId(a: *const Anchor) TypeId {
        return a.*._type_id;
    }

    /// The type name behind this Anchor, or `<unstamped>`. For panic and log
    /// text.
    pub fn typeName(a: *const Anchor) []const u8 {
        return if (a.info()) |i| i.*.name else "<unstamped>";
    }

    /// This Parent type's description. Null when unstamped.
    ///
    /// For container authors. Application code does not need it.
    pub inline fn info(a: *const Anchor) ?*const TypeInfo {
        const id: *const anyopaque = a.typeId() orelse return null;
        return @ptrCast(@alignCast(id));
    }

    /// The dispatch view of the Parent behind this Anchor, without knowing
    /// its type. Null when unstamped.
    pub inline fn toAny(a: *Anchor) ?AnyParent {
        const ti: *const TypeInfo = a.info() orelse return null;
        return ti.toAny(a);
    }
};

/// The dispatch view of a Parent: where it is and what it is.
///
/// - One way. No call turns it back into an Anchor.
/// - Built by `toAny` only.
///   - Both forms take a mutable pointer. So `ptr` is mutable memory.
///   - The fields are `pub`. A hand-built one passes every id check.
/// - A view, not a copy. The Parent outlives every copy of it.
pub const AnyParent = struct {
    /// The Parent.
    ptr: *anyopaque,
    /// The Parent's TypeId.
    type_id: TypeId,
};

/// A std Node and an Anchor, as one type.
///
/// - One type means one layout. The Node-to-Anchor distance is the same in
///   every Parent.
/// - So a check reads the Anchor before it knows the Parent type.
/// - `N` is `std.SinglyLinkedList.Node` or `std.DoublyLinkedList.Node`. Any
///   other `N` is a compile error.
pub fn Link(comptime N: type) type {
    const node_kind: NodeKind = comptime kindOf(N);

    return struct {
        /// The std Node. A std list links it.
        node: N = .{},
        /// The stamped word. `Typed(P).stamp` writes it.
        anchor: Anchor = .{},

        /// The Node type, `N`.
        pub const Node: type = N;
        /// `.single` or `.double`.
        pub const kind: NodeKind = node_kind;
        /// From the Anchor to the Node's `next` field.
        pub const node_next_offset: isize =
            @as(isize, @offsetOf(@This(), "node") + @offsetOf(N, "next")) -
            @as(isize, @offsetOf(@This(), "anchor"));
    };
}

/// The Link of a `std.SinglyLinkedList.Node`.
pub const SLink = Link(std.SinglyLinkedList.Node);
/// The Link of a `std.DoublyLinkedList.Node`.
pub const DLink = Link(std.DoublyLinkedList.Node);

fn kindOf(comptime N: type) NodeKind {
    if (N == std.SinglyLinkedList.Node) return .single;
    if (N == std.DoublyLinkedList.Node) return .double;
    @compileError("Link(" ++ @typeName(N) ++ "): not a std Node, so it cannot be a Paternitas Link");
}

/// Panics where runtime safety is on. Compiled out elsewhere, so a broken
/// contract is never an assumption the optimizer may act on.
inline fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}

fn findLink(comptime P: type) []const u8 {
    comptime {
        const ti: std.builtin.Type = @typeInfo(P);
        if (ti != .@"struct")
            @compileError(@typeName(P) ++ ": not a struct, so it cannot be a Paternitas Parent");
        var found: ?[]const u8 = null;
        for (ti.@"struct".fields) |f| {
            if (f.type == SLink or f.type == DLink) {
                if (found != null)
                    @compileError(@typeName(P) ++ ": more than one Link, and exactly one is allowed");
                found = f.name;
            }
        }
        return found orelse
            @compileError(@typeName(P) ++ ": no Link, so it cannot be a Paternitas Parent");
    }
}

/// The typed helper for one Parent type.
///
/// `P` is a struct with exactly one `SLink` or `DLink` field, any name, any
/// position. Zero, two, or a non-struct is a compile error naming the type.
pub fn Typed(comptime P: type) type {
    const field: []const u8 = comptime findLink(P);
    const L: type = @FieldType(P, field);

    return struct {
        /// The Node type of `P`'s Link.
        pub const Node: type = L.Node;

        // Never read or written. Its address keeps `desc` unique. A `const`
        // tag would be merged with the tag of every other `Typed`.
        var tag: u8 = 0;

        const desc: TypeInfo = .{
            ._tag = &tag,
            .name = @typeName(P),
            .anchor_offset = @offsetOf(P, field) + @offsetOf(L, "anchor"),
            .node_next_offset = L.node_next_offset,
            .node_kind = L.kind,
        };

        /// This type's id.
        pub inline fn typeId() TypeId {
            return &desc;
        }

        /// True when the id is this type's.
        pub inline fn isId(id: TypeId) bool {
            return id == typeId();
        }

        /// Writes this type's id into the Anchor. Writes nothing else.
        ///
        /// - It does not touch the Node. A Parent already in a list may be
        ///   stamped.
        /// - `allocator.create` returns undefined memory. Initialize the
        ///   Parent before stamping it.
        pub inline fn stamp(p: *P) void {
            @field(p.*, field).anchor._type_id = typeId();
        }

        /// The Anchor inside `p`.
        pub inline fn anchor(p: *P) *Anchor {
            return &@field(p.*, field).anchor;
        }

        /// The Node inside `p`.
        pub inline fn node(p: *P) *Node {
            return &@field(p.*, field).node;
        }

        inline fn linkOf(n: *Node) *L {
            return @fieldParentPtr("node", n);
        }

        /// True when the Node's Anchor is stamped as `P`.
        ///
        /// MUST: the Node lives in a paternitas Link.
        pub inline fn is(n: *const Node) bool {
            const l: *const L = @fieldParentPtr("node", n);
            return isId(l.*.anchor.typeId());
        }

        /// The Parent, from its Anchor. Null when the Anchor is another type
        /// or unstamped.
        pub inline fn fromAnchor(a: *Anchor) ?*P {
            if (!isId(a.typeId())) return null;
            const l: *L = @fieldParentPtr("anchor", a);
            return @fieldParentPtr(field, l);
        }

        /// The Parent, from its Anchor. Panics in every build mode on another
        /// type, naming both.
        pub inline fn mustFromAnchor(a: *Anchor) *P {
            return fromAnchor(a) orelse wrongType("mustFromAnchor", a);
        }

        /// The dispatch view of `p`.
        pub inline fn toAny(p: *P) AnyParent {
            return .{ .ptr = p, .type_id = typeId() };
        }

        /// The Parent, from a dispatch view. Null when it is another type.
        pub inline fn fromAny(any: AnyParent) ?*P {
            if (!isId(any.type_id)) return null;
            const p: *P = @ptrCast(@alignCast(any.ptr));
            check(isId(anchor(p).typeId()), "fromAny: the Parent was never stamped");
            return p;
        }

        /// The Parent, from its Node. Null when the Node's Anchor is another
        /// type or unstamped.
        ///
        /// MUST: the Node lives in a paternitas Link.
        pub inline fn parentFromNode(n: *Node) ?*P {
            if (!is(n)) return null;
            return parentFromNodeUnchecked(n);
        }

        /// The Parent, from its Node. Panics in every build mode on another
        /// type, naming both.
        ///
        /// MUST: the Node lives in a paternitas Link.
        pub inline fn mustParentFromNode(n: *Node) *P {
            return parentFromNode(n) orelse wrongType("mustParentFromNode", &linkOf(n).*.anchor);
        }

        /// The Parent, from its Node, without the check. The caller knows
        /// the type.
        ///
        /// MUST: the Node lives in a `P`.
        pub inline fn parentFromNodeUnchecked(n: *Node) *P {
            return @fieldParentPtr(field, linkOf(n));
        }

        fn wrongType(comptime call: []const u8, found: *const Anchor) noreturn {
            std.debug.panic(call ++ ": asked for {s}, found {s}", .{ @typeName(P), found.typeName() });
        }
    };
}

/// For container authors: the type description and the layout facts a
/// container needs. Application code does not need it.
pub const container = @import("container.zig");
const TypeInfo = container.TypeInfo;
const NodeKind = container.NodeKind;
const std = @import("std");
