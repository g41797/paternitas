// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 311 — destroying an open pool is refused.
//!
//! In all four modes. `Pool.destroy` aborts with `std.debug.panic` and not
//! with `check`: freeing a pool that was never closed leaves whatever it
//! still stores unreachable, and a fast build may not assume the caller got
//! this right.
//!
//! The mailbox's 310 is the same contract. They are separate programs
//! because a program can only die once.

const Item = struct {
    hdr: m.inner.SinglyTypedNode = .{},

    pub fn init(self: *Item, alloc: std.mem.Allocator, io: std.Io) !void {
        _ = self;
        _ = alloc;
        _ = io;
    }

    pub fn finish(self: *Item, alloc: std.mem.Allocator, io: std.Io) void {
        _ = self;
        _ = alloc;
        _ = io;
    }
};

const ITEM = m.helper.ParentHelper(Item);

fn onGet(ctx: *anyopaque, want: m.inner.TypeId, in_pool: usize, slot: *m.inner.Slot) void {
    _ = ctx;
    _ = want;
    _ = in_pool;
    _ = slot;
}

fn onPut(ctx: *anyopaque, in_pool: usize, slot: *m.inner.Slot, extra: *m.queue.Queue) void {
    _ = ctx;
    _ = in_pool;
    _ = slot;
    _ = extra;
}

fn onClose(ctx: *anyopaque, remaining: m.queue.Queue) void {
    _ = ctx;
    _ = remaining;
}

pub fn main() void {
    var threaded: std.Io.Threaded = std.Io.Threaded.init(std.heap.page_allocator, .{});
    const io: std.Io = threaded.io();

    var nothing: usize = 0;

    var slot: m.inner.Slot = null;
    m.pool.new(std.heap.page_allocator, io, &.{ITEM.ID}, .{
        .ctx = &nothing,
        .on_get = onGet,
        .on_put = onPut,
        .on_close = onClose,
    }, &slot) catch @panic("311: the pool was not made");

    const pool: *m.Pool = m.Pool.moveFromSlot(&slot).?;

    // Never closed. This aborts.
    pool.destroy();
}

const m = @import("matryoshka");
const std = @import("std");
