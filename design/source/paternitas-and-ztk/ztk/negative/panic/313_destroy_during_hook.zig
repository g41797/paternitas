// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 313 — destroying a pool while a hook is running is refused.
//!
//! In all four modes, and this is the half that `close` alone cannot give
//! you. The pool is closed, so the first half of the contract holds. A put
//! is still inside it, running the hook, so the second half does not.
//!
//! A hook is caller code running inside a call, and the call counter counts
//! it. Without that, the free would succeed and the hook would come back
//! into memory that had been handed to the allocator.
//!
//! **Why the hook is still counted when `destroy` runs.** It does not rest
//! on timing: the hook spins on `released` and this program never sets it,
//! so the putting context cannot leave the pool at all. The main context
//! waits until the hook says it is inside, closes, and destroys. The
//! putting context is still in there when it does.
//!
//! If this program ever exits normally the build reports the contract as
//! not refused, which is the right way for it to fail.

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

var inside: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
var released: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

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

    inside.store(true, .release);

    // Never let go. The put stays inside the pool, counted, for as long as
    // this program lives.
    while (!released.load(.acquire)) std.Thread.yield() catch {};
}

fn onClose(ctx: *anyopaque, remaining: m.queue.Queue) void {
    _ = ctx;
    var mine: m.queue.Queue = remaining;
    while (mine.popFirst()) |_| {}
}

var hooks: m.Pool.Hooks = undefined;

fn putOne(pool: *m.Pool) void {
    var slot: m.inner.Slot = null;
    ITEM.create(std.heap.page_allocator, undefined, &slot) catch return;

    pool.put(&slot) catch return;
}

pub fn main() void {
    var threaded: std.Io.Threaded = std.Io.Threaded.init(std.heap.page_allocator, .{});
    const io: std.Io = threaded.io();

    var nothing: usize = 0;
    hooks = .{
        .ctx = &nothing,
        .on_get = onGet,
        .on_put = onPut,
        .on_close = onClose,
    };

    var slot: m.inner.Slot = null;
    m.pool.new(std.heap.page_allocator, io, &.{ITEM.ID}, hooks, &slot) catch
        @panic("313: the pool was not made");

    const pool: *m.Pool = m.Pool.moveFromSlot(&slot).?;

    const putter = std.Thread.spawn(.{}, putOne, .{pool}) catch
        @panic("313: the putting context did not start");

    while (!inside.load(.acquire)) std.Thread.yield() catch {};

    // Closed, so the first half of the contract holds. The put hook is
    // still inside, so the second half does not, and this aborts.
    pool.close();
    pool.destroy();

    putter.join();
}

const m = @import("matryoshka");
const std = @import("std");
