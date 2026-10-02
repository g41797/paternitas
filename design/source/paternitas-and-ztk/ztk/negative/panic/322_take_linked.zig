// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 322 — taking a parent that is still on a chain out of a Slot is refused.

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
    var msg: Msg = .{};
    MSG.stamp(&msg);

    var chain: m.queue.Queue = .{};
    chain.append(MSG.toAnchor(&msg));

    var slot: m.inner.Slot = MSG.toAnchor(&msg);
    _ = m.inner.takeFromSlot(&slot);
}

const m = @import("matryoshka");
const std = @import("std");
