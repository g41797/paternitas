//! Title: Timeout list and a queue
//!
//! A connection leaves the timeout list.
//!
//! It goes through a queue. Then it comes back.
//!
//! ### When you need it
//!
//! A server keeps its open connections in a timeout list, a plain `std.DoublyLinkedList`.
//!
//! Sometimes a connection goes to another thread for a while, through a queue.
//!
//! A `std.Io.Queue` stores a copy of what you put in.
//!
//! A connection must not be copied.
//!
//! ### What it does
//!
//! - Call `setTypeId` on three `Connection`s.
//! - Append them to the timeout list.
//! - Remove the middle one from the list.
//! - Send its `Any` through a `std.Io.Queue`, with `toAny`.
//! - Receive the `Any`.
//! - Get the `Connection` back with `fromAny`.
//! - Give it a new deadline.
//! - Append it to the list again.
//! - Check the order of the list.
//!
//! ### What to notice
//!
//! The queue carries an `Any`: the address and the type id. Two words.
//!
//! The `Connection` is never copied.
//!
//! It MUST stay alive while its `Any` is in the queue.
//!
//! ```
//!  timeout list:   c1 <-> c2 <-> c3
//!                          |
//!                          |  remove, toAny()
//!                          v
//!  queue:             [Any]
//!                          |
//!                          |  getOne, fromAny()
//!                          v
//!  timeout list:   c1 <-> c3 <-> c2
//! ```

/// It has a `DoublyTypedNode`. The timeout list can remove it from anywhere.
const Connection: type = struct {
    id: u32,
    deadline: u64,
    tnode: paternitas.DoublyTypedNode = .{},
};
const TypedConnection: type = paternitas.Typed(Connection);

const Queue: type = std.Io.Queue(paternitas.Any);

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

    var buffer: [4]paternitas.Any = undefined;
    var queue: Queue = .init(&buffer);

    try removeAndSend(&timeouts, &queue, io, &connections[1]);
    try receiveAndAppend(&timeouts, &queue, io);
    try checkOrder(&timeouts, &.{ 1, 3, 2 });
}

// --8<-- [start:queue]
/// Takes the connection out of the list. Sends its `Any` through the
/// queue.
fn removeAndSend(timeouts: *std.DoublyLinkedList, queue: *Queue, io: std.Io, c: *Connection) !void {
    timeouts.remove(TypedConnection.node(c));
    try queue.putOne(io, TypedConnection.toAny(c));
}

/// Gets an `Any` from the queue. Puts the connection back in the list,
/// with a new deadline.
fn receiveAndAppend(timeouts: *std.DoublyLinkedList, queue: *Queue, io: std.Io) !void {
    const any: paternitas.Any = try queue.getOne(io);
    const c: *Connection = TypedConnection.fromAny(any) orelse return error.WrongParent;

    c.*.deadline += 100;
    timeouts.append(TypedConnection.node(c));

    std.log.info("connection {d} is back, deadline {d}", .{ c.*.id, c.*.deadline });
}
// --8<-- [end:queue]

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
