// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! For Zig std linked lists that keep more than one struct type.
//!
//! Zig's std lists are intrusive and type-erased.
//!
//! - Intrusive: the Node lives in your struct.
//!   - The list copies nothing.
//!   - The list allocates nothing.
//! - Type-erased: the list sees only Nodes, never your struct's type.
//!   - Code built on the list does not change when you add a struct type.
//!
//! Paternitas keeps both.
//!
//! It adds a type check.
//!
//! Say you keep Messages and Jobs in one `std.DoublyLinkedList`.
//!
//! - You pop a Node.
//! - Is it in a Message or in a Job? The list does not know.
//! - `@fieldParentPtr` gives you whatever type you ask for.
//! - Ask for a Job when it is a Message. You read a Message as a Job.
//! - It compiles. It runs. Nothing warns you.
//!
//! With Paternitas, a wrong type gives null.
//!
//! - The `must` calls panic instead.
//! - The panic names both types.
//! - This works in every build mode.
//!
//! You put a TypedNode where the Node was.
//!
//! - The change is mechanical.
//! - You find and replace, five times.
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
//! `Job` gets the same change.
//!
//! - Its `std.DoublyLinkedList.Node` becomes a `paternitas.DoublyTypedNode`.
//! - It gets its own `const TypedJob = paternitas.Typed(Job);`.
//!
//! Do it for each struct in the list:
//!
//! 1. Change the Node.
//!    - `std.SinglyLinkedList.Node` becomes `paternitas.SinglyTypedNode`.
//!    - `std.DoublyLinkedList.Node` becomes `paternitas.DoublyTypedNode`.
//! 2. Add `const TypedMessage = paternitas.Typed(Message);`, once.
//! 3. Call `TypedMessage.setTypeId(&message)`.
//!    - Call it right after the struct is created.
//!    - Call it again after each whole-struct write, such as a reset.
//! 4. `&message.node` becomes `TypedMessage.node(&message)`.
//! 5. `@fieldParentPtr("node", n)` becomes `TypedMessage.mustParentFromNode(n)`.
//!    - It still returns `*Message`.
//!    - A wrong type panics, in every build mode.
//!
//! The list itself does not change.
//!
//! The compiler stops at each place you missed in steps 4 and 5.
//!
//! Where a Node can be in another type, use `parentFromNode`.
//!
//! It returns null for another type.
//!
//! Outside a std list, pass an `AnyParent`.
//!
//! - It holds the struct's address and its type id.
//! - A queue, a map or a union field copies these two words. It never copies
//!   your struct.
//! - Get one with `toAny`. Get the struct back with `fromAny`.
//! - Or look up a handler by its `type_id`, and give it `ptr`.
//!
//! Writing your own container?
//!
//! See `Anchor` and `container`.
//!
//! Paternitas is not a container library.
//!
//! - It has no list or queue of its own.
//! - It allocates nothing. It frees nothing.
//! - It locks nothing. Guard shared lists yourself.
//! - It checks the type. It does not check that the struct is still alive.
//!
//! A type id has limits.
//!
//! - It is valid only inside one running program. Do not save it or send it.
//! - A shared library has its own type ids, even for the same struct type.
//!   - A struct marked by `setTypeId` in the library fails the type check
//!     in the program.
//!   - The same holds the other way round.

const _doc_stub = void;

/// The TypedNode for a `std.SinglyLinkedList`.
pub const SinglyTypedNode = TypedNode(std.SinglyLinkedList.Node);
/// Short for `SinglyTypedNode`.
pub const STNode = SinglyTypedNode;
/// The TypedNode for a `std.DoublyLinkedList`.
pub const DoublyTypedNode = TypedNode(std.DoublyLinkedList.Node);
/// Short for `DoublyTypedNode`.
pub const DTNode = DoublyTypedNode;

/// The std Node with a type check added.
///
/// - It is the field you put in your struct, where the std Node was.
/// - Use `SinglyTypedNode` or `DoublyTypedNode`.
/// - You do not call `TypedNode` yourself.
/// - A Parent has exactly one.
/// - It holds the std Node and the struct's type id.
/// - Any `N` other than the two std Node types is a compile error.
pub fn TypedNode(comptime N: type) type {
    const node_kind: NodeKind = comptime kindOf(N);

    return struct {
        /// The std Node that the list links.
        node: N = .{},
        /// The part of your struct that any code can point to.
        ///
        /// `setTypeId` writes the struct's type id into it.
        ///
        /// See `Anchor`.
        anchor: Anchor = .{},

        /// The std Node type.
        pub const Node: type = N;
        /// `.single` for `SinglyTypedNode`, `.double` for `DoublyTypedNode`.
        pub const kind: NodeKind = node_kind;
        /// For container authors.
        ///
        /// It is the distance from the Anchor to the Node's `next` field.
        pub const node_next_offset: isize =
            @as(isize, @offsetOf(@This(), "node") + @offsetOf(N, "next")) -
            @as(isize, @offsetOf(@This(), "anchor"));
    };
}

/// Does the `@fieldParentPtr` work for `P`.
///
/// It also checks the type.
///
/// Declare it once per type: `const TypedMessage = paternitas.Typed(Message);`
///
/// - You never write `@fieldParentPtr` or the field's name.
/// - It finds the TypedNode by its type.
/// - You get your struct back only when the type matches.
/// - Otherwise you get null. The `must` calls panic instead.
/// - `P` MUST be a struct with exactly one `SinglyTypedNode` or
///   `DoublyTypedNode` field, under any name.
/// - Anything else is a compile error that names the type.
pub fn Typed(comptime P: type) type {
    const field: []const u8 = comptime findTypedNode(P);
    const TN: type = @FieldType(P, field);

    return struct {
        /// Writes the type id of `p` into its TypedNode.
        ///
        /// Call it right after you create `p`.
        ///
        /// - A new `p` has no type id, even when every field has its default
        ///   value.
        /// - Without it, `parentFromNode` and `parentFromAnchor` return null
        ///   for `p`.
        /// - `fromAny` is different. See `fromAny`.
        /// - A whole-struct write erases the type id. Call `setTypeId` again
        ///   after each one.
        ///   - `message = .{ ... };`
        ///   - a reset, clear or zero-fill of the whole struct
        /// - Writing one field keeps the type id.
        /// - `allocator.create` gives you undefined memory. Set up `p` first.
        ///   Then call `setTypeId`.
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

        /// Returns the Node of `p`.
        ///
        /// Give it to the std list.
        ///
        /// ```zig
        /// list.append(TypedMessage.node(&message));
        /// ```
        pub inline fn node(p: *P) *Node {
            return &@field(p.*, field).node;
        }

        /// Returns the `P` that contains the Node.
        ///
        /// - Returns null when the Node is in another type.
        /// - Returns null when `setTypeId` was never called.
        /// - The Node MUST be inside a `SinglyTypedNode` or `DoublyTypedNode`.
        ///   - A plain std Node is not caught.
        ///   - The check then reads memory that is not a type id.
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

        /// Like `parentFromNode`, but panics instead of returning null.
        ///
        /// - It panics in every build mode.
        /// - The panic message names both types.
        /// - The Node MUST be inside a `SinglyTypedNode` or `DoublyTypedNode`.
        pub inline fn mustParentFromNode(n: *Node) *P {
            return parentFromNode(n) orelse wrongType("mustParentFromNode", &typedNodeOf(n).*.anchor);
        }

        /// Returns the `P` that contains the Node.
        ///
        /// It does not check the type.
        ///
        /// - The Node MUST be inside a `P`.
        /// - A wrong Node gives you garbage. Nothing checks it, in any build
        ///   mode.
        pub inline fn parentFromNodeUnchecked(n: *Node) *P {
            return @fieldParentPtr(field, typedNodeOf(n));
        }

        /// Returns true when the Node is inside a `P`.
        ///
        /// - Returns false when `setTypeId` was never called.
        /// - The Node MUST be inside a `SinglyTypedNode` or `DoublyTypedNode`.
        pub inline fn is(n: *const Node) bool {
            const tn: *const TN = @fieldParentPtr("node", n);
            return isId(tn.*.anchor.typeId());
        }

        /// Returns the `*Anchor` of `p`.
        ///
        /// Pass it where the type is not known yet.
        ///
        /// See `Anchor`.
        pub inline fn anchor(p: *P) *Anchor {
            return &@field(p.*, field).anchor;
        }

        /// Returns the `P` behind the `*Anchor`.
        ///
        /// - Returns null when the Anchor is in another type.
        /// - Returns null when `setTypeId` was never called.
        /// - The Anchor MUST come from `anchor`.
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

        /// Like `parentFromAnchor`, but panics instead of returning null.
        ///
        /// - It panics in every build mode.
        /// - The panic message names both types.
        pub inline fn mustParentFromAnchor(a: *Anchor) *P {
            return parentFromAnchor(a) orelse wrongType("mustParentFromAnchor", a);
        }

        /// Returns an `AnyParent` for `p`: its address and its type id.
        ///
        /// - Call `setTypeId` on `p` first. `toAny` does not check it.
        /// - It does not copy `p`. `p` MUST stay alive while the `AnyParent`
        ///   is in use.
        pub inline fn toAny(p: *P) AnyParent {
            return .{ .ptr = p, .type_id = typeId() };
        }

        /// Returns the `P` behind an `AnyParent`.
        ///
        /// - Returns null when the `AnyParent` is of another type.
        /// - The `AnyParent` MUST come from `toAny`.
        /// - `setTypeId` MUST have been called on the Parent.
        ///   - When runtime safety is on, a missing call panics.
        ///   - Otherwise nothing catches it.
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

/// The one fixed point in your struct.
///
/// From it you reach the struct's type id, the struct itself and its Node.
///
/// *Da ubi consistam, et terram movebo.* Give me a place to stand, and I
/// will move the Earth. (Archimedes)
///
/// It is for container authors.
///
/// Application code passes an `AnyParent`, which is two words.
///
/// A `*Anchor` is one word.
///
/// Use it in your own container, or as a C callback's `void*` context.
///
/// - Every struct with a TypedNode has one Anchor, inside the TypedNode.
/// - `setTypeId` writes the struct's type id into it.
/// - Get it with `TypedMessage.anchor(&message)`.
/// - Get the struct back with `TypedMessage.parentFromAnchor(a)`. You get
///   null for another type.
/// - You never make an Anchor. You only pass `*Anchor`.
/// - A `*Anchor` does not keep the struct alive. The struct MUST outlive it.
///
/// `*Node` carries any struct with the same Node kind.
///
/// `*Anchor` carries any struct.
///
/// Both turn back into your struct with a type check.
pub const Anchor = struct {
    /// Do not write this field.
    ///
    /// `Typed(P).setTypeId` writes it.
    ///
    /// Paternitas trusts this value. A wrong value is not caught.
    _type_id: TypeId = null,

    /// Returns the Parent's type name.
    ///
    /// Use it in logs and panic messages.
    ///
    /// It returns `<no type>` when `setTypeId` was never called on the Parent.
    pub fn typeName(a: *const Anchor) []const u8 {
        return if (a.info()) |i| i.*.name else "<no type>";
    }

    /// Returns an `AnyParent` for the Parent: its address and its type id.
    ///
    /// It returns null when `setTypeId` was never called on the Parent.
    pub inline fn toAny(a: *Anchor) ?AnyParent {
        const ti: *const TypeInfo = a.info() orelse return null;
        return ti.toAny(a);
    }

    /// Returns the Parent's type id.
    ///
    /// It returns null when `setTypeId` was never called on the Parent.
    pub inline fn typeId(a: *const Anchor) TypeId {
        return a.*._type_id;
    }

    /// For container authors.
    ///
    /// Returns the `TypeInfo` of the Parent's type.
    ///
    /// It returns null when `setTypeId` was never called on the Parent.
    pub inline fn info(a: *const Anchor) ?*const TypeInfo {
        const id: *const anyopaque = a.typeId() orelse return null;
        return @ptrCast(@alignCast(id));
    }
};

/// A Parent's address and its type id.
///
/// Pass it where the code in between does not know your struct's type: a queue,
/// a map, a union field.
///
/// They copy the two words.
///
/// They never copy your struct.
///
/// - Look up a handler by `type_id`, and give it `ptr`. The handler is
///   chosen without reading the struct.
/// - Or get the struct back with `Typed(P).fromAny`. You get null for another
///   type.
/// - The Parent MUST stay alive while you use the `AnyParent`.
/// - Get one only from `toAny`. Paternitas trusts its fields.
pub const AnyParent = struct {
    /// The Parent's address.
    ptr: *anyopaque,
    /// The Parent's type id.
    type_id: TypeId,
};

/// An id for a struct type.
///
/// Each Parent type gets its own.
///
/// Zig's `type` exists only at compile time.
///
/// A `TypeId` exists at run time.
///
/// - Use it as a map key, when Parents of several types share a map or a
///   dispatch table.
/// - Null means no type: `setTypeId` was never called on that struct.
/// - It is valid only inside one running program. Do not save it or send it.
/// - A shared library has its own type ids, even for the same struct type.
///   A struct marked by `setTypeId` in the library fails the type check in
///   the program.
pub const TypeId = ?*const anyopaque;

/// For you, if you write your own container.
///
/// Application code does not need it.
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
