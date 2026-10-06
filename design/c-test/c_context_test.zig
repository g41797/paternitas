//! The C-callback scenario from design 014, "C code: findings".
//!
//! Zig only, no libc. A `callconv(.c)` callback takes a `?*anyopaque`
//! context and is called through a function pointer, as a C library would
//! call it. A record, not advice.

const Job: type = struct { tnode: paternitas.DoublyTypedNode = .{}, id: u32 };
const TypedJob: type = paternitas.Typed(Job);
const Msg: type = struct { tnode: paternitas.SinglyTypedNode = .{}, id: u32 };
const TypedMsg: type = paternitas.Typed(Msg);
const Point: type = struct { x: u32, y: u32 }; // no TypedNode
const TypedPoint: type = paternitas.Typed(Point);
const Tick: type = struct { n: u32 }; // no TypedNode
const TypedTick: type = paternitas.Typed(Tick);

// What a C callback looks like: a function pointer and a void* context.
const Callback: type = *const fn (ctx: ?*anyopaque) callconv(.c) u32;

// Stands in for a C library: it keeps the context and calls back later.
const FakeC: type = struct {
    cb: Callback,
    ctx: ?*anyopaque,

    fn callBack(c: *const FakeC) u32 {
        return c.*.cb(c.*.ctx);
    }
};

// The context is a *Anchor. Returns the Job's id, or 0 for another type.
fn onJobAnchor(ctx: ?*anyopaque) callconv(.c) u32 {
    const a: *Anchor = @ptrCast(@alignCast(ctx.?));
    const j: *Job = TypedJob.parentFromAnchor(a) orelse return 0;
    return j.*.id;
}

// The context is a *Any. Returns x + y of the Point, or 0 for another type.
fn onPointAny(ctx: ?*anyopaque) callconv(.c) u32 {
    const any: *const Any = @ptrCast(@alignCast(ctx.?));
    const p: *Point = TypedPoint.fromAny(any.*) orelse return 0;
    return p.*.x + p.*.y;
}

test "a *Anchor through a C callback's context comes back as the Parent" {
    var job: Job = .{ .id = 42 };
    TypedJob.setTypeId(&job);

    // The function pointer is a var, so the call is not folded away.
    var cb: Callback = &onJobAnchor;
    _ = &cb;
    const c: FakeC = .{ .cb = cb, .ctx = TypedJob.anchor(&job) };
    try testing.expectEqual(@as(u32, 42), c.callBack());
}

test "a *Anchor of another type gives null in the callback" {
    var msg: Msg = .{ .id = 7 };
    TypedMsg.setTypeId(&msg);

    var cb: Callback = &onJobAnchor;
    _ = &cb;
    const c: FakeC = .{ .cb = cb, .ctx = TypedMsg.anchor(&msg) };
    try testing.expectEqual(@as(u32, 0), c.callBack());
}

test "a *Anchor without setTypeId gives null in the callback" {
    var job: Job = .{ .id = 42 };

    var cb: Callback = &onJobAnchor;
    _ = &cb;
    const c: FakeC = .{ .cb = cb, .ctx = TypedJob.anchor(&job) };
    try testing.expectEqual(@as(u32, 0), c.callBack());
}

test "a *Any of a struct with no TypedNode comes back through the callback" {
    var pt: Point = .{ .x = 3, .y = 4 };
    // The Any must outlive the callback: C keeps only its address.
    var any: Any = TypedPoint.toAny(&pt);

    var cb: Callback = &onPointAny;
    _ = &cb;
    const c: FakeC = .{ .cb = cb, .ctx = &any };
    try testing.expectEqual(@as(u32, 7), c.callBack());
}

test "a *Any of another type gives null in the callback" {
    var tick: Tick = .{ .n = 9 };
    var any: Any = TypedTick.toAny(&tick);

    var cb: Callback = &onPointAny;
    _ = &cb;
    const c: FakeC = .{ .cb = cb, .ctx = &any };
    try testing.expectEqual(@as(u32, 0), c.callBack());
}

const std = @import("std");
const testing = std.testing;
const paternitas = @import("paternitas");
const Anchor = paternitas.Anchor;
const Any = paternitas.Any;
