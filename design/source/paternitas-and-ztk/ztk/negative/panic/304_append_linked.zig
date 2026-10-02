// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 304 — appending a parent already on a chain is refused, including the
//! chain of one.
//!
//! The chain here holds one item. The old blind link test could not see it.

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

    var first: m.queue.Queue = .{};
    first.append(MSG.toAnchor(&msg));

    var second: m.queue.Queue = .{};
    second.append(MSG.toAnchor(&msg));
}

const m = @import("matryoshka");
const std = @import("std");
