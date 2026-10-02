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

    var tally: Tally = .{};
    for (received) |a| try dispatch(&handlers, a, &tally);

    if (tally.messages != 1 or tally.jobs != 1 or tally.unhandled != 1) return error.WrongCount;

    try checkedForm(&message);
}

/// The dispatch step. No Parent type appears here.
fn dispatch(handlers: *const std.AutoHashMap(paternitas.TypeId, Handler), a: *paternitas.Anchor, tally: *Tally) !void {
    const any: paternitas.AnyParent = a.toAny() orelse return error.Unstamped;
    const h: Handler = handlers.get(any.type_id) orelse {
        std.log.info("no handler for {s}", .{paternitas.nameOf(a)});
        tally.*.unhandled += 1;
        return;
    };
    h(any.ptr, tally);
}

/// `fromAny` compares the id first. A view of another type gives null.
fn checkedForm(message: *Message) !void {
    const any: paternitas.AnyParent = MessageInfo.toAny(message);
    if (MessageInfo.fromAny(any) != message) return error.WrongParent;
    if (JobInfo.fromAny(any) != null) return error.WrongParent;
}

const Tally: type = struct {
    messages: usize = 0,
    jobs: usize = 0,
    unhandled: usize = 0,
};

const Handler: type = *const fn (parent: *anyopaque, tally: *Tally) void;

// The cast is unchecked. The map matched the id, so it is correct by
// registration.
fn onMessage(parent: *anyopaque, tally: *Tally) void {
    const m: *Message = @ptrCast(@alignCast(parent));
    std.log.info("message: {s}", .{m.*.text});
    tally.*.messages += 1;
}

fn onJob(parent: *anyopaque, tally: *Tally) void {
    const j: *Job = @ptrCast(@alignCast(parent));
    std.log.info("job: {d}", .{j.*.id});
    tally.*.jobs += 1;
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
