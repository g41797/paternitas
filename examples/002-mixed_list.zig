//! Two Parent types in one std list, each recovered with a check.
//!
//! The list sees only Nodes.
//! `@fieldParentPtr` trusts any Node it is given.
//! `parentFromNode` reads the Anchor next to the Node first.
//!
//! - stamp a `Message` and a `Job`
//! - append both Nodes to one `std.DoublyLinkedList`
//! - pop each Node
//! - ask each Parent type in turn: `Message`, then `Job`
//! - check that each type recovered its own Parent once

const Message: type = struct {
    text: []const u8,
    link: paternitas.DLink = .{},
};
const TypedMessage: type = paternitas.Typed(Message);

const Job: type = struct {
    link: paternitas.DLink = .{},
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
    TypedMessage.stamp(&message);

    var job: Job = .{ .id = 42 };
    TypedJob.stamp(&job);

    var list: std.DoublyLinkedList = .{};
    list.append(TypedMessage.node(&message));
    list.append(TypedJob.node(&job));

    var counts: Counts = .{};
    while (list.popFirst()) |node| try recoverAndCount(node, &counts);

    if (counts.messages != 1 or counts.jobs != 1) return error.WrongCount;
}

/// Asks each Parent type in turn. A Node no type claims is an error.
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
