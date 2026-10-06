//! Title: Two types, one list
//!
//! One std list carries two struct types.
//!
//! Each one comes back as itself.
//!
//! ### When you need it
//!
//! A mailbox list often carries more than one kind of item.
//!
//! The list sees only Nodes. It does not know the types.
//!
//! A plain `@fieldParentPtr` gives you any type you ask for. It does not check.
//!
//! ### What it does
//!
//! - Call `setTypeId` on a `Message` and a `Job`.
//! - Append both Nodes to one `std.DoublyLinkedList`.
//! - Ask with `is` whether the last Node is a `Job`.
//! - Pop each Node.
//! - Ask `Message` first, then `Job`, with `parentFromNode`.
//! - Check that each type came back once.
//!
//! ### What to notice
//!
//! The wrong type gets null.
//!
//! So you can ask each type in turn.
//!
//! A Node that no type claims is an error you can see.

// --8<-- [start:types]
const Message: type = struct {
    text: []const u8,
    tnode: paternitas.DoublyTypedNode = .{},
};
const TypedMessage: type = paternitas.Typed(Message);

const Job: type = struct {
    tnode: paternitas.DoublyTypedNode = .{},
    id: u32,
    attempts: u32 = 0,
};
const TypedJob: type = paternitas.Typed(Job);
// --8<-- [end:types]

const Counts: type = struct {
    messages: usize = 0,
    jobs: usize = 0,
};

pub fn mixed_list(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;
    _ = io;

    // --8<-- [start:setup]
    var message: Message = .{ .text = "hello" };
    TypedMessage.setTypeId(&message);

    var job: Job = .{ .id = 42 };
    TypedJob.setTypeId(&job);

    var list: std.DoublyLinkedList = .{};
    list.append(TypedMessage.node(&message));
    list.append(TypedJob.node(&job));

    // --8<-- [start:is]
    const last: *std.DoublyLinkedList.Node = list.last orelse return error.ListEmpty;
    if (!TypedJob.is(last)) return error.WrongParent;
    // --8<-- [end:is]

    var counts: Counts = .{};
    while (list.popFirst()) |node| try recoverAndCount(node, &counts);
    // --8<-- [end:setup]

    if (counts.messages != 1 or counts.jobs != 1) return error.WrongCount;
}

// --8<-- [start:recover]
/// Asks each Parent type in turn. A Node that no type claims is an error.
fn recoverAndCount(node: *std.DoublyLinkedList.Node, counts: *Counts) !void {
    if (TypedMessage.parentFromNode(node)) |m| {
        std.log.info("message: {s}", .{m.*.text});
        counts.*.messages += 1;
        return;
    }
    if (TypedJob.parentFromNode(node)) |j| {
        std.log.info("job: {d}", .{j.*.id});
        counts.*.jobs += 1;
        return;
    }
    return error.UnknownParent;
}
// --8<-- [end:recover]

const paternitas = @import("paternitas");
const std = @import("std");
