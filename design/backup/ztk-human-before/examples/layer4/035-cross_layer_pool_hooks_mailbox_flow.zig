// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Pool hooks + mailbox flow.
//!
//! - round1: on_get creates a parent, mailbox carries it, on_put keeps it (cap
//!   not yet reached) and resets its data.
//! - round2: on_get creates a fresh parent, mailbox carries it, on_put releases
//!   it (cap reached).
//! - verifyRecycled confirms the kept parent is still in the pool, holding
//!   reset data — not the value round1 set.
//!
//!
//! ```
//!  pl.get (new_only) ──► on_get creates ──► slot (code=1)
//!  mbx.send ──► mailbox holds the parent
//!  mbx.receive ──► slot (same parent)
//!  pl.put ──► on_put: count<cap → keep, reset data ──► pool store
//!  │
//!  pl.get (new_only) ──► on_get creates fresh ──► slot (code=2)
//!  mbx.send ──► mailbox holds the parent
//!  mbx.receive ──► slot (same parent)
//!  pl.put ──► on_put: count>=cap → release ──► released
//!  │
//!  pl.get (.available_only) ──► recycled (data reset) ──► verify
//!  pl.close ──► on_close ──► destroyQueue
//! ```
//!

pub fn pool_hooks_mailbox_flow(allocator: std.mem.Allocator, io: std.Io) !void {
    // CappedPoolHooks: cap=1 — first put keeps, second put releases.
    var pool_ctx: hooks.CappedPoolHooks = .{ .alloc = allocator, .cap = 1, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, pool_ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var ctx: Ctx = .{ .pl = pl, .mbx = mbx, .alloc = allocator, .io = io };
    try ctx.round1();
    try ctx.round2();
    try ctx.verifyRecycled();
}

const Ctx = struct {
    pl: *Pool,
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,

    fn round1(self: *Ctx) !void {
        {
            var slot: Slot = null;
            defer parents.Event.EventHelper.destroy(self.alloc, self.io, &slot);
            try self.pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
            parents.Event.EventHelper.mustFromSlot(&slot).code = 1;
            std.log.info("on_get: created Event code=1", .{});
            try self.mbx.send(&slot);
        }
        {
            var slot: Slot = null;
            try self.mbx.receive(&slot, null);
            defer parents.destroySlot(&slot, self.alloc, self.io);
            std.log.info("on_put: count<cap → keeping Event code={d}", .{parents.Event.EventHelper.mustFromSlot(&slot).code});
            try self.pl.put(&slot);
        }
    }

    fn round2(self: *Ctx) !void {
        {
            var slot: Slot = null;
            defer parents.Event.EventHelper.destroy(self.alloc, self.io, &slot);
            try self.pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
            parents.Event.EventHelper.mustFromSlot(&slot).code = 2;
            std.log.info("on_get: created fresh Event code=2", .{});
            try self.mbx.send(&slot);
        }
        {
            var slot: Slot = null;
            try self.mbx.receive(&slot, null);
            defer parents.destroySlot(&slot, self.alloc, self.io);
            std.log.info("on_put: count>=cap → releasing Event code={d}", .{parents.Event.EventHelper.mustFromSlot(&slot).code});
            try self.pl.put(&slot);
            // on_put emptied the Slot and released the parent; destroySlot sees null → no-op.
        }
    }

    fn verifyRecycled(self: *Ctx) !void {
        var slot: Slot = null;
        defer self.pl.put(&slot) catch {};
        try self.pl.get(parents.Event.EventHelper.ID, .available_only, &slot);
        const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
        try helpers.expect(error.CrossLayerHooksFailed, ev.code == 0, "expected reset default, not round1's value");
        std.log.info("recycled parent: code={d} (reset by on_put) — hooks decided keep/release correctly", .{ev.code});
    }
};

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
