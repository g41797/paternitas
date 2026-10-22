//! Just a demo parent — not for production.
//!
//! It has a DoublyTypedNode, so it can also live in the application's own
//! `std.DoublyLinkedList`, a timeout list.
inner: DoublyTypedNode = .{},
due_ms: u64 = 0,

pub const DeadlineHelper = matryoshka.helper.ParentHelper(Self);

pub fn init(self: *Self, alloc: std.mem.Allocator, io: std.Io) !void {
    _ = .{ alloc, io };
    self.due_ms = 0;
}

pub fn finish(self: *Self, alloc: std.mem.Allocator, io: std.Io) void {
    _ = .{ self, alloc, io };
}

const Self = @This();
const DoublyTypedNode = matryoshka.inner.DoublyTypedNode;
const matryoshka = @import("matryoshka");
const std = @import("std");
