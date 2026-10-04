//! Title: One struct, one list
//!
//! The smallest use.
//!
//! One struct goes into a std list. It comes back with a type check.
//!
//! ### When you need it
//!
//! Start here.
//!
//! Every other example builds on these calls.
//!
//! ### What it does
//!
//! - Put a `DoublyTypedNode` in `Message`, where the std Node would be.
//! - Call `setTypeId` on a `Message`.
//! - Append its Node to a `std.DoublyLinkedList`, with `node`.
//! - Pop the Node.
//! - Get the `Message` back with `parentFromNode`.
//! - Log its text.
//!
//! ### What to notice
//!
//! The list is the plain std list.
//!
//! A Node of another type would give null, not a wrong pointer.

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
