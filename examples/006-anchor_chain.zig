//! A stack chained through `TypeInfo.nextField`, for container authors.
//!
//! The chain word is the Node's `next`.
//! paternitas says where it is. The container decides what goes in it.
//!
//! - a `Stack` keeps `*Anchor`s, chained through each Anchor's `next` word
//! - push an `SLink` Parent and a `DLink` Parent: one chain, two Node kinds
//! - pop each, and recover it with `fromAnchor`
//! - check the order, and that each chain word is null again
//!
//! The `next` word is shared with the std lists.
//! A Parent on this stack is in no std list.
//!
//! ```
//!  top --> job.anchor --next--> message.anchor --next--> null
//! ```

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

/// A last-in, first-out stack of Anchors. It allocates nothing.
const Stack: type = struct {
    top: ?*paternitas.Anchor = null,

    fn push(s: *Stack, a: *paternitas.Anchor) !void {
        const word: *?*paternitas.Anchor = try chainWord(a);
        word.* = s.*.top;
        s.*.top = a;
    }

    fn pop(s: *Stack) !?*paternitas.Anchor {
        const a: *paternitas.Anchor = s.*.top orelse return null;
        const word: *?*paternitas.Anchor = try chainWord(a);
        s.*.top = word.*;
        word.* = null;
        return a;
    }
};

pub fn anchor_chain(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;
    _ = io;

    var message: Message = .{ .text = "hello" };
    var job: Job = .{ .id = 42 };
    TypedMessage.stamp(&message);
    TypedJob.stamp(&job);

    var stack: Stack = .{};
    try stack.push(TypedMessage.anchor(&message));
    try stack.push(TypedJob.anchor(&job));

    const first: *paternitas.Anchor = try stack.pop() orelse return error.StackEmpty;
    const j: *Job = TypedJob.fromAnchor(first) orelse return error.WrongOrder;

    const second: *paternitas.Anchor = try stack.pop() orelse return error.StackEmpty;
    const m: *Message = TypedMessage.fromAnchor(second) orelse return error.WrongOrder;

    if (try stack.pop() != null) return error.StackNotEmpty;
    if ((try chainWord(first)).* != null or (try chainWord(second)).* != null) return error.ChainWordLeft;

    std.log.info("popped job {d}, then message {s}", .{ j.*.id, m.*.text });
}

/// The chain word of `a`, typed as this stack keeps it: the next Anchor.
///
/// An unstamped Anchor has no `TypeInfo`, so no chain word.
fn chainWord(a: *paternitas.Anchor) !*?*paternitas.Anchor {
    const ti: *const paternitas.container.TypeInfo = a.info() orelse return error.Unstamped;
    return @ptrCast(ti.nextField(a));
}

const paternitas = @import("paternitas");
const std = @import("std");
