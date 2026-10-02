//! Stamp a Parent, pass its Node through a std list, and recover the Parent.
//!
//! The smallest use of paternitas. One Parent type, one std list.
//!
//! - stamp a `Message`
//! - append its Node to a `std.DoublyLinkedList`
//! - pop the Node
//! - recover the `Message` from the Node, checked
//! - log its text

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
