//! One std list, two struct types, and each one comes back as itself.
//!
//! A mailbox list often carries more than one kind of item.
//! The list is type-erased: it sees only Nodes, never a `Message` or a `Job`.
//! With a plain std Node, `@fieldParentPtr` returns whatever type you ask for, right or wrong.
//! Here each type asks `parentFromNode`, and the wrong type gets null.
//!
//! - Call `setTypeId` on a `Message` and a `Job`.
//! - Append both Nodes to one `std.DoublyLinkedList`.
//! - Pop each Node.
//! - Ask `Message` first, then `Job`.
//! - Check that each type came back exactly once.

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

const Counts: type = struct {
    messages: usize = 0,
    jobs: usize = 0,
};

pub fn mixed_list(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;
    _ = io;

    var message: Message = .{ .text = "hello" };
    TypedMessage.setTypeId(&message);

    var job: Job = .{ .id = 42 };
    TypedJob.setTypeId(&job);

    var list: std.DoublyLinkedList = .{};
    list.append(TypedMessage.node(&message));
    list.append(TypedJob.node(&job));

    var counts: Counts = .{};
    while (list.popFirst()) |node| try recoverAndCount(node, &counts);

    if (counts.messages != 1 or counts.jobs != 1) return error.WrongCount;
}

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

const paternitas = @import("paternitas");
const std = @import("std");
