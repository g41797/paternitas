// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Paternitas adds a runtime type check to Zig's intrusive, type-erased lists.
//!
//! An intrusive list gives you a Node, not your struct.
//!
//! You get your struct back with `@fieldParentPtr`:
//!
//! ```zig
//! const node = list.popFirst().?;
//! const job: *Job = @fieldParentPtr("node", node);
//! ```
//!
//! But maybe `node` belongs to a `Message`.
//!
//! Nothing stops you.
//!
//! Now `job` points at a `Message`.
//!
//! The bug may show up much later.
//!
//! Paternitas tells you whether the Node really is in the struct you ask for.
//!
//! - If it is not, you get null.
//! - The `must` calls panic instead. The panic message shows both type names.
//! - This works in every build mode.
//! - Your list is still the std list. No allocator. No lock.
//!
//! ## The four calls you will use
//!
//! - `Typed(P)` makes the helper for one struct type.
//! - `setTypeId(&p)` sets the struct's type id.
//! - `node(&p)` gives its Node to the std list.
//! - `parentFromNode(n)` checks the Node and gives your struct back, or null.
//!
//! `mustParentFromNode` panics instead of returning null.
//!
//! Use it when another type is a bug.
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
//! ## The setTypeId rule
//!
//! Call `setTypeId` after you create the struct, and again after each
//! whole-struct write. The compiler cannot check it.
//!
//! The struct MUST stay alive while its Node, Anchor or Any is in use.
//!
//! ## Beyond lists
//!
//! - `Any` passes a struct through a queue, a map, a union field or a callback.
//! - `typeId` gives any struct a type id, with or without a TypedNode.
//! - `container` is for you, if you write your own container.
//!
//! ## The site
//!
//! The [site](https://g41797.github.io/paternitas/) has the rest:
//!
//! - "Are you my Parent?": the problem, and when you need Paternitas.
//! - "Migrate your code": the five steps from a plain std list.
//! - "The setTypeId rule", "Limits", and the seven examples.

const _doc_stub = void;

/// Use this in a struct that goes into a `std.SinglyLinkedList`.
///
/// It replaces `std.SinglyLinkedList.Node`.
pub const SinglyTypedNode = TypedNode(std.SinglyLinkedList.Node);
/// Short for `SinglyTypedNode`.
pub const STNode = SinglyTypedNode;
/// Use this in a struct that goes into a `std.DoublyLinkedList`.
///
/// It replaces `std.DoublyLinkedList.Node`.
pub const DoublyTypedNode = TypedNode(std.DoublyLinkedList.Node);
/// Short for `DoublyTypedNode`.
pub const DTNode = DoublyTypedNode;

/// The std Node with a type check added.
///
/// - It is the field you put in your struct, where the std Node was.
/// - Use `SinglyTypedNode` or `DoublyTypedNode`.
/// - You do not call `TypedNode` yourself.
/// - A struct has at most one. With one, it is a Parent.
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

/// Makes the helper for one struct type. Declare it once per type.
///
/// What the helper can do depends on your struct.
///
/// If your struct has a TypedNode field, it can live in a std list. The
/// helper puts it in the list, and gets it back from a Node:
///
/// ```zig
/// const Message = struct {
///     text: []const u8,
///     tnode: paternitas.DoublyTypedNode = .{},
/// };
/// const TypedMessage = paternitas.Typed(Message);
///
/// var message: Message = .{ .text = "hello" };
/// TypedMessage.setTypeId(&message);
/// list.append(TypedMessage.node(&message));
///
/// const m: ?*Message = TypedMessage.parentFromNode(list.popFirst().?);
/// ```
///
/// `parentFromNode` gives you your struct only if the Node really is in a
/// `Message`. Otherwise it gives null. You never write `@fieldParentPtr` or
/// the field's name. Such a struct is called a Parent.
///
/// If your struct has no TypedNode field, it cannot go in a list. The
/// helper still gives it a type id. So you can pass it through code that
/// does not know its type, and get it back safely:
///
/// ```zig
/// const Point = struct { x: i32, y: i32 };
/// const TypedPoint = paternitas.Typed(Point);
///
/// var point: Point = .{ .x = 3, .y = 4 };
/// const any: paternitas.Any = TypedPoint.toAny(&point);
///
/// const p: ?*Point = TypedPoint.fromAny(any); // your Point, or null
/// ```
///
/// A struct with a TypedNode can do this too.
///
/// The rules:
///
/// - `P` MUST be a struct.
/// - `P` has at most one `SinglyTypedNode` or `DoublyTypedNode` field,
///   under any name. With one, `P` is a Parent.
/// - On a struct without a TypedNode, a call that needs one, like `node` or
///   `parentFromNode`, is a compile error.
/// - Each error message shows the type name.
pub fn Typed(comptime P: type) type {
    const node_field: ?[]const u8 = comptime findTypedNode(P);
    const has_node: bool = node_field != null;
    const field: []const u8 = node_field orelse "";
    const TN: type = if (has_node) @FieldType(P, field) else NoTypedNode;

    return struct {
        /// Sets the type id of `p`: the type id of `P`.
        ///
        /// It writes the type id of `p` into its TypedNode.
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
            comptime needNode();
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
            comptime needNode();
            return &@field(p.*, field).node;
        }

        /// Returns the `P` that contains the Node, or null for another type.
        ///
        /// Use it when the Node may be in several struct types.
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
            comptime needNode();
            if (!is(n)) return null;
            return parentFromNodeUnchecked(n);
        }

        /// Like `parentFromNode`, but panics instead of returning null.
        ///
        /// Use it when another type is a bug.
        ///
        /// - It panics in every build mode.
        /// - The panic message shows both type names.
        /// - The Node MUST be inside a `SinglyTypedNode` or `DoublyTypedNode`.
        pub inline fn mustParentFromNode(n: *Node) *P {
            comptime needNode();
            return parentFromNode(n) orelse wrongType("mustParentFromNode", &typedNodeOf(n).*.anchor);
        }

        /// Returns the `P` that contains the Node.
        ///
        /// It does not check the type.
        ///
        /// Use it only when the type is already known.
        ///
        /// - The Node MUST be inside a `P`.
        /// - A wrong Node gives you garbage. Nothing checks it, in any build
        ///   mode.
        pub inline fn parentFromNodeUnchecked(n: *Node) *P {
            comptime needNode();
            return @fieldParentPtr(field, typedNodeOf(n));
        }

        /// Returns true when the Node is inside a `P` whose type id was set.
        ///
        /// - Returns false when `setTypeId` was never called.
        /// - The Node MUST be inside a `SinglyTypedNode` or `DoublyTypedNode`.
        pub inline fn is(n: *const Node) bool {
            comptime needNode();
            const tn: *const TN = @fieldParentPtr("node", n);
            return isId(tn.*.anchor.typeId());
        }

        /// Returns the `*Anchor` of `p`.
        ///
        /// Pass it where the type is not known yet.
        ///
        /// See `Anchor`.
        pub inline fn anchor(p: *P) *Anchor {
            comptime needNode();
            return &@field(p.*, field).anchor;
        }

        /// Returns the `P` behind the `*Anchor`, or null for another type.
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
            comptime needNode();
            if (!isId(a.typeId())) return null;
            const tn: *TN = @fieldParentPtr("anchor", a);
            return @fieldParentPtr(field, tn);
        }

        /// Like `parentFromAnchor`, but panics instead of returning null.
        ///
        /// - It panics in every build mode.
        /// - The panic message shows both type names.
        pub inline fn mustParentFromAnchor(a: *Anchor) *P {
            comptime needNode();
            return parentFromAnchor(a) orelse wrongType("mustParentFromAnchor", a);
        }

        /// Returns an `Any` for `p`: its address and its type id.
        ///
        /// - Works for every struct, with or without a TypedNode.
        /// - With a TypedNode, call `setTypeId` on `p` first. `toAny` does not
        ///   check it.
        /// - It does not copy `p`. `p` MUST stay alive while the `Any` is in
        ///   use.
        pub inline fn toAny(p: *P) Any {
            return .{ .ptr = p, .type_id = typeId() };
        }

        /// Returns the `P` behind an `Any`, or null for another type.
        ///
        /// - Works for every struct, with or without a TypedNode.
        /// - Returns null when the `Any` is of another type.
        /// - The `Any` MUST come from `toAny`.
        /// - With a TypedNode, `setTypeId` MUST have been called on `p`.
        ///   - When runtime safety is on, a missing call panics.
        ///   - Otherwise nothing catches it.
        pub inline fn fromAny(any: Any) ?*P {
            if (!isId(any.type_id)) return null;
            const p: *P = @ptrCast(@alignCast(any.ptr));
            if (has_node) check(isId(anchor(p).typeId()), "fromAny: setTypeId was never called on the Parent");
            return p;
        }

        /// Returns the type id of `P`.
        ///
        /// Works for every struct, with or without a TypedNode.
        ///
        /// Use it as a map key, when several struct types share a map.
        ///
        /// A type id has limits.
        ///
        /// - It is valid only inside one running program.
        /// - A shared library has its own type ids, even for the same struct
        ///   type.
        /// - Do not save it or send it.
        pub inline fn typeId() TypeId {
            return if (has_node) &desc else &tag;
        }

        /// Returns true when `id` is the type id of `P`.
        ///
        /// Works for every struct, with or without a TypedNode.
        pub inline fn isId(id: TypeId) bool {
            return id == typeId();
        }

        /// The std Node type of `P`.
        ///
        /// Only for a struct with a TypedNode.
        pub const Node: type = if (has_node) TN.Node else noNode();

        // Nothing reads or writes this.
        // - With a TypedNode, its address keeps `desc` unique.
        // - Without one, its address is the type id.
        // A `const` tag would merge with the tag of every other `Typed`.
        // This struct MUST use `P`, as `fromAny` does. A struct that does not
        // use `P` is one type for every `P`, so all would share one tag.
        var tag: u8 = 0;

        const desc: TypeInfo = .{
            ._tag = &tag,
            .name = @typeName(P),
            .anchor_offset = @offsetOf(P, field) + @offsetOf(TN, "anchor"),
            .node_next_offset = TN.node_next_offset,
            .node_kind = TN.kind,
        };

        fn needNode() void {
            if (!has_node) _ = noNode();
        }

        fn noNode() type {
            @compileError(@typeName(P) ++ ": no TypedNode, so it has only typeId, isId, toAny and fromAny");
        }

        inline fn typedNodeOf(n: *Node) *TN {
            return @fieldParentPtr("node", n);
        }

        fn wrongType(comptime call: []const u8, found: *const Anchor) noreturn {
            std.debug.panic(call ++ ": asked for {s}, found {s}", .{ @typeName(P), found.typeName() });
        }
    };
}

/// A one-word handle to a Parent.
///
/// The one fixed point in your struct.
///
/// From it you reach the struct's type id, the struct itself and its Node.
///
/// *Da ubi consistam, et terram movebo.* Give me a place to stand, and I
/// will move the Earth. (Archimedes)
///
/// It is for container authors.
///
/// Application code usually passes an `Any`, which is two words.
///
/// A `*Anchor` is one word.
///
/// Use it in your own container.
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

    /// Returns an `Any` for the Parent: its address and its type id.
    ///
    /// It returns null when `setTypeId` was never called on the Parent.
    pub inline fn toAny(a: *Anchor) ?Any {
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

/// A struct's address and its type id.
///
/// The struct can be any struct, with or without a TypedNode.
///
/// Pass it where the code in between does not know your struct's type: a queue,
/// a map, a union field, a callback.
///
/// They copy the two words.
///
/// They never copy your struct.
///
/// - Look up a handler by `type_id`, and give it `ptr`. The handler is
///   chosen without reading the struct.
/// - Or get the struct back with `Typed(P).fromAny`. You get null for another
///   type.
/// - The struct MUST stay alive while you use the `Any`.
/// - Get one only from `toAny`. Paternitas trusts its fields.
pub const Any = struct {
    /// The struct's address.
    ptr: *anyopaque,
    /// The struct's type id.
    type_id: TypeId,
};

/// A runtime id for a struct type.
///
/// Every struct type gets its own, through `Typed(P).typeId()`.
///
/// Zig's `type` exists only at compile time.
///
/// A `TypeId` exists at run time.
///
/// - It is one pointer, so it works as a map key: a handler map, a dispatch
///   table.
/// - Null means no type: `setTypeId` was never called on that struct.
/// - It is valid only inside one running program. Do not save it or send it.
/// - A shared library has its own type ids, even for the same struct type.
///   A struct whose type id was set in the library fails the type check in
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

// Stands in for the TypedNode of a struct that has none.
// Such a struct cannot go in a list.
// `node`, `parentFromNode` and the other list functions do not compile for it.
// So nothing uses this stand-in.
const NoTypedNode = struct {};

// The name of `P`'s TypedNode field, or null when `P` has none.
fn findTypedNode(comptime P: type) ?[]const u8 {
    comptime {
        const ti: std.builtin.Type = @typeInfo(P);
        if (ti != .@"struct")
            @compileError(@typeName(P) ++ ": not a struct, and Typed takes structs only");
        var found: ?[]const u8 = null;
        for (ti.@"struct".fields) |f| {
            if (f.type == SinglyTypedNode or f.type == DoublyTypedNode) {
                if (found != null)
                    @compileError(@typeName(P) ++ ": more than one TypedNode, and at most one is allowed");
                found = f.name;
            }
        }
        return found;
    }
}

/// Panics when runtime safety is on, and compiles to nothing otherwise.
inline fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}

const TypeInfo = container.TypeInfo;
const NodeKind = container.NodeKind;
const std = @import("std");
