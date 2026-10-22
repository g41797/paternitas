// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 302 — creating into a full Slot is refused.

const Msg = struct {
    seq: u32 = 0,
    hdr: m.inner.SinglyTypedNode = .{},

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

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(alloc, .{});
    const io: std.Io = threaded.io();

    var slot: m.inner.Slot = null;
    try MSG.create(alloc, io, &slot);

    // The Slot is full. A second acquisition would lose the first parent.
    try MSG.create(alloc, io, &slot);
}

const m = @import("matryoshka");
const std = @import("std");
