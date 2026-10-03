// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! For Zig std linked lists that keep more than one struct type.
//!
//! Zig's std lists are intrusive and type-erased.
//!
//! - Intrusive: the Node lives in your struct. The list copies nothing and
//!   allocates nothing.
//! - Type-erased: the list sees only Nodes, never your struct's type.
//!
//! Paternitas keeps both, and lets you check the type again.
//!
//! The problem:
//!
//! - You keep Messages and Jobs in one `std.DoublyLinkedList`. You pop a
//!   Node. Is it in a Message or in a Job? The list does not know.
//! - `@fieldParentPtr` returns whatever type you ask for. Ask for a Job when
//!   it is a Message, and you read a Message as a Job. It compiles, it runs,
//!   and nothing warns you.
//!
//! The fix: put a TypedNode where the Node was. It is the same std Node,
//! with the struct's type kept next to it.
//!
//! ```
//! before                       after
//! Message                      Message
//! +--------------------+       +---------------------------+
//! | text               |       | text                      |
//! | node  <-- the list |       | tnode: DoublyTypedNode    |
//! +--------------------+       | +-----------------------+ |
//!                              | | node   <-- the list   | |
//!                              | | internal info...      | |
//!                              | +-----------------------+ |
//!                              +---------------------------+
//! ```
//!
//! Before:
//!
//! ```zig
//! const Message = struct {
//!     text: []const u8,
//!     node: std.DoublyLinkedList.Node = .{},
//! };
//!
//! var message: Message = .{ .text = "hello" };
//! list.append(&message.node);
//!
//! const m: *Message = @fieldParentPtr("node", list.popFirst().?);
//! ```
//!
//! After:
//!
//! ```zig
//! const Message = struct {
//!     text: []const u8,
//!     tnode: paternitas.DoublyTypedNode = .{},
//! };
//! const TypedMessage = paternitas.Typed(Message); // does the @fieldParentPtr work
//!
//! var message: Message = .{ .text = "hello" };
//! TypedMessage.setTypeId(&message);
//! list.append(TypedMessage.node(&message));
//!
//! const m: *Message = TypedMessage.mustParentFromNode(list.popFirst().?);
//! ```
//!
//! Job gets the same change: its `std.DoublyLinkedList.Node` becomes a
//! `paternitas.DoublyTypedNode`, and it gets its own
//! `const TypedJob = paternitas.Typed(Job);`.
//!
//! Do it this way, for each struct in the list:
//!
//! 1. `std.SinglyLinkedList.Node` becomes `paternitas.SinglyTypedNode`.
//!    `std.DoublyLinkedList.Node` becomes `paternitas.DoublyTypedNode`.
//! 2. Add `const TypedMessage = paternitas.Typed(Message);`, once.
//! 3. Call `TypedMessage.setTypeId(&message)` once, after the struct is set
//!    up and before it goes in a list.
//! 4. `&message.node` becomes `TypedMessage.node(&message)`.
//! 5. `@fieldParentPtr("node", n)` becomes `TypedMessage.mustParentFromNode(n)`.
//!    It still returns `*Message`. A wrong type panics, in every build mode.
//!
//! The list itself does not change. The compiler stops at each place you
//! missed in steps 4 and 5.
//!
//! Then, where a Node of another type is expected, use `parentFromNode`.
//! It returns null for another type.
//!
//! Outside a std list, pass an `AnyParent`: the struct's address and its
//! type id. A queue, a map or a union field copies the two words, never
//! your struct.
//!
//! - Get it with `toAny`, and the struct back with `fromAny`.
//! - Or look up a handler by its `type_id`, and give it `ptr`.
//!
//! Writing your own container? See `Anchor` and `container`.
//!
//! Paternitas has no list or queue of its own, and it allocates nothing.

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
/// - You do not call `TypedNode` yourself.
/// - A Parent has exactly one.
/// - It contains the std Node, and the place where `setTypeId` writes the
///   type.
/// - Any `N` other than the two std Node types is a compile error.
pub fn TypedNode(comptime N: type) type {
    const node_kind: NodeKind = comptime kindOf(N);

    return struct {
        /// The std Node that the list links.
        node: N = .{},
        /// The part of your struct that any code can point to. `setTypeId`
        /// writes the struct's type into it. See `Anchor`.
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

/// Does the `@fieldParentPtr` work for `P`, and checks the type.
///
/// - You never write `@fieldParentPtr` or the field's name. It finds the
///   TypedNode by its type.
/// - You get your struct back only when the type matches. Otherwise you get
///   null, or a panic from the `must` calls.
///
/// Declare it once per type: `const TypedMessage = paternitas.Typed(Message);`
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
        /// - Without it, `parentFromNode`, `parentFromAnchor` and `fromAny` return
        ///   null for `p`.
        /// - Set up `p` first. `allocator.create` gives you undefined memory.
        /// - It changes nothing else in `p`. A Parent already in a list stays
        ///   there.
        ///
        /// ```zig
        /// var message: Message = .{ .text = "hello" };
        /// TypedMessage.setTypeId(&message);
        /// list.append(TypedMessage.node(&message));
        /// ```
        pub inline fn setTypeId(p: *P) void {
            @field(p.*, field).anchor._type_id = typeId();
        }

        /// Returns the Node of `p`. Give it to the std list.
        ///
        /// ```zig
        /// list.append(TypedMessage.node(&message));
        /// ```
        pub inline fn node(p: *P) *Node {
            return &@field(p.*, field).node;
        }

        /// Returns the `P` that contains the Node. Returns null when it is
        /// another type, or when `setTypeId` was never called.
        ///
        /// The Node MUST be inside a `SinglyTypedNode` or `DoublyTypedNode`.
        ///
        /// ```zig
        /// if (TypedMessage.parentFromNode(node)) |message| {
        ///     // use message
        /// }
        /// ```
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
        ///
        /// ```zig
        /// if (TypedMessage.parentFromAnchor(anchor)) |message| {
        ///     // use message
        /// }
        /// ```
        pub inline fn parentFromAnchor(a: *Anchor) ?*P {
            if (!isId(a.typeId())) return null;
            const tn: *TN = @fieldParentPtr("anchor", a);
            return @fieldParentPtr(field, tn);
        }

        /// Like `parentFromAnchor`, but panics instead of returning null. It panics
        /// in every build mode.
        pub inline fn mustParentFromAnchor(a: *Anchor) *P {
            return parentFromAnchor(a) orelse wrongType("mustParentFromAnchor", a);
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

/// The one fixed point in your struct. Everything else is reached from it:
/// the struct's type, the struct itself, its Node.
///
/// *Da ubi consistam, et terram movebo.* Give me a place to stand, and I
/// will move the Earth. (Archimedes)
///
/// For container authors. Application code passes an `AnyParent`, two words.
/// `*Anchor` is one word: use it in your own container, or as a C callback's
/// `void*` context.
///
/// - Every struct with a TypedNode has one Anchor, inside the TypedNode.
///   `setTypeId` writes the struct's type into it.
/// - Get it with `TypedMessage.anchor(&message)`.
/// - Get the struct back with `TypedMessage.parentFromAnchor(a)`. You get
///   null for another type.
/// - You never make an Anchor. You only pass `*Anchor`.
///
/// `*Node` carries any struct with the same Node kind. `*Anchor` carries
/// any struct. Both turn back into your struct with a type check.
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

/// A Parent's address and its type id, together. Pass it where the code in
/// between does not know your struct's type: a queue, a map, a union field.
/// They copy the two words, never your struct.
///
/// - Look up a handler by `type_id`, and give it `ptr`. The handler is
///   chosen without reading the struct.
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
/// - Use it as a map key, when Parents of several types share a map or a
///   dispatch table.
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
inline fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}

const TypeInfo = container.TypeInfo;
const NodeKind = container.NodeKind;
const std = @import("std");
