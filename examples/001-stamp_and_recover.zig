//! The smallest use: one struct, one std list, and the struct back with a type check.
//!
//! The struct has a `DLink` where it would have a std Node.
//!
//! - Stamp a `Message`, so it carries its type.
//! - Append its Node to a `std.DoublyLinkedList`.
//! - Pop the Node.
//! - Get the `Message` back with `parentFromNode`. A Node of another type would give null.
//! - Log its text.

pub fn stamp_and_recover(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;
    _ = io;

    const Message: type = struct {
        text: []const u8,
        link: paternitas.DLink = .{},
    };

    const TypedMessage: type = paternitas.Typed(Message);

    var message: Message = .{ .text = "hello" };
    TypedMessage.stamp(&message);

    var list: std.DoublyLinkedList = .{};
    list.append(TypedMessage.node(&message));

    const node: *std.DoublyLinkedList.Node = list.popFirst() orelse return error.ListEmpty;
    const recovered: *Message = TypedMessage.parentFromNode(node) orelse return error.WrongParent;

    if (recovered != &message) return error.WrongParent;

    std.log.info("recovered: {s}", .{recovered.*.text});
}

const paternitas = @import("paternitas");
const std = @import("std");
