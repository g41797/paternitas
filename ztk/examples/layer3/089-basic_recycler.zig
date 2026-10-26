// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Reuse a parent
//!
//! A pool gives back the same parent, reset by your hook.
//!
//! - Make a pool with hooks for the Event id.
//! - Get a parent with `.available_or_new`. `on_get` makes a new one.
//! - Put it back. `on_put` resets it.
//! - Get again. You get the same parent, with its data reset.
//!
//! ```
//!  pl.get (available_or_new) ──► Slot (new, from on_get)
//!       │ pl.put ──► on_put resets the data ──► pool
//!       │ pl.get (available_or_new) ──► Slot (the same parent, reset)
//!       │ EventHelper.destroy ──► released
//! ```
//!

pub fn basic_recycler(allocator: std.mem.Allocator, io: std.Io) !void {
    var ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    var slot: Slot = null;
    defer parents.destroySlot(&slot, allocator, io);

    try pl.get(parents.Event.EventHelper.ID, .available_or_new, &slot);
    const ev = parents.Event.EventHelper.fromSlot(&slot) orelse return error.WrongType;
    ev.code = 89;
    std.log.info("got fresh Event, set code={d}", .{ev.code});

    try pl.put(&slot);
    std.log.info("returned Event to pool", .{});

    try pl.get(parents.Event.EventHelper.ID, .available_or_new, &slot);
    const ev2 = parents.Event.EventHelper.fromSlot(&slot) orelse return error.WrongType;
    std.log.info("recycled Event code={d}", .{ev2.code});
    try helpers.expect(error.BasicRecyclerFailed, ev2.code == 0, "recycled parent was not reset by the hook");
}

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Slot = matryoshka.inner.Slot;
