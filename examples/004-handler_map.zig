//! Pick a handler by type, with a map from type id to handler.
//!
//! An event loop gets items of many types as `*Anchor`s.
//! It keeps one handler per type in a map, keyed by `TypeId`.
//! Picking the handler needs only the type id, not the type itself.
//!
//! - Register one handler per type, under its `TypeId`.
//! - Receive a `Message`, a `Job` and a `Ping` as `*Anchor`s.
//! - Turn each `*Anchor` into an `AnyParent` with `toAny`.
//! - Find the handler by `type_id`, and call it with `ptr`.
//! - Count the `Ping` as unhandled. No handler is registered for it.
//! - Get a `Message` back from an `AnyParent` with `fromAny`, which checks the type.

const Message: type = struct {
    text: []const u8,
    tnode: paternitas.SinglyTypedNode = .{},
};
const TypedMessage: type = paternitas.Typed(Message);

const Job: type = struct {
    tnode: paternitas.DoublyTypedNode = .{},
    id: u32,
};
const TypedJob: type = paternitas.Typed(Job);

const Ping: type = struct {
    tnode: paternitas.SinglyTypedNode = .{},
};
const TypedPing: type = paternitas.Typed(Ping);

const Counts: type = struct {
    messages: usize = 0,
    jobs: usize = 0,
    unhandled: usize = 0,
};

const Handler: type = *const fn (parent: *anyopaque, counts: *Counts) void;

pub fn handler_map(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = io;

    var handlers: std.AutoHashMap(paternitas.TypeId, Handler) = .init(allocator);
    defer handlers.deinit();

    // Register the handlers. The dispatch below never names a type.
    try handlers.put(TypedMessage.typeId(), onMessage);
    try handlers.put(TypedJob.typeId(), onJob);

    var message: Message = .{ .text = "hello" };
    var job: Job = .{ .id = 42 };
    var ping: Ping = .{};
    TypedMessage.setTypeId(&message);
    TypedJob.setTypeId(&job);
    TypedPing.setTypeId(&ping);

    const received: [3]*paternitas.Anchor = .{
        TypedMessage.anchor(&message),
        TypedJob.anchor(&job),
        TypedPing.anchor(&ping),
    };

    var counts: Counts = .{};
    for (received) |a| try dispatch(&handlers, a, &counts);

    if (counts.messages != 1 or counts.jobs != 1 or counts.unhandled != 1) return error.WrongCount;

    try checkFromAny(&message);
}

/// Picks the handler by type id. No struct type appears here.
fn dispatch(handlers: *const std.AutoHashMap(paternitas.TypeId, Handler), a: *paternitas.Anchor, counts: *Counts) !void {
    const any: paternitas.AnyParent = a.toAny() orelse return error.NoTypeId;
    const h: Handler = handlers.get(any.type_id) orelse {
        std.log.info("no handler for {s}", .{a.typeName()});
        counts.*.unhandled += 1;
        return;
    };
    h(any.ptr, counts);
}

/// `fromAny` checks the type id first. Asking for another type gives null.
fn checkFromAny(message: *Message) !void {
    const any: paternitas.AnyParent = TypedMessage.toAny(message);
    if (TypedMessage.fromAny(any) != message) return error.WrongParent;
    if (TypedJob.fromAny(any) != null) return error.WrongParent;
}

// The cast has no check. The map matched the type id, so the type is
// right.
fn onMessage(parent: *anyopaque, counts: *Counts) void {
    const m: *Message = @ptrCast(@alignCast(parent));
    std.log.info("message: {s}", .{m.*.text});
    counts.*.messages += 1;
}

fn onJob(parent: *anyopaque, counts: *Counts) void {
    const j: *Job = @ptrCast(@alignCast(parent));
    std.log.info("job: {d}", .{j.*.id});
    counts.*.jobs += 1;
}

const paternitas = @import("paternitas");
const std = @import("std");
