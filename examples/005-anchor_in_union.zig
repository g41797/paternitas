//! `*Anchor` as one variant of a tagged union. The Parent stays where it is.
//!
//! Small events travel by value.
//! A Parent that must not be copied travels as a pointer to its Anchor.
//!
//! - a `Download` keeps a large buffer, and is never copied
//! - build three `Event`s: a tick, a resize, and the `Download`'s `*Anchor`
//! - copy the events into a second array, as a queue would
//! - handle each event, and recover the `Download` with `fromAnchor`
//! - check that it is the same `Download`, not a copy

/// Too large to copy around.
const Download: type = struct {
    link: paternitas.SLink = .{},
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
    TypedDownload.stamp(&download);

    const sent: [3]Event = .{
        .{ .tick = 1 },
        .{ .resize = .{ .width = 80, .height = 24 } },
        .{ .parent = TypedDownload.anchor(&download) },
    };

    // A copy, as a queue makes. Each Event is small. The Download is not in it.
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
