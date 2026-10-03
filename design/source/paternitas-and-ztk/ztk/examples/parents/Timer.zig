//! Just a demo parent — not for production.
inner: SinglyTypedNode = .{},
ticks: u32 = 0,

pub const TimerHelper = matryoshka.helper.ParentHelper(Self);

pub fn init(self: *Self, alloc: std.mem.Allocator, io: std.Io) !void {
    _ = .{ alloc, io };
    self.ticks = 0;
}

pub fn finish(self: *Self, alloc: std.mem.Allocator, io: std.Io) void {
    _ = .{ self, alloc, io };
}

const Self = @This();
const Anchor = matryoshka.inner.Anchor;
const SinglyTypedNode = matryoshka.inner.SinglyTypedNode;
const matryoshka = @import("matryoshka");
const std = @import("std");
