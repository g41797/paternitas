// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Pool holds pools at teardown.
//!
//! - A carrier pool's hooks accept Pool parents (Pool.ID).
//! - Two inner pools are stored in the carrier via put.
//! - close on the carrier hands the stored pools to on_close, which closes and destroys each.
//! - Shows uniform cleanup of infrastructure parents — no per-instance role discrimination needed.
//!
//!
//! ```
//!  newPool × 2 ──► carrier.put ──► carrier pool (holds inner pools as parents)
//!       │ carrier.close
//!       ▼
//!  on_close ──► close + destroy per inner pool
//! ```
//!

pub fn pool_holds_pools_at_teardown(allocator: std.mem.Allocator, io: std.Io) !void {
    // Carrier pool — holds inner pools as parents.
    var carrier_ctx: CarrierCtx = .{ .alloc = allocator };
    const carrier_ids = [_]TypeId{Pool.ID};

    var carrier_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &carrier_ids, .{
        .ctx = &carrier_ctx,
        .on_get = onGet,
        .on_put = onPut,
        .on_close = onClose,
    }, &carrier_slot);
    const carrier: *Pool = Pool.moveFromSlot(&carrier_slot).?;

    const n: usize = 2;
    var ctx: Ctx = .{
        .carrier = carrier,
        .alloc = allocator,
        .io = io,
        .inner_ctx = .{ .alloc = allocator },
    };
    try ctx.createAndStoreInnerPools(n);
    try ctx.closeCarrier(&carrier_ctx, n);
}

const inner_ids = [_]TypeId{Pool.ID};

const CarrierCtx = struct {
    alloc: std.mem.Allocator,
    closed_count: usize = 0,
};

fn onGet(_: *anyopaque, _: TypeId, _: usize, _: *Slot) void {}

fn onPut(_: *anyopaque, _: usize, _: *Slot, _: *Queue) void {}

fn onClose(ctx_opaque: *anyopaque, remaining: Queue) void {
    const ctx: *CarrierCtx = @ptrCast(@alignCast(ctx_opaque));
    var rest = remaining;
    while (rest.popFirst()) |anchor| {
        const pl: *Pool = Pool.mustFromAnchor(anchor);
        pl.close();
        pl.destroy();
        ctx.closed_count += 1;
    }
    std.log.info("on_close: closed and destroyed {d} inner pool(s)", .{ctx.closed_count});
}

const Ctx = struct {
    carrier: *Pool,
    alloc: std.mem.Allocator,
    io: std.Io,
    inner_ctx: CarrierCtx,

    /// Hooks for an inner pool.
    ///
    /// An inner pool is cargo: it is created, stored in the carrier and closed
    /// at teardown, and no parent ever passes through it. It still needs a full
    /// hook set, because `newPool` registers one and `close` calls `on_close`.
    fn innerHooks(self: *Ctx) Pool.Hooks {
        return .{
            .ctx = &self.inner_ctx,
            .on_get = onGet,
            .on_put = onPut,
            .on_close = onClose,
        };
    }

    fn createAndStoreInnerPools(self: *Ctx, n: usize) !void {
        var j: usize = 0;
        while (j < n) : (j += 1) {
            var slot: Slot = null;
            try matryoshka.pool.new(self.alloc, self.io, &inner_ids, self.innerHooks(), &slot);
            try self.carrier.put(&slot);
            try helpers.expect(error.PoolAsItemFailed, slot == null, "carrier did not accept inner pool");
            std.log.info("stored inner pool {d} in carrier", .{j + 1});
        }
    }

    fn closeCarrier(self: *Ctx, carrier_ctx: *CarrierCtx, n: usize) !void {
        // Id dispatch is not needed here: every parent is a pool by construction.
        self.carrier.close();
        try helpers.expect(error.PoolAsItemFailed, carrier_ctx.closed_count == n, "wrong number of inner pools cleaned up");
        std.log.info("carrier closed: {d} inner pool(s) cleaned up", .{carrier_ctx.closed_count});
        self.carrier.destroy();
    }
};

const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
