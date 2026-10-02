// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Paternitas: intrusive type-erased programming for Zig.
//!
//! A std Node does not say which Parent it lives in. Paternitas says.
//!
//! - `Link` pairs a std Node with an `Anchor`. A Parent embeds one.
//! - `Anchor` is one stamped word. Its address is the erased reference.
//! - `container.TypeInfo` describes one Parent type. Its address is the
//!   `TypeId`. For container authors only.
//! - `Info(P)` is the typed helper, generated at comptime.
//! - `AnyParent` is a dispatch view: the Parent address and its TypeId.
//!
//! Mechanism, not policy. Paternitas says where things are and what type
//! they belong to. Ownership, chain conventions and allocation belong to the
//! containers built on top.

const std = @import("std");

/// For container authors: the type description and the layout facts a
/// container needs to chain through a Node and find a Parent without knowing
/// its type. Application code does not need it.
pub const container = @import("container.zig");

const TypeInfo = container.TypeInfo;
const NodeKind = container.NodeKind;

/// A Parent type's identity: the address of its `TypeInfo`.
///
/// Null is the id of an Anchor that was never stamped. Null matches no
/// Parent, so zeroed memory is a valid unstamped Anchor.
///
/// Valid inside one running binary only. Not persistent, not serialized.
pub const TypeId = ?*const anyopaque;

/// One stamped word inside every Parent, in its Link.
///
/// The Anchor is not the object; the Parent is. The Anchor is one small
/// marker inside the Parent, and `*Anchor` is the erased reference to it:
/// the address says where the Parent is, the stamped value says what it is.
///
/// A plain struct. It becomes `extern` the day it has to cross an ABI.
pub const Anchor = struct {
    type_id: TypeId = null,

    /// This Parent type's description. Null when unstamped.
    ///
    /// For container authors. Application code does not need it.
    pub inline fn info(a: *const Anchor) ?*const TypeInfo {
        const p = a.type_id orelse return null;
        return @ptrCast(@alignCast(p));
    }

    /// The dispatch view of the Parent behind this Anchor, without knowing
    /// its type. Null when unstamped.
    ///
    /// For a consumer holding a bare `*Anchor` and a `TypeId -> handler` map.
    pub inline fn toAny(a: *Anchor) ?AnyParent {
        const ti = a.info() orelse return null;
        return ti.toAny(a);
    }
};

/// The dispatch view of a Parent: where it is and what it is.
///
/// One way. Built from an Anchor or a `*P`, consumed by handlers. There is
/// no way back to the Anchor; the code that built it still has one.
///
/// MUST: built only by `TypeInfo.toAny` and `Info(P).toAny`, both of which
/// take mutable pointers. So `ptr` is always mutable memory.
pub const AnyParent = struct {
    /// The Parent.
    ptr: *anyopaque,
    type_id: TypeId,
};

/// A std Node and an Anchor, as one type.
///
/// One type means one layout, so the Node-to-Anchor distance is the same in
/// every Parent. That is what lets a check read the Anchor before it knows
/// the Parent type.
///
/// Comptime glue. A Parent embeds `SLink` or `DLink` once and never calls
/// into it.
pub fn Link(comptime N: type) type {
    return struct {
        node: N = .{},
        anchor: Anchor = .{},

        pub const Node = N;
        pub const kind: NodeKind =
            if (N == std.SinglyLinkedList.Node) .single else .double;
        pub const node_next_offset: isize =
            @as(isize, @offsetOf(@This(), "node") + @offsetOf(N, "next")) -
            @as(isize, @offsetOf(@This(), "anchor"));
    };
}

pub const SLink = Link(std.SinglyLinkedList.Node);
pub const DLink = Link(std.DoublyLinkedList.Node);

/// Panics where runtime safety is on. Compiled out elsewhere, so a broken
/// contract is never an assumption the optimizer may act on.
inline fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}

fn findLink(comptime P: type) []const u8 {
    comptime {
        const ti = @typeInfo(P);
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

/// The type name behind an Anchor, or `<unstamped>`.
pub fn nameOf(a: *const Anchor) []const u8 {
    return if (a.info()) |i| i.name else "<unstamped>";
}

/// The typed helper for one Parent type.
///
/// `P` is a struct with exactly one `SLink` or `DLink` field, any name, any
/// position. Zero, two, or a non-struct is a compile error naming the type.
pub fn Info(comptime P: type) type {
    const field = comptime findLink(P);
    const L = @FieldType(P, field);

    return struct {
        pub const Node = L.Node;

        const desc: TypeInfo = .{
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
        /// Does not touch the Node, so a Parent that is already linked may be
        /// stamped. `allocator.create` returns undefined memory: initialize
        /// the Parent before stamping it.
        pub inline fn stamp(p: *P) void {
            @field(p.*, field).anchor.type_id = typeId();
        }

        pub inline fn anchor(p: *P) *Anchor {
            return &@field(p.*, field).anchor;
        }

        pub inline fn node(p: *P) *Node {
            return &@field(p.*, field).node;
        }

        inline fn linkOf(n: *Node) *L {
            return @fieldParentPtr("node", n);
        }

        /// True when the Node's Anchor is stamped as `P`.
        ///
        /// MUST: the Node lives in a Paternitas Link.
        pub inline fn is(n: *Node) bool {
            return isId(linkOf(n).anchor.type_id);
        }

        /// The Parent, from its Anchor. Null when the Anchor is another type
        /// or unstamped.
        pub inline fn fromAnchor(a: *Anchor) ?*P {
            if (!isId(a.type_id)) return null;
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
            check(isId(anchor(p).type_id), "fromAny: the Parent was never stamped");
            return p;
        }

        /// The Parent, from its Node. Null when the Node's Anchor is another
        /// type or unstamped.
        ///
        /// MUST: the Node lives in a Paternitas Link.
        pub inline fn parentFromNode(n: *Node) ?*P {
            if (!is(n)) return null;
            return parentFromNodeUnchecked(n);
        }

        /// The Parent, from its Node. Panics in every build mode on another
        /// type, naming both.
        pub inline fn mustParentFromNode(n: *Node) *P {
            return parentFromNode(n) orelse wrongType("mustParentFromNode", &linkOf(n).anchor);
        }

        /// The Parent, from its Node, without the check. The caller knows.
        pub inline fn parentFromNodeUnchecked(n: *Node) *P {
            return @fieldParentPtr(field, linkOf(n));
        }

        fn wrongType(comptime call: []const u8, found: *const Anchor) noreturn {
            std.debug.panic(call ++ ": asked for {s}, found {s}", .{ @typeName(P), nameOf(found) });
        }
    };
}

// ---------------------------------------------------------------- tests

const testing = std.testing;

const Msg = struct { text: []const u8, link: SLink = .{} };
const Job = struct { link: DLink = .{}, id: u32, extra: u64 = 7 };
const MI = Info(Msg);
const JI = Info(Job);

// A container-style chain over Anchors with a self-pointing tail, as
// Matryoshka keeps one.
fn next(a: *Anchor) *?*Anchor {
    const ti = a.info() orelse @panic("chain: unstamped");
    return @ptrCast(ti.nextField(a));
}

const Chain = struct {
    head: ?*Anchor = null,
    tail: ?*Anchor = null,

    fn append(q: *Chain, a: *Anchor) void {
        check(next(a).* == null, "already linked");
        next(a).* = a;
        if (q.tail) |t| next(t).* = a else q.head = a;
        q.tail = a;
    }

    fn popFirst(q: *Chain) ?*Anchor {
        const a = q.head orelse return null;
        const n = next(a).*.?;
        if (n == a) {
            q.head = null;
            q.tail = null;
        } else q.head = n;
        next(a).* = null;
        return a;
    }
};

test "the uniform offset holds" {
    try testing.expect(container.uniform_next_offset != null);
}

test "ids are distinct; TypeInfo fields and accessors" {
    try testing.expect(MI.typeId() != JI.typeId());
    var m = Msg{ .text = "x" };
    MI.stamp(&m);
    const i = MI.anchor(&m).info().?;
    try testing.expect(i.node_kind == .single);
    try testing.expectEqualStrings(@typeName(Msg), i.name);
    try testing.expect(i.parent(MI.anchor(&m)) == @as(*anyopaque, &m));
    try testing.expect(i.node(MI.anchor(&m), std.SinglyLinkedList.Node) == MI.node(&m));
}

test "SLink and DLink parents in one Anchor chain, then a std list" {
    var m = Msg{ .text = "hi" };
    var j = Job{ .id = 42 };
    MI.stamp(&m);
    JI.stamp(&j);

    var q: Chain = .{};
    q.append(MI.anchor(&m));
    q.append(JI.anchor(&j));
    const a = q.popFirst().?;
    const b = q.popFirst().?;
    try testing.expect(MI.fromAnchor(a).? == &m);
    try testing.expect(JI.fromAnchor(a) == null);
    try testing.expect(JI.fromAnchor(b).?.id == 42);

    var list: std.DoublyLinkedList = .{};
    list.append(JI.node(&j));
    const n = list.popFirst().?;
    try testing.expect(JI.parentFromNode(n).? == &j);
}

test "unstamped" {
    var m = Msg{ .text = "x" };
    try testing.expect(!MI.is(MI.node(&m)));
    try testing.expect(MI.parentFromNode(MI.node(&m)) == null);
    try testing.expect(MI.fromAnchor(MI.anchor(&m)) == null);
    try testing.expect(MI.anchor(&m).info() == null);
    try testing.expectEqualStrings("<unstamped>", nameOf(MI.anchor(&m)));
}

test "stamp leaves a linked node intact" {
    var j1 = Job{ .id = 1 };
    var j2 = Job{ .id = 2 };
    var list: std.DoublyLinkedList = .{};
    list.append(JI.node(&j1));
    list.append(JI.node(&j2));
    JI.stamp(&j1);
    JI.stamp(&j2);
    try testing.expect(JI.parentFromNode(list.popFirst().?).?.id == 1);
    try testing.expect(JI.parentFromNode(list.popFirst().?).?.id == 2);
}

test "AnyParent dispatch through a map, no Info at dispatch" {
    var m = Msg{ .text = "hi" };
    var j = Job{ .id = 42 };
    MI.stamp(&m);
    JI.stamp(&j);

    const H = struct {
        var seen_msg: ?*Msg = null;
        var seen_job: u32 = 0;
        fn onMsg(p: *anyopaque) void {
            seen_msg = @ptrCast(@alignCast(p));
        }
        fn onJob(p: *anyopaque) void {
            const jj: *Job = @ptrCast(@alignCast(p));
            seen_job = jj.id;
        }
    };
    const Handler = *const fn (*anyopaque) void;
    var map = std.AutoHashMap(TypeId, Handler).init(testing.allocator);
    defer map.deinit();
    try map.put(MI.typeId(), H.onMsg);
    try map.put(JI.typeId(), H.onJob);

    var q: Chain = .{};
    q.append(MI.anchor(&m));
    q.append(JI.anchor(&j));
    while (q.popFirst()) |a| {
        const any = a.toAny().?;
        (map.get(any.type_id).?)(any.ptr);
    }
    try testing.expect(H.seen_msg.? == &m);
    try testing.expect(H.seen_job == 42);
}

test "toAny and fromAny" {
    var m = Msg{ .text = "x" };
    MI.stamp(&m);
    const any = MI.toAny(&m);
    try testing.expect(MI.fromAny(any).? == &m);
    try testing.expect(JI.fromAny(any) == null);
    const via = MI.anchor(&m).toAny().?;
    try testing.expect(via.ptr == any.ptr and via.type_id == any.type_id);

    var unstamped = Msg{ .text = "y" };
    try testing.expect(MI.anchor(&unstamped).toAny() == null);
}

test "AnyParent and *Anchor in a tagged union" {
    const Event = union(enum) { tick: u64, anchor: *Anchor, view: AnyParent };
    var m = Msg{ .text = "x" };
    MI.stamp(&m);
    const evs = [_]Event{ .{ .tick = 1 }, .{ .anchor = MI.anchor(&m) }, .{ .view = MI.toAny(&m) } };
    var hits: u32 = 0;
    for (evs) |e| switch (e) {
        .tick => {},
        .anchor => |a| hits += @intFromBool(MI.fromAnchor(a) != null),
        .view => |v| hits += @intFromBool(MI.fromAny(v) != null),
    };
    try testing.expectEqual(@as(u32, 2), hits);
}

test "the fallback offset in TypeInfo finds next, for both kinds" {
    // nextField uses the comptime constant while it holds. The stored
    // offset is what it falls back to; it must land on the same word.
    var m = Msg{ .text = "x" };
    var j = Job{ .id = 1 };
    MI.stamp(&m);
    JI.stamp(&j);

    const ma = MI.anchor(&m);
    const ja = JI.anchor(&j);
    const mi = ma.info().?;
    const ji = ja.info().?;

    try testing.expect(@intFromPtr(ma) +% @as(usize, @bitCast(mi.node_next_offset)) == @intFromPtr(&MI.node(&m).next));
    try testing.expect(@intFromPtr(ja) +% @as(usize, @bitCast(ji.node_next_offset)) == @intFromPtr(&JI.node(&j).next));
    try testing.expect(@intFromPtr(mi.nextField(ma)) == @intFromPtr(&MI.node(&m).next));
    try testing.expect(@intFromPtr(ji.nextField(ja)) == @intFromPtr(&JI.node(&j).next));
}
