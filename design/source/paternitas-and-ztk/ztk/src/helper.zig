// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! One helper per parent type. It does the boring part.
//!
//! One line makes it: `const MSG = ParentHelper(Msg);`
//!
//! There is nothing to instantiate and nothing to keep.
//!
//! The helper wraps `paternitas.Typed(Parent)`. It finds the one
//! `SinglyTypedNode` or `DoublyTypedNode` field by type, so its name is yours
//! to choose. Zero such fields, or two, is a compile error naming the type.
//!
//! Two methods your parent declares, where the helper creates or releases it:
//!
//! - `pub fn init(self: *Parent, alloc: std.mem.Allocator, io: std.Io) !void`
//! - `pub fn finish(self: *Parent, alloc: std.mem.Allocator, io: std.Io) void`
//!
//! An empty body is fine. It says there is nothing to do, and a parent that
//! uses neither the allocator nor the `Io` says so with `_ = alloc;`. A container that
//! allocates itself never calls `create`, so it declares neither.
//!
//! Examples:
//! https://g41797.github.io/matryoshka-ztk/examples/helper/
const _doc_stub = void;

/// Generates the runtime type support for `Parent`.
///
/// What it gives you:
///
/// - the type's id, and the test against it
/// - the crossing from an `*Anchor` or a `Slot` back to your pointer
/// - the crossing the other way
/// - the dispatch view, both ways
/// - create and destroy, which run your own `init` and `finish`
pub fn ParentHelper(comptime Parent: type) type {
    const P = paternitas.Typed(Parent);

    return struct {
        /// This type's id.
        ///
        /// One description per type, `const`, so its address is the identity.
        pub const ID: TypeId = P.typeId();

        /// True when the id is this type's.
        pub inline fn isIt(id: TypeId) bool {
            return P.isId(id);
        }

        /// Makes a fresh parent you allocated yourself usable: clears its
        /// link and writes the id.
        ///
        /// Runs once per parent, before it is used anywhere. `create` does it
        /// for you. Never on a parent that is on a chain or a std list.
        pub inline fn setTypeId(self: *Parent) void {
            P.node(self).* = .{};
            P.setTypeId(self);
        }

        /// The Anchor embedded in your parent.
        ///
        /// Cannot fail — the type is known at compile time.
        pub inline fn toAnchor(self: *Parent) *Anchor {
            return P.anchor(self);
        }

        /// Your pointer, from a bare Anchor.
        ///
        /// Null when the Anchor belongs to another type. Reads the Anchor and
        /// changes nothing.
        pub inline fn fromAnchor(anchor: *Anchor) ?*Parent {
            return P.fromAnchor(anchor);
        }

        /// Your pointer, from a bare Anchor. Panics on another type.
        ///
        /// Panics in every optimization mode, and the message names the type
        /// asked for and the type that was there.
        pub inline fn mustFromAnchor(anchor: *Anchor) *Parent {
            return fromAnchor(anchor) orelse wrongType("mustFromAnchor", anchor);
        }

        /// Your pointer, from the Slot holding it.
        ///
        /// Null when the Slot is empty or holds another type. Leaves the Slot
        /// full.
        pub inline fn fromSlot(slot: *const Slot) ?*Parent {
            const anchor = slot.* orelse return null;
            return fromAnchor(anchor);
        }

        /// Your pointer, from the Slot holding it. Panics on an empty Slot or
        /// another type.
        pub inline fn mustFromSlot(slot: *const Slot) *Parent {
            const anchor = slot.* orelse
                @panic("mustFromSlot: the Slot is empty");
            return fromAnchor(anchor) orelse wrongType("mustFromSlot", anchor);
        }

        /// Takes your parent out of the Slot.
        ///
        /// Null when the Slot is empty or holds another type, and then the
        /// Slot is untouched. On success the Slot is empty.
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
        /// The form for a caller who knows what is there and does not want to
        /// write the unwrap.
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
        /// A view, not an owner. The parent stays where it is and whoever
        /// owned it still does.
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
        /// MUST: the parent is on none of the toolkit's chains while it is on
        /// a std list. The `next` word is shared.
        pub inline fn node(self: *Parent) *Node {
            return P.node(self);
        }

        /// Your pointer, from a std Node. Null when the Node belongs to
        /// another type, or when setTypeId was never called.
        ///
        /// MUST: the Node lives in a TypedNode. A std list handed back by a
        /// caller holds only Nodes of parents.
        pub inline fn fromNode(n: *Node) ?*Parent {
            return P.parentFromNode(n);
        }

        /// True when the parent is on a chain.
        pub inline fn isLinked(self: *Parent) bool {
            return inner.isLinked(toAnchor(self));
        }

        /// Allocates your parent, runs its `init`, calls setTypeId, and fills the
        /// Slot.
        ///
        /// Frees the parent again when `init` fails, and passes the failure
        /// on. The Slot stays empty then.
        ///
        /// Refuses a Slot that is not empty on entry.
        ///
        /// Your `init` gets the allocator and the `Io`, and the toolkit keeps
        /// neither. ztk passes both where 3tk passes an allocator alone,
        /// because Zig 0.16 moved file, net, time and concurrency behind
        /// `Io`, and a parent that owns a connection cannot release it
        /// without one. A parent that keeps the `Io` in a field MUST NOT
        /// outlive the runtime that produced it.
        pub fn create(allocator: std.mem.Allocator, io: Io, slot: *Slot) !void {
            comptime requireHooks();
            check(slot.* == null, "an acquisition needs an empty Slot on entry");

            const parent: *Parent = try allocator.create(Parent);
            errdefer allocator.destroy(parent);

            try parent.init(allocator, io);
            setTypeId(parent);

            slot.* = toAnchor(parent);
        }

        /// Runs your parent's `finish`, empties the Slot, and frees the parent.
        ///
        /// Does nothing on an empty Slot, so one `defer` covers every path
        /// out, including the path where the parent was never created.
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
