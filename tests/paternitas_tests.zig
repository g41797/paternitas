//! Tests of the paternitas module.

const Msg: type = struct { text: []const u8, link: paternitas.SLink = .{} };
const Job: type = struct { link: paternitas.DLink = .{}, id: u32, extra: u64 = 7 };
const MI: type = paternitas.Info(Msg);
const JI: type = paternitas.Info(Job);

fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}

// The chain word of an Anchor, typed as this chain keeps it.
fn next(a: *Anchor) *?*Anchor {
    const ti: *const TypeInfo = a.info() orelse @panic("chain: unstamped");
    return @ptrCast(ti.nextField(a));
}

// A container-style chain over Anchors. The tail points to itself, as ztk
// keeps its chains. Null in the chain word means: not in a chain.
const Chain: type = struct {
    head: ?*Anchor = null,
    tail: ?*Anchor = null,

    fn append(q: *Chain, a: *Anchor) void {
        check(next(a).* == null, "chain: already linked");
        next(a).* = a;
        if (q.*.tail) |t| next(t).* = a else q.*.head = a;
        q.*.tail = a;
    }

    fn popFirst(q: *Chain) ?*Anchor {
        const a: *Anchor = q.*.head orelse return null;
        const n: *Anchor = next(a).*.?;
        if (n == a) {
            q.*.head = null;
            q.*.tail = null;
        } else q.*.head = n;
        next(a).* = null;
        return a;
    }
};

test "the Chain helper keeps order and clears the chain word" {
    std.testing.log_level = .debug;

    var m1: Msg = .{ .text = "1" };
    var m2: Msg = .{ .text = "2" };
    MI.stamp(&m1);
    MI.stamp(&m2);

    var q: Chain = .{};
    q.append(MI.anchor(&m1));
    try testing.expect(next(MI.anchor(&m1)).*.? == MI.anchor(&m1));
    q.append(MI.anchor(&m2));
    try testing.expect(next(MI.anchor(&m1)).*.? == MI.anchor(&m2));
    try testing.expect(next(MI.anchor(&m2)).*.? == MI.anchor(&m2));

    try testing.expect(q.popFirst().? == MI.anchor(&m1));
    try testing.expect(next(MI.anchor(&m1)).* == null);
    try testing.expect(q.popFirst().? == MI.anchor(&m2));
    try testing.expect(next(MI.anchor(&m2)).* == null);
    try testing.expect(q.popFirst() == null);
}

test "the uniform offset holds" {
    std.testing.log_level = .debug;

    try testing.expect(container.uniform_next_offset != null);
}

test "ids are distinct; TypeInfo fields and calls" {
    std.testing.log_level = .debug;

    try testing.expect(MI.typeId() != JI.typeId());

    var m: Msg = .{ .text = "x" };
    MI.stamp(&m);
    const a: *Anchor = MI.anchor(&m);
    try testing.expect(a.typeId() == MI.typeId());

    const i: *const TypeInfo = a.info().?;
    try testing.expect(i.*.node_kind == .single);
    try testing.expectEqualStrings(@typeName(Msg), i.*.name);
    try testing.expect(i.parent(a) == @as(*anyopaque, &m));
    try testing.expect(i.node(a, std.SinglyLinkedList.Node) == MI.node(&m));
}

test "Anchor.typeId is null when unstamped, the type's id when stamped" {
    std.testing.log_level = .debug;

    var j: Job = .{ .id = 1 };
    try testing.expect(JI.anchor(&j).typeId() == null);
    JI.stamp(&j);
    try testing.expect(JI.anchor(&j).typeId() == JI.typeId());
}

test "two types with one name have two TypeIds" {
    std.testing.log_level = .debug;

    const A: type = msg_one.Msg;
    const B: type = msg_two.Msg;
    const AI: type = paternitas.Info(A);
    const BI: type = paternitas.Info(B);

    // The precondition: the two names are equal.
    try testing.expectEqualStrings(@typeName(A), @typeName(B));

    // Compared at run time. A comparison folded at comptime cannot see a
    // merge the linker does later.
    var ids: [2]TypeId = .{ AI.typeId(), BI.typeId() };
    std.mem.doNotOptimizeAway(&ids);
    try testing.expect(ids[0] != ids[1]);

    var b: B = .{};
    BI.stamp(&b);
    var a: *Anchor = BI.anchor(&b);
    std.mem.doNotOptimizeAway(&a);
    try testing.expect(AI.fromAnchor(a) == null);
    try testing.expect(BI.fromAnchor(a).? == &b);
}

test "SLink and DLink Parents in one Anchor chain, then a std list" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "hi" };
    var j: Job = .{ .id = 42 };
    MI.stamp(&m);
    JI.stamp(&j);

    var q: Chain = .{};
    q.append(MI.anchor(&m));
    q.append(JI.anchor(&j));
    const a: *Anchor = q.popFirst().?;
    const b: *Anchor = q.popFirst().?;
    try testing.expect(MI.fromAnchor(a).? == &m);
    try testing.expect(JI.fromAnchor(a) == null);
    try testing.expect(JI.fromAnchor(b).?.*.id == 42);

    var list: std.DoublyLinkedList = .{};
    list.append(JI.node(&j));
    const n: *std.DoublyLinkedList.Node = list.popFirst().?;
    try testing.expect(JI.parentFromNode(n).? == &j);
}

test "unstamped" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "x" };
    try testing.expect(!MI.is(MI.node(&m)));
    try testing.expect(MI.parentFromNode(MI.node(&m)) == null);
    try testing.expect(MI.fromAnchor(MI.anchor(&m)) == null);
    try testing.expect(MI.anchor(&m).info() == null);
    try testing.expectEqualStrings("<unstamped>", MI.anchor(&m).typeName());
}

test "stamp leaves a linked Node intact" {
    std.testing.log_level = .debug;

    var j1: Job = .{ .id = 1 };
    var j2: Job = .{ .id = 2 };
    var list: std.DoublyLinkedList = .{};
    list.append(JI.node(&j1));
    list.append(JI.node(&j2));
    JI.stamp(&j1);
    JI.stamp(&j2);
    try testing.expect(JI.parentFromNode(list.popFirst().?).?.*.id == 1);
    try testing.expect(JI.parentFromNode(list.popFirst().?).?.*.id == 2);
}

test "is, isId and parentFromNodeUnchecked on a stamped Parent" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "x" };
    var j: Job = .{ .id = 3 };
    MI.stamp(&m);
    JI.stamp(&j);

    const mn: *const std.SinglyLinkedList.Node = MI.node(&m);
    try testing.expect(MI.is(mn));
    try testing.expect(JI.is(JI.node(&j)));

    try testing.expect(MI.isId(MI.typeId()));
    try testing.expect(!MI.isId(JI.typeId()));
    try testing.expect(!MI.isId(null));

    try testing.expect(MI.parentFromNodeUnchecked(MI.node(&m)) == &m);
    try testing.expect(JI.parentFromNodeUnchecked(JI.node(&j)) == &j);
}

test "mustFromAnchor and mustParentFromNode return the Parent on a match" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "x" };
    var j: Job = .{ .id = 4 };
    MI.stamp(&m);
    JI.stamp(&j);

    try testing.expect(MI.mustFromAnchor(MI.anchor(&m)) == &m);
    try testing.expect(JI.mustFromAnchor(JI.anchor(&j)) == &j);
    try testing.expect(MI.mustParentFromNode(MI.node(&m)) == &m);
    try testing.expect(JI.mustParentFromNode(JI.node(&j)) == &j);
}

test "typeName of a stamped Anchor" {
    std.testing.log_level = .debug;

    var j: Job = .{ .id = 5 };
    JI.stamp(&j);
    try testing.expectEqualStrings(@typeName(Job), JI.anchor(&j).typeName());
}

test "TypeInfo.node for a DLink Parent" {
    std.testing.log_level = .debug;

    var j: Job = .{ .id = 6 };
    JI.stamp(&j);
    const a: *Anchor = JI.anchor(&j);
    const i: *const TypeInfo = a.info().?;
    try testing.expect(i.*.node_kind == .double);
    try testing.expect(i.node(a, std.DoublyLinkedList.Node) == JI.node(&j));
}

test "AnyParent dispatch through a map, no Info call at dispatch" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "hi" };
    var j: Job = .{ .id = 42 };
    MI.stamp(&m);
    JI.stamp(&j);

    const H: type = struct {
        var seen_msg: ?*Msg = null;
        var seen_job: u32 = 0;

        fn onMsg(p: *anyopaque) void {
            seen_msg = @ptrCast(@alignCast(p));
        }

        fn onJob(p: *anyopaque) void {
            const jj: *Job = @ptrCast(@alignCast(p));
            seen_job = jj.*.id;
        }
    };

    const Handler: type = *const fn (*anyopaque) void;
    var map: std.AutoHashMap(TypeId, Handler) = .init(testing.allocator);
    defer map.deinit();
    try map.put(MI.typeId(), H.onMsg);
    try map.put(JI.typeId(), H.onJob);

    var q: Chain = .{};
    q.append(MI.anchor(&m));
    q.append(JI.anchor(&j));
    while (q.popFirst()) |a| {
        const any: AnyParent = a.toAny().?;
        const h: Handler = map.get(any.type_id).?;
        h(any.ptr);
    }
    try testing.expect(H.seen_msg.? == &m);
    try testing.expect(H.seen_job == 42);
}

test "toAny and fromAny" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "x" };
    MI.stamp(&m);
    const any: AnyParent = MI.toAny(&m);
    try testing.expect(MI.fromAny(any).? == &m);
    try testing.expect(JI.fromAny(any) == null);

    const via: AnyParent = MI.anchor(&m).toAny().?;
    try testing.expect(via.ptr == any.ptr and via.type_id == any.type_id);

    var unstamped: Msg = .{ .text = "y" };
    try testing.expect(MI.anchor(&unstamped).toAny() == null);
}

test "*Anchor and AnyParent in a tagged union" {
    std.testing.log_level = .debug;

    const Event: type = union(enum) { tick: u64, anchor: *Anchor, view: AnyParent };

    var m: Msg = .{ .text = "x" };
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

test "the stored offset finds next for both kinds, and so does nextField" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "x" };
    var j: Job = .{ .id = 1 };
    MI.stamp(&m);
    JI.stamp(&j);

    const ma: *Anchor = MI.anchor(&m);
    const ja: *Anchor = JI.anchor(&j);
    const mi: *const TypeInfo = ma.info().?;
    const ji: *const TypeInfo = ja.info().?;
    const m_next: usize = @intFromPtr(&MI.node(&m).*.next);
    const j_next: usize = @intFromPtr(&JI.node(&j).*.next);

    // The fallback step of nextField, with the stored offset.
    try testing.expect(@intFromPtr(container._nextFieldAt(ma, mi.*.node_next_offset)) == m_next);
    try testing.expect(@intFromPtr(container._nextFieldAt(ja, ji.*.node_next_offset)) == j_next);

    try testing.expect(@intFromPtr(mi.nextField(ma)) == m_next);
    try testing.expect(@intFromPtr(ji.nextField(ja)) == j_next);
}

const paternitas = @import("paternitas");
const container = paternitas.container;
const Anchor = paternitas.Anchor;
const AnyParent = paternitas.AnyParent;
const TypeId = paternitas.TypeId;
const TypeInfo = container.TypeInfo;
const msg_one = @import("msg_one");
const msg_two = @import("msg_two");
const testing = std.testing;
const std = @import("std");
