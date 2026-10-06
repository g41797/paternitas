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
//! - Reset the `Message` with a whole-struct write.
//! - Call `setTypeId` again, and get the `Message` back again.
//!
//! ### What to notice
//!
//! The list is the plain std list.
//!
//! A Node of another type would give null, not a wrong pointer.
//!
//! A whole-struct write clears the type id. `setTypeId` again brings it back.

pub fn set_type_id_and_recover(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;
    _ = io;

    // --8<-- [start:define]
    const Message: type = struct {
        text: []const u8,
        tnode: paternitas.DoublyTypedNode = .{},
    };
    const TypedMessage: type = paternitas.Typed(Message);
    // --8<-- [end:define]

    // --8<-- [start:create]
    var message: Message = .{ .text = "hello" };
    TypedMessage.setTypeId(&message);
    // --8<-- [end:create]

    // --8<-- [start:list]
    var list: std.DoublyLinkedList = .{};
    list.append(TypedMessage.node(&message));

    const node: *std.DoublyLinkedList.Node = list.popFirst() orelse return error.ListEmpty;
    const recovered: *Message = TypedMessage.parentFromNode(node) orelse return error.WrongParent;
    // --8<-- [end:list]

    if (recovered != &message) return error.WrongParent;

    std.log.info("recovered: {s}", .{recovered.*.text});

    // --8<-- [start:reset]
    message = .{ .text = "reset" };
    TypedMessage.setTypeId(&message);
    // --8<-- [end:reset]

    const again: *Message = TypedMessage.parentFromNode(node) orelse return error.WrongParent;
    if (again != &message) return error.WrongParent;

    std.log.info("after reset: {s}", .{again.*.text});
}

const paternitas = @import("paternitas");
const std = @import("std");
