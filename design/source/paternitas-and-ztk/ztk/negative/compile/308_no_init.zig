// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 308 — a parent with no init does not compile where the helper creates it.

const NoInit = struct {
    hdr: m.inner.SLink = .{},

    pub fn finish(self: *NoInit, alloc: std.mem.Allocator, io: std.Io) void {
        _ = io;
        _ = self;
        _ = alloc;
    }
};

pub fn main() !void {
    const io: std.Io = undefined;
    var slot: m.inner.Slot = null;
    try m.helper.ParentHelper(NoInit).create(std.heap.page_allocator, io, &slot);
}

const m = @import("matryoshka");
const std = @import("std");
