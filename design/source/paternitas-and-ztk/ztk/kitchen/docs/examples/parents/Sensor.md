# Just a demo parent — not for production

## Description

Just a demo parent — not for production.

## Source

```zig
inner: SLink = .{},
value: f64 = 0.0,

pub const SensorHelper = matryoshka.helper.ParentHelper(Self);

pub fn init(self: *Self, alloc: std.mem.Allocator, io: std.Io) !void {
    _ = .{ alloc, io };
    self.value = 0.0;
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
