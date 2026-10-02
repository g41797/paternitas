# Just a demo parent — not for production

## Description

Just a demo parent — not for production.

## Source

```zig
inner: SLink = .{},
reason: u8 = 0,

pub const ShutdownCommandHelper = matryoshka.helper.ParentHelper(Self);

pub fn init(self: *Self, alloc: std.mem.Allocator, io: std.Io) !void {
    _ = .{ alloc, io };
    self.reason = 0;
}

pub fn finish(self: *Self, alloc: std.mem.Allocator, io: std.Io) void {
    _ = .{ self, alloc, io };
}

const Self = @This();
const Anchor = matryoshka.inner.Anchor;
const SLink = matryoshka.inner.SLink;
const matryoshka = @import("matryoshka");
const std = @import("std");
```
