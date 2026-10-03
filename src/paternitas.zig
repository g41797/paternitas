// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Get your struct back from a std list Node, with a type check.
//!
//! `@fieldParentPtr` returns whatever type you ask for. When one list has
//! two struct types, it can give you the wrong one, and nothing warns you.
//! paternitas checks the type first.
//!
//! ```zig
//! const Message = struct {
//!     text: []const u8,
//!     tnode: paternitas.DoublyTypedNode = .{}, // where the std Node was
//! };
//! const TypedMessage = paternitas.Typed(Message);
//!
//! var message: Message = .{ .text = "hello" };
//! TypedMessage.setTypeId(&message);
//! list.append(TypedMessage.node(&message));
//!
//! // null when the Node is in a struct of another type
//! const m: ?*Message = TypedMessage.parentFromNode(list.popFirst().?);
//! ```
//!
//! How to use it:
//!
//! - Put a `SinglyTypedNode` or a `DoublyTypedNode` in your struct, where
//!   the std Node was. paternitas calls that struct the Parent.
//! - Declare `Typed` once per struct type.
//! - Call `setTypeId` once on each struct, before it goes in a list. It
//!   writes the struct's type into its TypedNode.
//! - Give `node` to the std list.
//! - Get the struct back with `parentFromNode`. You get null when the Node
//!   is in a struct of another type.
//!
//! When the type is not known yet, as in a queue that carries several struct
//! types:
//!
//! - Pass the `*Anchor` that `anchor` gives you. Every Parent has one.
//! - Get the struct back with `fromAnchor`. You get null for another type.
//!
//! paternitas has no list or queue of its own, and it allocates nothing.

const _doc_stub = void;

/// The TypedNode for a `std.SinglyLinkedList`.
pub const SinglyTypedNode = TypedNode(std.SinglyLinkedList.Node);
/// Short for `SinglyTypedNode`.
pub const STNode = SinglyTypedNode;
/// The TypedNode for a `std.DoublyLinkedList`.
pub const DoublyTypedNode = TypedNode(std.DoublyLinkedList.Node);
/// Short for `DoublyTypedNode`.
pub const DTNode = DoublyTypedNode;

/// The std Node with a type check added. It is the field you put in your
/// struct, where the std Node was. Use `SinglyTypedNode` or
/// `DoublyTypedNode`.
///
/// - A Parent has exactly one.
/// - It contains the std Node, and the place where `setTypeId` writes the
///   type.
/// - Any `N` other than the two std Node types is a compile error.
pub fn TypedNode(comptime N: type) type {
    const node_kind: NodeKind = comptime kindOf(N);

    return struct {
        /// The std Node that the list links.
        node: N = .{},
        /// Where `setTypeId` writes the type.
        anchor: Anchor = .{},

        /// The std Node type.
        pub const Node: type = N;
        /// `.single` for `SinglyTypedNode`, `.double` for `DoublyTypedNode`.
        pub const kind: NodeKind = node_kind;
        /// For container authors: where the Node's `next` field is, counted
        /// from the Anchor.
        pub const node_next_offset: isize =
            @as(isize, @offsetOf(@This(), "node") + @offsetOf(N, "next")) -
            @as(isize, @offsetOf(@This(), "anchor"));
    };
}

/// The calls for one Parent type `P`. Declare it once per type:
/// `const TypedMessage = paternitas.Typed(Message);`
///
/// - `P` MUST be a struct with exactly one `SinglyTypedNode` or
///   `DoublyTypedNode` field, under any name.
/// - Anything else is a compile error that names the type.
pub fn Typed(comptime P: type) type {
    const field: []const u8 = comptime findTypedNode(P);
    const TN: type = @FieldType(P, field);

    return struct {
        /// Writes the type of `p` into its TypedNode. Call it once, before
        /// `p` goes in a list or a queue.
        ///
        /// - Without it, `parentFromNode`, `fromAnchor` and `fromAny` return
        ///   null for `p`.
        /// - Set up `p` first. `allocator.create` gives you undefined memory.
        /// - It changes nothing else in `p`. A Parent already in a list stays
        ///   there.
        pub inline fn setTypeId(p: *P) void {
            @field(p.*, field).anchor._type_id = typeId();
        }

        /// Returns the Node of `p`. Give it to the std list.
        pub inline fn node(p: *P) *Node {
            return &@field(p.*, field).node;
        }

        /// Returns the `P` that contains the Node. Returns null when it is
        /// another type, or when `setTypeId` was never called.
        ///
        /// The Node MUST be inside a `SinglyTypedNode` or `DoublyTypedNode`.
        pub inline fn parentFromNode(n: *Node) ?*P {
            if (!is(n)) return null;
            return parentFromNodeUnchecked(n);
        }

        /// Like `parentFromNode`, but panics instead of returning null. It
        /// panics in every build mode.
        ///
        /// The Node MUST be inside a `SinglyTypedNode` or `DoublyTypedNode`.
        pub inline fn mustParentFromNode(n: *Node) *P {
            return parentFromNode(n) orelse wrongType("mustParentFromNode", &typedNodeOf(n).*.anchor);
        }

        /// Returns the `P` that contains the Node, with no type check.
        ///
        /// The Node MUST be inside a `P`. Anything else gives you garbage.
        pub inline fn parentFromNodeUnchecked(n: *Node) *P {
            return @fieldParentPtr(field, typedNodeOf(n));
        }

        /// Returns true when the Node is inside a `P`.
        ///
        /// The Node MUST be inside a `SinglyTypedNode` or `DoublyTypedNode`.
        pub inline fn is(n: *const Node) bool {
            const tn: *const TN = @fieldParentPtr("node", n);
            return isId(tn.*.anchor.typeId());
        }

        /// Returns the `*Anchor` of `p`. Pass it where the type is not known
        /// yet.
        pub inline fn anchor(p: *P) *Anchor {
            return &@field(p.*, field).anchor;
        }

        /// Returns the `P` behind the `*Anchor`. Returns null when it is
        /// another type, or when `setTypeId` was never called.
        pub inline fn fromAnchor(a: *Anchor) ?*P {
            if (!isId(a.typeId())) return null;
            const tn: *TN = @fieldParentPtr("anchor", a);
            return @fieldParentPtr(field, tn);
        }

        /// Like `fromAnchor`, but panics instead of returning null. It panics
        /// in every build mode.
        pub inline fn mustFromAnchor(a: *Anchor) *P {
            return fromAnchor(a) orelse wrongType("mustFromAnchor", a);
        }

        /// Returns the address and type id of `p`, to pick a handler by type.
        pub inline fn toAny(p: *P) AnyParent {
            return .{ .ptr = p, .type_id = typeId() };
        }

        /// Returns the `P` behind an `AnyParent`, or null for another type.
        pub inline fn fromAny(any: AnyParent) ?*P {
            if (!isId(any.type_id)) return null;
            const p: *P = @ptrCast(@alignCast(any.ptr));
            check(isId(anchor(p).typeId()), "fromAny: setTypeId was never called on the Parent");
            return p;
        }

        /// Returns the type id of `P`.
        pub inline fn typeId() TypeId {
            return &desc;
        }

        /// Returns true when `id` is the type id of `P`.
        pub inline fn isId(id: TypeId) bool {
            return id == typeId();
        }

        /// The std Node type of `P`.
        pub const Node: type = TN.Node;

        // Nothing reads or writes this. Its address keeps `desc` unique.
        // A `const` tag would merge with the tag of every other `Typed`.
        var tag: u8 = 0;

        const desc: TypeInfo = .{
            ._tag = &tag,
            .name = @typeName(P),
            .anchor_offset = @offsetOf(P, field) + @offsetOf(TN, "anchor"),
            .node_next_offset = TN.node_next_offset,
            .node_kind = TN.kind,
        };

        inline fn typedNodeOf(n: *Node) *TN {
            return @fieldParentPtr("node", n);
        }

        fn wrongType(comptime call: []const u8, found: *const Anchor) noreturn {
            std.debug.panic(call ++ ": asked for {s}, found {s}", .{ @typeName(P), found.typeName() });
        }
    };
}

/// A pointer to a Parent whose type is checked when you get it back.
///
/// Every Parent has one, inside its `SinglyTypedNode` or
/// `DoublyTypedNode`. Get it with `Typed(P).anchor(&p)`.
///
/// - Pass `*Anchor` through a queue, a map or a union field that carries
///   several struct types.
/// - Get the Parent back with `Typed(P).fromAnchor`. You get null for
///   another type.
pub const Anchor = struct {
    /// Do not write this field. `Typed(P).setTypeId` writes it. A value you
    /// write yourself passes every type check.
    _type_id: TypeId = null,

    /// Returns the Parent's type name, or `<no type>` when `setTypeId` was
    /// never called on it. For logs and panic messages.
    pub fn typeName(a: *const Anchor) []const u8 {
        return if (a.info()) |i| i.*.name else "<no type>";
    }

    /// Returns the Parent's address and type id, to pick a handler by type.
    /// Returns null when `setTypeId` was never called on the Parent.
    pub inline fn toAny(a: *Anchor) ?AnyParent {
        const ti: *const TypeInfo = a.info() orelse return null;
        return ti.toAny(a);
    }

    /// Returns the Parent's type id, or null when `setTypeId` was never called
    /// on it.
    pub inline fn typeId(a: *const Anchor) TypeId {
        return a.*._type_id;
    }

    /// For container authors. Returns the type's layout facts, or null when
    /// `setTypeId` was never called on the Parent.
    pub inline fn info(a: *const Anchor) ?*const TypeInfo {
        const id: *const anyopaque = a.typeId() orelse return null;
        return @ptrCast(@alignCast(id));
    }
};

/// A Parent's address and its type id, together. Use it to pick a handler by
/// type.
///
/// - Look up the handler by `type_id`, and give it `ptr`.
/// - Or get the typed pointer back with `Typed(P).fromAny`. You get null for
///   another type.
/// - It does not copy the Parent. The Parent MUST stay alive while you use
///   this.
/// - Get one only from `toAny`. One you fill in yourself passes every type
///   check.
pub const AnyParent = struct {
    /// The Parent's address.
    ptr: *anyopaque,
    /// The Parent's type id.
    type_id: TypeId,
};

/// An id for a struct type. Each Parent type gets its own.
///
/// - Use it as a map key, to find the handler for a type.
/// - Null means no type: `setTypeId` was never called on that struct.
/// - It is valid only while the program runs. Do not save it or send it.
/// - A shared library gets a different id for the same type.
pub const TypeId = ?*const anyopaque;

/// For people who write their own containers. Application code does not
/// need it.
pub const container = @import("container.zig");

fn kindOf(comptime N: type) NodeKind {
    if (N == std.SinglyLinkedList.Node) return .single;
    if (N == std.DoublyLinkedList.Node) return .double;
    @compileError("TypedNode(" ++ @typeName(N) ++ "): not a std Node, so it cannot be a Paternitas TypedNode");
}

fn findTypedNode(comptime P: type) []const u8 {
    comptime {
        const ti: std.builtin.Type = @typeInfo(P);
        if (ti != .@"struct")
            @compileError(@typeName(P) ++ ": not a struct, so it cannot be a Paternitas Parent");
        var found: ?[]const u8 = null;
        for (ti.@"struct".fields) |f| {
            if (f.type == SinglyTypedNode or f.type == DoublyTypedNode) {
                if (found != null)
                    @compileError(@typeName(P) ++ ": more than one TypedNode, and exactly one is allowed");
                found = f.name;
            }
        }
        return found orelse
            @compileError(@typeName(P) ++ ": no TypedNode, so it cannot be a Paternitas Parent");
    }
}

/// Panics when runtime safety is on, and compiles to nothing otherwise.
/// That way the optimizer never treats a broken contract as an assumption.
inline fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}

const TypeInfo = container.TypeInfo;
const NodeKind = container.NodeKind;
const std = @import("std");
