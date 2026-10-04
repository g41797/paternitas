//! Title: One struct, one list
//!
//! The smallest use. One struct goes into a std list. It comes back with a type check.
//!
//! The struct has a `DoublyTypedNode` where it would have a std Node.
//!
//! - Call `setTypeId` on a `Message`.
//! - Append its Node to a `std.DoublyLinkedList`.
//! - Pop the Node.
//! - Get the `Message` back with `parentFromNode`. A Node of another type would give null.
//! - Log its text.

pub fn set_type_id_and_recover(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;
    _ = io;

    const Message: type = struct {
        text: []const u8,
        tnode: paternitas.DoublyTypedNode = .{},
    };
    const TypedMessage: type = paternitas.Typed(Message);

    var message: Message = .{ .text = "hello" };
    TypedMessage.setTypeId(&message);

    var list: std.DoublyLinkedList = .{};
    list.append(TypedMessage.node(&message));

    const node: *std.DoublyLinkedList.Node = list.popFirst() orelse return error.ListEmpty;
    const recovered: *Message = TypedMessage.parentFromNode(node) orelse return error.WrongParent;

    if (recovered != &message) return error.WrongParent;

    std.log.info("recovered: {s}", .{recovered.*.text});
}

const paternitas = @import("paternitas");
const std = @import("std");
