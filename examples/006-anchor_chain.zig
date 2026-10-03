//! Build your own stack of mixed struct types, with no extra memory per item.
//!
//! You write a container that keeps items of several types.
//! Each item has a std Node, and its `next` field is free while the item is in no std list.
//! `TypeInfo.nextField` gives you that field for any type, so your stack chains through it.
//!
//! - Write a `Stack` that keeps `*Anchor`s, chained through each item's `next` field.
//! - Push a `Message` with a `SinglyTypedNode` and a `Job` with a `DoublyTypedNode`. Two Node types share one chain.
//! - Pop each, and get it back with `fromAnchor`.
//! - Check the order, and that each `next` field is null again.
//!
//! A std list uses the same `next` field. An item on this stack MUST NOT be in a std list.
//!
//! ```
//!  top --> job.anchor --next--> message.anchor --next--> null
//! ```

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

/// A last-in, first-out stack of `*Anchor`s. It allocates nothing.
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
    TypedMessage.setTypeId(&message);
    TypedJob.setTypeId(&job);

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

/// Returns the item's `next` field, typed as this stack uses it: a pointer
/// to the next `*Anchor`.
///
/// Fails when `setTypeId` was never called on the item.
fn chainWord(a: *paternitas.Anchor) !*?*paternitas.Anchor {
    const ti: *const paternitas.container.TypeInfo = a.info() orelse return error.NoTypeId;
    return @ptrCast(ti.nextField(a));
}

const paternitas = @import("paternitas");
const std = @import("std");
