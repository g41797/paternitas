//! Title: Type id without a node
//!
//! A handler map for structs that have no TypedNode.
//!
//! ### When you need it
//!
//! Your struct is not on a list. It has no room for a node, or you do not
//! want one.
//!
//! You still want a runtime type id for it. Callbacks, queues and handler
//! maps all need one.
//!
//! ### What it does
//!
//! - Register one handler per type, under its `typeId`.
//! - Send a `Point`, a `Tick` and an `Empty` as `Any`s.
//! - Find the handler by `type_id`. No list. The loop does not use your struct types.
//! - Count the `Empty` as unhandled. It has no handler.
//! - Check with `isId` which type an `Any` holds.
//! - Get a `Point` back from an `Any` with `fromAny`.
//!
//! ### What to notice
//!
//! The structs have no TypedNode. The id lives in the `Any`, not in the
//! struct. So a bare pointer carries no id.
//!
//! `Empty` has no fields, and it still gets its own id.

// --8<-- [start:types]
const Point: type = struct {
    x: i32,
    y: i32,
};
const TypedPoint: type = paternitas.Typed(Point);

const Tick: type = struct {
    count: u64,
    label: []const u8,
};
const TypedTick: type = paternitas.Typed(Tick);
// --8<-- [end:types]

const Empty: type = struct {};
const TypedEmpty: type = paternitas.Typed(Empty);

const Counts: type = struct {
    points: usize = 0,
    ticks: usize = 0,
    unhandled: usize = 0,
};

const Handler: type = *const fn (ptr: *anyopaque, counts: *Counts) void;

pub fn type_id_without_node(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = io;

    var handlers: std.AutoHashMap(paternitas.TypeId, Handler) = .init(allocator);
    defer handlers.deinit();

    // Register the handlers. The dispatch code does not use your struct types.
    // --8<-- [start:send]
    try handlers.put(TypedPoint.typeId(), onPoint);
    try handlers.put(TypedTick.typeId(), onTick);

    var point: Point = .{ .x = 3, .y = 4 };
    var tick: Tick = .{ .count = 7, .label = "tick" };
    var empty: Empty = .{};

    const items: [3]paternitas.Any = .{
        TypedPoint.toAny(&point),
        TypedTick.toAny(&tick),
        TypedEmpty.toAny(&empty),
    };

    var counts: Counts = .{};
    for (items) |any| dispatch(&handlers, any, &counts);
    // --8<-- [end:send]
    if (counts.points != 1 or counts.ticks != 1 or counts.unhandled != 1) return error.WrongCount;

    try checkIsId(items[0]);
    try checkFromAny(&point, items[0]);
}

/// Picks the handler by type id. No struct type appears here.
fn dispatch(handlers: *const std.AutoHashMap(paternitas.TypeId, Handler), any: paternitas.Any, counts: *Counts) void {
    const h: Handler = handlers.get(any.type_id) orelse {
        std.log.info("no handler for this type", .{});
        counts.*.unhandled += 1;
        return;
    };
    h(any.ptr, counts);
}

// --8<-- [start:isid]
/// `isId` asks about one type. It is true for that type only.
fn checkIsId(any: paternitas.Any) !void {
    if (!TypedPoint.isId(any.type_id)) return error.WrongId;
    if (TypedTick.isId(any.type_id)) return error.WrongId;
}
// --8<-- [end:isid]

/// `fromAny` checks the type id first. Asking for another type gives null.
fn checkFromAny(point: *Point, any: paternitas.Any) !void {
    if (TypedPoint.fromAny(any) != point) return error.WrongParent;
    if (TypedTick.fromAny(any) != null) return error.WrongParent;
}

// The cast has no check. The map matched the type id, so the type is
// right.
fn onPoint(ptr: *anyopaque, counts: *Counts) void {
    const p: *Point = @ptrCast(@alignCast(ptr));
    std.log.info("point: {d},{d}", .{ p.*.x, p.*.y });
    counts.*.points += 1;
}

fn onTick(ptr: *anyopaque, counts: *Counts) void {
    const t: *Tick = @ptrCast(@alignCast(ptr));
    std.log.info("tick: {d} {s}", .{ t.*.count, t.*.label });
    counts.*.ticks += 1;
}

const paternitas = @import("paternitas");
const std = @import("std");
