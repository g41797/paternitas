// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 301 — a wrong-type must-call panics, and names both types.
//!
//! In all four modes. This is a `@panic`, not a `check`: the old tree's
//! `orelse unreachable` was undefined behaviour in the two fast modes, where
//! the optimizer could drop the compare and answer a pointer of the wrong
//! type.

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

const Chunk = struct {
    mtk: m.inner.SLink = .{},

    pub fn init(self: *Chunk, alloc: std.mem.Allocator, io: std.Io) !void {
        _ = io;
        _ = self;
        _ = alloc;
    }

    pub fn finish(self: *Chunk, alloc: std.mem.Allocator, io: std.Io) void {
        _ = io;
        _ = self;
        _ = alloc;
    }
};

const CHUNK = m.helper.ParentHelper(Chunk);

pub fn main() void {
    var msg: Msg = .{};
    MSG.stamp(&msg);

    var slot: m.inner.Slot = MSG.toAnchor(&msg);
    _ = CHUNK.mustMoveFromSlot(&slot);
}

const m = @import("matryoshka");
const std = @import("std");
