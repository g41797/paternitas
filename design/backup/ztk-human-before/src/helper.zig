// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! One helper per parent type. It does the boring part.
//!
//! One line makes it: `const MSG = ParentHelper(Msg);`
//!
//! There is nothing to instantiate and nothing to keep.
//!
//! It finds the one `SinglyTypedNode` or `DoublyTypedNode` field by type.
//!
//! - The field's name is yours to choose.
//! - Zero such fields, or two, is a compile error that names the type.
//!
//! Your parent declares two methods. The helper calls them when it creates
//! or releases the parent.
//!
//! - `pub fn init(self: *Parent, alloc: std.mem.Allocator, io: std.Io) !void`
//! - `pub fn finish(self: *Parent, alloc: std.mem.Allocator, io: std.Io) void`
//!
//! An empty body is fine when there is nothing to do. Write `_ = alloc;` and
//! `_ = io;` for what you do not use.
//!
//! A parent you allocate yourself never meets `create` or `destroy`. It
//! declares neither.
//!
//! Examples:
//! https://g41797.github.io/matryoshka-ztk/examples/helper/
const _doc_stub = void;

/// The helper for `Parent`.
///
/// It gives you:
///
/// - the type's id, and a test against it
/// - your pointer back, from an `*Anchor` or a `Slot`
/// - the `*Anchor`, from your pointer
/// - the dispatch view, `AnyParent`, both ways
/// - `create` and `destroy`, which run your `init` and `finish`
pub fn ParentHelper(comptime Parent: type) type {
    const P = paternitas.Typed(Parent);
    comptime {
        if (paternitas.findTypedNode(Parent) == null) @compileError(@typeName(Parent) ++
            ": no TypedNode, so it cannot be a ztk parent");
    }

    return struct {
        /// This type's id. Equal ids mean the same type.
        pub const ID: TypeId = P.typeId();

        /// True when the id is this type's.
        pub inline fn isIt(id: TypeId) bool {
            return P.isId(id);
        }

        /// Makes a parent you allocated yourself ready for use. It clears the
        /// link and writes the id.
        ///
        /// Call it once, before the parent goes anywhere. `create` calls it
        /// for you.
        ///
        /// Never call it on a parent that is on a chain or a std list.
        pub inline fn setTypeId(self: *Parent) void {
            P.node(self).* = .{};
            P.setTypeId(self);
        }

        /// The Anchor embedded in your parent.
        ///
        /// It cannot fail. The type is known at compile time.
        pub inline fn toAnchor(self: *Parent) *Anchor {
            return P.anchor(self);
        }

        /// Your pointer, from a bare Anchor.
        ///
        /// Null when the Anchor is in another type. It reads the Anchor and
        /// changes nothing.
        pub inline fn fromAnchor(anchor: *Anchor) ?*Parent {
            return P.parentFromAnchor(anchor);
        }

        /// Your pointer, from a bare Anchor. Panics on another type.
        ///
        /// It panics in every optimization mode. The message names the type you
        /// asked for and the type that was there.
        pub inline fn mustFromAnchor(anchor: *Anchor) *Parent {
            return fromAnchor(anchor) orelse wrongType("mustFromAnchor", anchor);
        }

        /// Your pointer, from the Slot it sits in.
        ///
        /// Null when the Slot is empty or has another type. The Slot stays full.
        pub inline fn fromSlot(slot: *const Slot) ?*Parent {
            const anchor = slot.* orelse return null;
            return fromAnchor(anchor);
        }

        /// Your pointer, from the Slot it sits in. Panics on an empty Slot or
        /// another type.
        pub inline fn mustFromSlot(slot: *const Slot) *Parent {
            const anchor = slot.* orelse
                @panic("mustFromSlot: the Slot is empty");
            return fromAnchor(anchor) orelse wrongType("mustFromSlot", anchor);
        }

        /// Takes your parent out of the Slot. On success the Slot is empty.
        ///
        /// Null when the Slot is empty or has another type. The Slot is
        /// untouched then.
        ///
        /// Refuses a parent still on a chain. Take it off first.
        pub inline fn moveFromSlot(slot: *Slot) ?*Parent {
            const anchor = slot.* orelse return null;
            const out = fromAnchor(anchor) orelse return null;

            check(!inner.isLinked(anchor), "a parent crosses the border unlinked");
            slot.* = null;

            return out;
        }

        /// Takes your parent out of the Slot. Panics on an empty Slot or
        /// another type.
        ///
        /// Use it when you know what is there, and do not want to write the
        /// unwrap.
        pub inline fn mustMoveFromSlot(slot: *Slot) *Parent {
            const anchor = slot.* orelse
                @panic("mustMoveFromSlot: the Slot is empty");
            const out = fromAnchor(anchor) orelse wrongType("mustMoveFromSlot", anchor);

            check(!inner.isLinked(anchor), "a parent crosses the border unlinked");
            slot.* = null;

            return out;
        }

        /// The dispatch view of your parent.
        ///
        /// It is only a view. The parent stays where it is, and nothing moves.
        pub inline fn toAny(self: *Parent) AnyParent {
            return P.toAny(self);
        }

        /// Your pointer, from a dispatch view.
        ///
        /// Null when the view is of another type.
        pub inline fn fromAny(any: AnyParent) ?*Parent {
            return P.fromAny(any);
        }

        /// The std Node type of this parent's TypedNode.
        pub const Node = P.Node;

        /// The std Node embedded in your parent, for a std list of your own.
        ///
        /// The parent MUST NOT be on a toolkit chain while it is on a std list.
        /// The two share the `next` word.
        pub inline fn node(self: *Parent) *Node {
            return P.node(self);
        }

        /// Your pointer, from a std Node.
        ///
        /// Null when the Node is in another type, or when setTypeId was never
        /// called on it.
        ///
        /// The Node MUST live in a TypedNode. A std list you get back from a
        /// caller has only Nodes of parents.
        pub inline fn fromNode(n: *Node) ?*Parent {
            return P.parentFromNode(n);
        }

        /// True when the parent is on a chain.
        pub inline fn isLinked(self: *Parent) bool {
            return inner.isLinked(toAnchor(self));
        }

        /// Makes a parent for you, in four steps:
        ///
        /// - allocates it
        /// - runs its `init`
        /// - calls setTypeId
        /// - puts it into the Slot
        ///
        /// When `init` fails, it frees the parent and returns the error. The Slot
        /// stays empty then.
        ///
        /// Refuses a Slot that is not empty.
        ///
        /// Your `init` gets the allocator and the `Io`. The toolkit keeps neither.
        /// In Zig 0.16 files, sockets, time and threads all go through `Io`. A
        /// parent with a connection needs it to close the connection.
        ///
        /// A parent that keeps the `Io` in a field MUST NOT outlive the runtime
        /// that made it.
        pub fn create(allocator: std.mem.Allocator, io: Io, slot: *Slot) !void {
            comptime requireHooks();
            check(slot.* == null, "an acquisition needs an empty Slot on entry");

            const parent: *Parent = try allocator.create(Parent);
            errdefer allocator.destroy(parent);

            try parent.init(allocator, io);
            setTypeId(parent);

            slot.* = toAnchor(parent);
        }

        /// Runs your parent's `finish`, empties the Slot and frees the parent.
        ///
        /// Does nothing on an empty Slot. So one `defer` covers every way out,
        /// even when the parent was never created.
        ///
        /// Refuses a parent still on a chain.
        pub fn destroy(allocator: std.mem.Allocator, io: Io, slot: *Slot) void {
            comptime requireHooks();

            const anchor = slot.* orelse return;
            check(!inner.isLinked(anchor), "a parent crosses the border unlinked");

            const out = mustFromAnchor(anchor);
            slot.* = null;

            out.finish(allocator, io);
            allocator.destroy(out);
        }

        fn wrongType(comptime call: []const u8, found: *const Anchor) noreturn {
            std.debug.panic(
                call ++ ": asked for {s}, found {s}",
                .{ @typeName(Parent), found.typeName() },
            );
        }

        fn requireHooks() void {
            if (!@hasDecl(Parent, "init"))
                @compileError(@typeName(Parent) ++
                    ": a parent the helper creates declares `pub fn init(self: *" ++
                    @typeName(Parent) ++ ", alloc: std.mem.Allocator, io: std.Io) !void` — an empty body is fine");

            if (!@hasDecl(Parent, "finish"))
                @compileError(@typeName(Parent) ++
                    ": a parent the helper releases declares `pub fn finish(self: *" ++
                    @typeName(Parent) ++ ", alloc: std.mem.Allocator, io: std.Io) void` — an empty body is fine");
        }
    };
}

const check = @import("internal/check.zig").check;
const inner = @import("inner.zig");
const paternitas = @import("paternitas");
const Anchor = inner.Anchor;
const AnyParent = inner.AnyParent;
const TypeId = inner.TypeId;
const Slot = inner.Slot;
const std = @import("std");
const Io = std.Io;
