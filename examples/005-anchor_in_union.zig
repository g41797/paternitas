//! Send a large struct through a union of events, by pointer, without copying it.
//!
//! Small events travel by value in a tagged union.
//! A large struct, or one that must not be copied, travels as its `*Anchor`.
//! The handler gets the struct back with a type check.
//!
//! - Call `setTypeId` on a `Download`. It has a 4 KB buffer, too large to copy.
//! - Build three `Event`s: a tick, a resize, and the `Download`'s `*Anchor`.
//! - Copy the events into a second array, as a queue would.
//! - Handle each event, and get the `Download` back with `fromAnchor`.
//! - Check that it is the same `Download`, not a copy.

/// It is too large to copy. Events carry a pointer to it.
const Download: type = struct {
    tnode: paternitas.SinglyTypedNode = .{},
    buffer: [4096]u8 = undefined,
    received: usize = 0,
};
const TypedDownload: type = paternitas.Typed(Download);

const Event: type = union(enum) {
    tick: u64,
    resize: Size,
    parent: *paternitas.Anchor,
};

const Size: type = struct {
    width: u16,
    height: u16,
};

pub fn anchor_in_union(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;
    _ = io;

    var download: Download = .{};
    TypedDownload.setTypeId(&download);

    const sent: [3]Event = .{
        .{ .tick = 1 },
        .{ .resize = .{ .width = 80, .height = 24 } },
        .{ .parent = TypedDownload.anchor(&download) },
    };

    // Copy the events, as a queue would. Each Event is small, and the
    // Download is not in it.
    var received: [sent.len]Event = undefined;
    @memcpy(&received, &sent);

    std.log.info("one Event: {d} bytes, one Download: {d} bytes", .{ @sizeOf(Event), @sizeOf(Download) });

    for (received) |e| try handle(e);

    if (download.received != 1) return error.NotTheSameDownload;
}

fn handle(e: Event) !void {
    switch (e) {
        .tick => |t| std.log.info("tick {d}", .{t}),
        .resize => |s| std.log.info("resize {d}x{d}", .{ s.width, s.height }),
        .parent => |a| {
            const d: *Download = TypedDownload.fromAnchor(a) orelse return error.UnknownParent;
            d.*.received += 1;
            std.log.info("download, {d} bytes of buffer", .{d.*.buffer.len});
        },
    }
}

const paternitas = @import("paternitas");
const std = @import("std");
