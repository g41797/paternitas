// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Pool teardown.
//!
//! - Seed the pool with 4 Events via get (new_only) + pl.put.
//! - Close the pool.
//! - on_close receives every stored parent as a Queue, by value, and
//!   releases them.
//!
//!
//! ```
//!  pl.get (new_only) × 4 ──► pl.put × 4
//!  (pool holds 4 parents)
//!       │ pl.close
//!       ▼
//!  on_close ──► AlwaysCreateHooks: releases all 4
//! ```
//!

pub fn pool_teardown(allocator: std.mem.Allocator, io: std.Io) !void {
    var ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer pl.destroy();

    const n: usize = 4;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        var slot: Slot = null;
        defer pl.put(&slot) catch {};
        try pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
    }
    std.log.info("pool holds {d} Events before teardown", .{n});

    // Close: on_close receives all stored parents and releases them.
    pl.close();
    std.log.info("pool closed: on_close released all {d} parents", .{n});
}

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Slot = matryoshka.inner.Slot;
