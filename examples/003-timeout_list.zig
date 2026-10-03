//! A connection leaves the timeout list, goes through a queue, and comes back.
//!
//! A server keeps its open connections in a timeout list, a plain `std.DoublyLinkedList`.
//! Sometimes a connection goes to another thread for a while, through a queue.
//! A connection must not be copied, so the queue carries its `*Anchor`, a pointer.
//! The other side gets the `Connection` back with a type check.
//!
//! - Call `setTypeId` on three `Connection`s and append them to the timeout list.
//! - Remove the middle one from the list.
//! - Send its `*Anchor` through a `std.Io.Queue`.
//! - Receive the `*Anchor`, and get the `Connection` back with `parentFromAnchor`.
//! - Give it a new deadline, and append it to the list again.
//! - Check the order of the list.
//!
//! ```
//!  timeout list:   c1 <-> c2 <-> c3
//!                          |
//!                          |  remove, anchor()
//!                          v
//!  queue:              [*Anchor]
//!                          |
//!                          |  getOne, parentFromAnchor()
//!                          v
//!  timeout list:   c1 <-> c3 <-> c2
//! ```

/// It has a `DoublyTypedNode`, so the timeout list can remove it from anywhere.
const Connection: type = struct {
    id: u32,
    deadline: u64,
    tnode: paternitas.DoublyTypedNode = .{},
};
const TypedConnection: type = paternitas.Typed(Connection);

const Queue: type = std.Io.Queue(*paternitas.Anchor);

pub fn timeout_list(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;

    var connections: [3]Connection = .{
        .{ .id = 1, .deadline = 10 },
        .{ .id = 2, .deadline = 20 },
        .{ .id = 3, .deadline = 30 },
    };

    var timeouts: std.DoublyLinkedList = .{};
    for (&connections) |*c| {
        TypedConnection.setTypeId(c);
        timeouts.append(TypedConnection.node(c));
    }

    var buffer: [4]*paternitas.Anchor = undefined;
    var queue: Queue = .init(&buffer);

    try removeAndSend(&timeouts, &queue, io, &connections[1]);
    try receiveAndAppend(&timeouts, &queue, io);
    try checkOrder(&timeouts, &.{ 1, 3, 2 });
}

/// Takes the connection out of the list, and sends its pointer through the
/// queue.
fn removeAndSend(timeouts: *std.DoublyLinkedList, queue: *Queue, io: std.Io, c: *Connection) !void {
    timeouts.remove(TypedConnection.node(c));
    try queue.putOne(io, TypedConnection.anchor(c));
}

/// Gets a pointer from the queue, and puts the connection back in the list
/// with a new deadline.
fn receiveAndAppend(timeouts: *std.DoublyLinkedList, queue: *Queue, io: std.Io) !void {
    const a: *paternitas.Anchor = try queue.getOne(io);
    const c: *Connection = TypedConnection.parentFromAnchor(a) orelse return error.WrongParent;

    c.*.deadline += 100;
    timeouts.append(TypedConnection.node(c));

    std.log.info("connection {d} is back, deadline {d}", .{ c.*.id, c.*.deadline });
}

fn checkOrder(timeouts: *const std.DoublyLinkedList, expected: []const u32) !void {
    var i: usize = 0;
    var it: ?*std.DoublyLinkedList.Node = timeouts.first;
    while (it) |node| : (it = node.*.next) {
        const c: *Connection = TypedConnection.parentFromNode(node) orelse return error.WrongParent;
        if (i == expected.len or c.*.id != expected[i]) return error.WrongOrder;
        i += 1;
    }
    if (i != expected.len) return error.WrongOrder;
}

const paternitas = @import("paternitas");
const std = @import("std");
