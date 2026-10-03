//! Tests of the paternitas module.

const Msg: type = struct { text: []const u8, tnode: paternitas.SinglyTypedNode = .{} };
const Job: type = struct { tnode: paternitas.DoublyTypedNode = .{}, id: u32, extra: u64 = 7 };
const TypedMsg: type = paternitas.Typed(Msg);
const TypedJob: type = paternitas.Typed(Job);

fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}

// The chain word of an Anchor, typed as this chain keeps it.
fn next(a: *Anchor) *?*Anchor {
    const ti: *const TypeInfo = a.info() orelse @panic("chain: no type");
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
    TypedMsg.setTypeId(&m1);
    TypedMsg.setTypeId(&m2);

    var q: Chain = .{};
    q.append(TypedMsg.anchor(&m1));
    try testing.expect(next(TypedMsg.anchor(&m1)).*.? == TypedMsg.anchor(&m1));
    q.append(TypedMsg.anchor(&m2));
    try testing.expect(next(TypedMsg.anchor(&m1)).*.? == TypedMsg.anchor(&m2));
    try testing.expect(next(TypedMsg.anchor(&m2)).*.? == TypedMsg.anchor(&m2));

    try testing.expect(q.popFirst().? == TypedMsg.anchor(&m1));
    try testing.expect(next(TypedMsg.anchor(&m1)).* == null);
    try testing.expect(q.popFirst().? == TypedMsg.anchor(&m2));
    try testing.expect(next(TypedMsg.anchor(&m2)).* == null);
    try testing.expect(q.popFirst() == null);
}

test "the uniform offset holds" {
    std.testing.log_level = .debug;

    try testing.expect(container.uniform_next_offset != null);
}

test "ids are distinct; TypeInfo fields and calls" {
    std.testing.log_level = .debug;

    try testing.expect(TypedMsg.typeId() != TypedJob.typeId());

    var m: Msg = .{ .text = "x" };
    TypedMsg.setTypeId(&m);
    const a: *Anchor = TypedMsg.anchor(&m);
    try testing.expect(a.typeId() == TypedMsg.typeId());

    const i: *const TypeInfo = a.info().?;
    try testing.expect(i.*.node_kind == .single);
    try testing.expectEqualStrings(@typeName(Msg), i.*.name);
    try testing.expect(i.parent(a) == @as(*anyopaque, &m));
    try testing.expect(i.node(a, std.SinglyLinkedList.Node) == TypedMsg.node(&m));
}

test "Anchor.typeId is null before setTypeId, the type's id after" {
    std.testing.log_level = .debug;

    var j: Job = .{ .id = 1 };
    try testing.expect(TypedJob.anchor(&j).typeId() == null);
    TypedJob.setTypeId(&j);
    try testing.expect(TypedJob.anchor(&j).typeId() == TypedJob.typeId());
}

test "two types with one name have two TypeIds" {
    std.testing.log_level = .debug;

    const A: type = msg_one.Msg;
    const B: type = msg_two.Msg;
    const TypedA: type = paternitas.Typed(A);
    const TypedB: type = paternitas.Typed(B);

    // The precondition: the two names are equal.
    try testing.expectEqualStrings(@typeName(A), @typeName(B));

    // Compared at run time. A comparison folded at comptime cannot see a
    // merge the linker does later.
    var ids: [2]TypeId = .{ TypedA.typeId(), TypedB.typeId() };
    std.mem.doNotOptimizeAway(&ids);
    try testing.expect(ids[0] != ids[1]);

    var b: B = .{};
    TypedB.setTypeId(&b);
    var a: *Anchor = TypedB.anchor(&b);
    std.mem.doNotOptimizeAway(&a);
    try testing.expect(TypedA.parentFromAnchor(a) == null);
    try testing.expect(TypedB.parentFromAnchor(a).? == &b);
}

test "SinglyTypedNode and DoublyTypedNode Parents in one Anchor chain, then a std list" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "hi" };
    var j: Job = .{ .id = 42 };
    TypedMsg.setTypeId(&m);
    TypedJob.setTypeId(&j);

    var q: Chain = .{};
    q.append(TypedMsg.anchor(&m));
    q.append(TypedJob.anchor(&j));
    const a: *Anchor = q.popFirst().?;
    const b: *Anchor = q.popFirst().?;
    try testing.expect(TypedMsg.parentFromAnchor(a).? == &m);
    try testing.expect(TypedJob.parentFromAnchor(a) == null);
    try testing.expect(TypedJob.parentFromAnchor(b).?.*.id == 42);

    var list: std.DoublyLinkedList = .{};
    list.append(TypedJob.node(&j));
    const n: *std.DoublyLinkedList.Node = list.popFirst().?;
    try testing.expect(TypedJob.parentFromNode(n).? == &j);
}

test "without setTypeId, every check returns null or false" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "x" };
    try testing.expect(!TypedMsg.is(TypedMsg.node(&m)));
    try testing.expect(TypedMsg.parentFromNode(TypedMsg.node(&m)) == null);
    try testing.expect(TypedMsg.parentFromAnchor(TypedMsg.anchor(&m)) == null);
    try testing.expect(TypedMsg.anchor(&m).info() == null);
    try testing.expectEqualStrings("<no type>", TypedMsg.anchor(&m).typeName());
}

test "setTypeId leaves a linked Node intact" {
    std.testing.log_level = .debug;

    var j1: Job = .{ .id = 1 };
    var j2: Job = .{ .id = 2 };
    var list: std.DoublyLinkedList = .{};
    list.append(TypedJob.node(&j1));
    list.append(TypedJob.node(&j2));
    TypedJob.setTypeId(&j1);
    TypedJob.setTypeId(&j2);
    try testing.expect(TypedJob.parentFromNode(list.popFirst().?).?.*.id == 1);
    try testing.expect(TypedJob.parentFromNode(list.popFirst().?).?.*.id == 2);
}

test "is, isId and parentFromNodeUnchecked after setTypeId" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "x" };
    var j: Job = .{ .id = 3 };
    TypedMsg.setTypeId(&m);
    TypedJob.setTypeId(&j);

    const m_node: *const std.SinglyLinkedList.Node = TypedMsg.node(&m);
    try testing.expect(TypedMsg.is(m_node));
    try testing.expect(TypedJob.is(TypedJob.node(&j)));

    try testing.expect(TypedMsg.isId(TypedMsg.typeId()));
    try testing.expect(!TypedMsg.isId(TypedJob.typeId()));
    try testing.expect(!TypedMsg.isId(null));

    try testing.expect(TypedMsg.parentFromNodeUnchecked(TypedMsg.node(&m)) == &m);
    try testing.expect(TypedJob.parentFromNodeUnchecked(TypedJob.node(&j)) == &j);
}

test "mustParentFromAnchor and mustParentFromNode return the Parent on a match" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "x" };
    var j: Job = .{ .id = 4 };
    TypedMsg.setTypeId(&m);
    TypedJob.setTypeId(&j);

    try testing.expect(TypedMsg.mustParentFromAnchor(TypedMsg.anchor(&m)) == &m);
    try testing.expect(TypedJob.mustParentFromAnchor(TypedJob.anchor(&j)) == &j);
    try testing.expect(TypedMsg.mustParentFromNode(TypedMsg.node(&m)) == &m);
    try testing.expect(TypedJob.mustParentFromNode(TypedJob.node(&j)) == &j);
}

test "typeName after setTypeId" {
    std.testing.log_level = .debug;

    var j: Job = .{ .id = 5 };
    TypedJob.setTypeId(&j);
    try testing.expectEqualStrings(@typeName(Job), TypedJob.anchor(&j).typeName());
}

test "TypeInfo.node for a DoublyTypedNode Parent" {
    std.testing.log_level = .debug;

    var j: Job = .{ .id = 6 };
    TypedJob.setTypeId(&j);
    const a: *Anchor = TypedJob.anchor(&j);
    const i: *const TypeInfo = a.info().?;
    try testing.expect(i.*.node_kind == .double);
    try testing.expect(i.node(a, std.DoublyLinkedList.Node) == TypedJob.node(&j));
}

test "AnyParent dispatch through a map, no Typed call at dispatch" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "hi" };
    var j: Job = .{ .id = 42 };
    TypedMsg.setTypeId(&m);
    TypedJob.setTypeId(&j);

    const Handlers: type = struct {
        var seen_msg: ?*Msg = null;
        var seen_job: u32 = 0;

        fn onMsg(p: *anyopaque) void {
            seen_msg = @ptrCast(@alignCast(p));
        }

        fn onJob(p: *anyopaque) void {
            const job: *Job = @ptrCast(@alignCast(p));
            seen_job = job.*.id;
        }
    };

    const Handler: type = *const fn (*anyopaque) void;
    var map: std.AutoHashMap(TypeId, Handler) = .init(testing.allocator);
    defer map.deinit();
    try map.put(TypedMsg.typeId(), Handlers.onMsg);
    try map.put(TypedJob.typeId(), Handlers.onJob);

    var q: Chain = .{};
    q.append(TypedMsg.anchor(&m));
    q.append(TypedJob.anchor(&j));
    while (q.popFirst()) |a| {
        const any: AnyParent = a.toAny().?;
        const h: Handler = map.get(any.type_id).?;
        h(any.ptr);
    }
    try testing.expect(Handlers.seen_msg.? == &m);
    try testing.expect(Handlers.seen_job == 42);
}

test "toAny and fromAny" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "x" };
    TypedMsg.setTypeId(&m);
    const any: AnyParent = TypedMsg.toAny(&m);
    try testing.expect(TypedMsg.fromAny(any).? == &m);
    try testing.expect(TypedJob.fromAny(any) == null);

    const from_anchor: AnyParent = TypedMsg.anchor(&m).toAny().?;
    try testing.expect(from_anchor.ptr == any.ptr and from_anchor.type_id == any.type_id);

    var no_type: Msg = .{ .text = "y" };
    try testing.expect(TypedMsg.anchor(&no_type).toAny() == null);
}

test "*Anchor and AnyParent in a tagged union" {
    std.testing.log_level = .debug;

    const Event: type = union(enum) { tick: u64, anchor: *Anchor, view: AnyParent };

    var m: Msg = .{ .text = "x" };
    TypedMsg.setTypeId(&m);
    const events: [3]Event = .{ .{ .tick = 1 }, .{ .anchor = TypedMsg.anchor(&m) }, .{ .view = TypedMsg.toAny(&m) } };

    var hits: u32 = 0;
    for (events) |e| switch (e) {
        .tick => {},
        .anchor => |a| hits += @intFromBool(TypedMsg.parentFromAnchor(a) != null),
        .view => |v| hits += @intFromBool(TypedMsg.fromAny(v) != null),
    };
    try testing.expectEqual(@as(u32, 2), hits);
}

test "the stored offset finds next for both kinds, and so does nextField" {
    std.testing.log_level = .debug;

    var m: Msg = .{ .text = "x" };
    var j: Job = .{ .id = 1 };
    TypedMsg.setTypeId(&m);
    TypedJob.setTypeId(&j);

    const m_anchor: *Anchor = TypedMsg.anchor(&m);
    const j_anchor: *Anchor = TypedJob.anchor(&j);
    const m_info: *const TypeInfo = m_anchor.info().?;
    const j_info: *const TypeInfo = j_anchor.info().?;
    const m_next: usize = @intFromPtr(&TypedMsg.node(&m).*.next);
    const j_next: usize = @intFromPtr(&TypedJob.node(&j).*.next);

    // The fallback step of nextField, with the stored offset.
    try testing.expect(@intFromPtr(container._nextFieldAt(m_anchor, m_info.*.node_next_offset)) == m_next);
    try testing.expect(@intFromPtr(container._nextFieldAt(j_anchor, j_info.*.node_next_offset)) == j_next);

    try testing.expect(@intFromPtr(m_info.nextField(m_anchor)) == m_next);
    try testing.expect(@intFromPtr(j_info.nextField(j_anchor)) == j_next);
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
