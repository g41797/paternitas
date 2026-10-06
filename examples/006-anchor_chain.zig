//! Title: Your own stack
//!
//! Build your own stack of mixed struct types.
//!
//! It needs no extra memory per item.
//!
//! ### When you need it
//!
//! You write a container yourself: a stack, a queue, a pool.
//!
//! It keeps items of several types, and does not know them.
//!
//! Most application code does not need this. A std list, or an `Any`, is enough.
//!
//! ### What it does
//!
//! - Write a `Stack` that keeps `*Anchor`s.
//! - Chain them through each item's `next` field, from `TypeInfo.nextField`.
//! - Push a `Message` with a `SinglyTypedNode`.
//! - Push a `Job` with a `DoublyTypedNode`. Two Node types share one chain.
//! - Pop each, and get it back with `parentFromAnchor`.
//! - Check the order.
//! - Check that each `next` field is null again.
//!
//! ### What to notice
//!
//! Each item has a std Node. Its `next` field is free while the item is in no std list.
//!
//! The link lives in the item, as in a std list. So the stack is intrusive.
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

// --8<-- [start:stack]
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
// --8<-- [end:stack]

pub fn anchor_chain(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;
    _ = io;

    var message: Message = .{ .text = "hello" };
    TypedMessage.setTypeId(&message);
    var job: Job = .{ .id = 42 };
    TypedJob.setTypeId(&job);

    // --8<-- [start:use]
    var stack: Stack = .{};
    try stack.push(TypedMessage.anchor(&message));
    try stack.push(TypedJob.anchor(&job));

    const first: *paternitas.Anchor = try stack.pop() orelse return error.StackEmpty;
    const j: *Job = TypedJob.parentFromAnchor(first) orelse return error.WrongOrder;

    const second: *paternitas.Anchor = try stack.pop() orelse return error.StackEmpty;
    const m: *Message = TypedMessage.parentFromAnchor(second) orelse return error.WrongOrder;
    // --8<-- [end:use]

    if (try stack.pop() != null) return error.StackNotEmpty;
    if ((try chainWord(first)).* != null or (try chainWord(second)).* != null) return error.ChainWordLeft;

    std.log.info("popped job {d}, then message {s}", .{ j.*.id, m.*.text });
}

// --8<-- [start:chain]
/// Returns the item's `next` field. This stack keeps a pointer to the next
/// `*Anchor` in it.
///
/// Returns `error.NoTypeId` when `setTypeId` was never called on the item.
fn chainWord(a: *paternitas.Anchor) !*?*paternitas.Anchor {
    const ti: *const paternitas.container.TypeInfo = a.info() orelse return error.NoTypeId;
    return @ptrCast(ti.nextField(a));
}
// --8<-- [end:chain]

const paternitas = @import("paternitas");
const std = @import("std");
