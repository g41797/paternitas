//! Dispatch through a `TypeId -> handler` map, with no `Typed` call at dispatch.
//!
//! The consumer keeps a map.
//! Each handler knows its own Parent type.
//! Picking a handler needs no paternitas call.
//!
//! - register one handler per Parent type, under its `TypeId`
//! - receive a `Message`, a `Job` and a `Ping` as `*Anchor`s
//! - turn each `*Anchor` into an `AnyParent` with `toAny`
//! - find the handler by `type_id`, and call it with `ptr`
//! - count the `Ping`: no handler is registered for it
//! - check one view with `fromAny`, the checked form

const Message: type = struct {
    text: []const u8,
    link: paternitas.SLink = .{},
};
const TypedMessage: type = paternitas.Typed(Message);

const Job: type = struct {
    link: paternitas.DLink = .{},
    id: u32,
};
const TypedJob: type = paternitas.Typed(Job);

const Ping: type = struct {
    link: paternitas.SLink = .{},
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

    // Registration: the only `Typed` calls.
    try handlers.put(TypedMessage.typeId(), onMessage);
    try handlers.put(TypedJob.typeId(), onJob);

    var message: Message = .{ .text = "hello" };
    var job: Job = .{ .id = 42 };
    var ping: Ping = .{};
    TypedMessage.stamp(&message);
    TypedJob.stamp(&job);
    TypedPing.stamp(&ping);

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

/// The dispatch step. No Parent type appears here.
fn dispatch(handlers: *const std.AutoHashMap(paternitas.TypeId, Handler), a: *paternitas.Anchor, counts: *Counts) !void {
    const any: paternitas.AnyParent = a.toAny() orelse return error.Unstamped;
    const h: Handler = handlers.get(any.type_id) orelse {
        std.log.info("no handler for {s}", .{a.typeName()});
        counts.*.unhandled += 1;
        return;
    };
    h(any.ptr, counts);
}

/// `fromAny` compares the id first. A view of another type gives null.
fn checkFromAny(message: *Message) !void {
    const any: paternitas.AnyParent = TypedMessage.toAny(message);
    if (TypedMessage.fromAny(any) != message) return error.WrongParent;
    if (TypedJob.fromAny(any) != null) return error.WrongParent;
}

// The cast is unchecked. The map matched the id, so it is correct by
// registration.
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
