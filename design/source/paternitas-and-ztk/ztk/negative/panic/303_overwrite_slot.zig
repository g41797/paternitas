// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 303 — overwriting a full Slot is refused.

const Msg = struct {
    seq: u32 = 0,
    hdr: m.inner.SLink = .{},

    pub fn init(self: *Msg, alloc: std.mem.Allocator, io: std.Io) !void {
        _ = io;
        _ = alloc;
        self.seq = 0;
    }

    pub fn finish(self: *Msg, alloc: std.mem.Allocator, io: std.Io) void {
        _ = io;
        _ = self;
        _ = alloc;
    }
};

const MSG = m.helper.ParentHelper(Msg);

pub fn main() void {
    var first: Msg = .{ .seq = 1 };
    var second: Msg = .{ .seq = 2 };
    MSG.stamp(&first);
    MSG.stamp(&second);

    var slot: m.inner.Slot = MSG.toAnchor(&first);
    m.inner.fillSlot(&slot, MSG.toAnchor(&second));
}

const m = @import("matryoshka");
const std = @import("std");
