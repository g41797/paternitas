//! A `DLink` Parent in the application's timeout list, sent away and back.
//!
//! The timeout list is a plain `std.DoublyLinkedList`.
//! It removes any Node in O(1).
//! The queue carries `*Anchor`, a pointer. The Parent never moves.
//!
//! - stamp three `Connection`s and append them to the timeout list
//! - remove the middle one from the list
//! - send its `*Anchor` through a `std.Io.Queue`
//! - receive the `*Anchor`, and recover the `Connection` with `fromAnchor`
//! - give it a new deadline, and append it to the list again
//! - check the order of the list
//!
//! ```
//!  timeout list:   c1 <-> c2 <-> c3
//!                          |
//!                          |  remove, Info.anchor
//!                          v
//!  queue:              [*Anchor]
//!                          |
//!                          |  getOne, Info.fromAnchor
//!                          v
//!  timeout list:   c1 <-> c3 <-> c2
//! ```

pub fn timeout_list(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;

    var connections: [3]Connection = .{
        .{ .id = 1, .deadline = 10 },
        .{ .id = 2, .deadline = 20 },
        .{ .id = 3, .deadline = 30 },
    };

    var timeouts: std.DoublyLinkedList = .{};
    for (&connections) |*c| {
        ConnectionInfo.stamp(c);
        timeouts.append(ConnectionInfo.node(c));
    }

    var buffer: [4]*paternitas.Anchor = undefined;
    var queue: Queue = .init(&buffer);

    try sendAway(&timeouts, &queue, io, &connections[1]);
    try comeBack(&timeouts, &queue, io);
    try checkOrder(&timeouts, &.{ 1, 3, 2 });
}

/// Out of the list, into the queue. Only the pointer travels.
fn sendAway(timeouts: *std.DoublyLinkedList, queue: *Queue, io: std.Io, c: *Connection) !void {
    timeouts.remove(ConnectionInfo.node(c));
    try queue.putOne(io, ConnectionInfo.anchor(c));
}

/// Out of the queue, back into the list, with a new deadline.
fn comeBack(timeouts: *std.DoublyLinkedList, queue: *Queue, io: std.Io) !void {
    const a: *paternitas.Anchor = try queue.getOne(io);
    const c: *Connection = ConnectionInfo.fromAnchor(a) orelse return error.WrongParent;

    c.*.deadline += 100;
    timeouts.append(ConnectionInfo.node(c));

    std.log.info("connection {d} is back, deadline {d}", .{ c.*.id, c.*.deadline });
}

fn checkOrder(timeouts: *const std.DoublyLinkedList, expected: []const u32) !void {
    var i: usize = 0;
    var it: ?*std.DoublyLinkedList.Node = timeouts.first;
    while (it) |node| : (it = node.*.next) {
        const c: *Connection = ConnectionInfo.parentFromNode(node) orelse return error.WrongParent;
        if (i == expected.len or c.*.id != expected[i]) return error.WrongOrder;
        i += 1;
    }
    if (i != expected.len) return error.WrongOrder;
}

/// A `DLink`, so the timeout list can remove it from anywhere.
const Connection: type = struct {
    id: u32,
    deadline: u64,
    link: paternitas.DLink = .{},
};

const ConnectionInfo: type = paternitas.Info(Connection);

const Queue: type = std.Io.Queue(*paternitas.Anchor);

const paternitas = @import("paternitas");
const std = @import("std");
