//! Title: Before Paternitas
//!
//! Page: none
//!
//! The code you start from.
//!
//! A plain std list, a plain Node, a plain `@fieldParentPtr`.
//!
//! The site pages quote it. It has no page of its own.
//!
//! ### What it does
//!
//! - Put a std Node in `Message` and in `Job`.
//! - Append both Nodes to one `std.DoublyLinkedList`.
//! - Pop each Node.
//! - Get each struct back with `@fieldParentPtr`, on the right type.
//!
//! ### What to notice
//!
//! Nothing checks the type. The code knows the order, and trusts it.

// --8<-- [start:structs]
const Message: type = struct {
    text: []const u8,
    node: std.DoublyLinkedList.Node = .{},
};

const Job: type = struct {
    id: u32,
    node: std.DoublyLinkedList.Node = .{},
};
// --8<-- [end:structs]

pub fn before_paternitas(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;
    _ = io;

    // --8<-- [start:list]
    var message: Message = .{ .text = "hello" };
    var job: Job = .{ .id = 42 };

    var list: std.DoublyLinkedList = .{};
    list.append(&message.node);
    list.append(&job.node);
    // --8<-- [end:list]

    // --8<-- [start:recover]
    const first: *std.DoublyLinkedList.Node = list.popFirst() orelse return error.ListEmpty;
    const m: *Message = @fieldParentPtr("node", first);
    std.log.info("message: {s}", .{m.*.text});

    const second: *std.DoublyLinkedList.Node = list.popFirst() orelse return error.ListEmpty;
    const j: *Job = @fieldParentPtr("node", second);
    std.log.info("job: {d}", .{j.*.id});
    // --8<-- [end:recover]

    if (m != &message or j != &job) return error.WrongParent;
}

const std = @import("std");
