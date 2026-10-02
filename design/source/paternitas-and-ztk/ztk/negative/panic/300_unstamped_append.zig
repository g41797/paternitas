// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 300 — an unstamped parent is refused at every crossing.
//!
//! The append is one crossing of several. The others are a send and a put,
//! and they arrive with their own layers.

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

    // No stamp. The helper is the only thing that writes an id.
    var q: m.queue.Queue = .{};
    q.append(&msg.hdr.anchor);
}

const m = @import("matryoshka");
const std = @import("std");
