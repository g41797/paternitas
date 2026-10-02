//! Dispatch through a `TypeId -> handler` map, with no `Info` call at dispatch.
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

pub fn handler_map(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = io;

    var handlers: std.AutoHashMap(paternitas.TypeId, Handler) = .init(allocator);
    defer handlers.deinit();

    // Registration: the only `Info` calls.
    try handlers.put(MessageInfo.typeId(), onMessage);
    try handlers.put(JobInfo.typeId(), onJob);

    var message: Message = .{ .text = "hello" };
    var job: Job = .{ .id = 42 };
    var ping: Ping = .{};
    MessageInfo.stamp(&message);
    JobInfo.stamp(&job);
    PingInfo.stamp(&ping);

    const received: [3]*paternitas.Anchor = .{
        MessageInfo.anchor(&message),
        JobInfo.anchor(&job),
        PingInfo.anchor(&ping),
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
    const any: paternitas.AnyParent = MessageInfo.toAny(message);
    if (MessageInfo.fromAny(any) != message) return error.WrongParent;
    if (JobInfo.fromAny(any) != null) return error.WrongParent;
}

const Counts: type = struct {
    messages: usize = 0,
    jobs: usize = 0,
    unhandled: usize = 0,
};

const Handler: type = *const fn (parent: *anyopaque, counts: *Counts) void;

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

const Message: type = struct {
    text: []const u8,
    link: paternitas.SLink = .{},
};

const Job: type = struct {
    link: paternitas.DLink = .{},
    id: u32,
};

const Ping: type = struct {
    link: paternitas.SLink = .{},
};

const MessageInfo: type = paternitas.Info(Message);
const JobInfo: type = paternitas.Info(Job);
const PingInfo: type = paternitas.Info(Ping);

const paternitas = @import("paternitas");
const std = @import("std");
