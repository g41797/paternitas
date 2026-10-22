// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 309 — a parent with no finish does not compile where the helper releases it.

const NoFinish = struct {
    hdr: m.inner.SinglyTypedNode = .{},

    pub fn init(self: *NoFinish, alloc: std.mem.Allocator, io: std.Io) !void {
        _ = io;
        _ = self;
        _ = alloc;
    }
};

pub fn main() void {
    const io: std.Io = undefined;
    var slot: m.inner.Slot = null;
    m.helper.ParentHelper(NoFinish).destroy(std.heap.page_allocator, io, &slot);
}

const m = @import("matryoshka");
const std = @import("std");
