// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 286 — a pool made with no identities at all is refused.
//!
//! A `check`, so Debug and ReleaseSafe only.
//!
//! Such a pool could never answer a `get` and could never take a `put`, so
//! the set being empty is a caller who has not decided what the pool is
//! for. The duplicate is the other half of the scenario, in its own
//! program.

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

    // No identities. This aborts.
    m.pool.new(std.heap.page_allocator, io, &.{}, .{
        .ctx = &nothing,
        .on_get = onGet,
        .on_put = onPut,
        .on_close = onClose,
    }, &slot) catch @panic("286: the pool was not made");
}

const m = @import("matryoshka");
const std = @import("std");
