// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Pool seeding.
//!
//! - Seed the pool with 5 Sensors via get (new_only) + pl.put.
//! - Take all 5 with available_only — nothing is made.
//! - Release each one, verify the count.
//!
//!
//! ```
//!  pl.get (new_only) × 5 ──► pl.put × 5
//!  (pool holds 5 parents)
//!       │ pl.get (available_only) × 5
//!       ▼
//!  slot ──► SensorHelper.destroy per parent
//! ```
//!

pub fn pool_seeding(allocator: std.mem.Allocator, io: std.Io) !void {
    var ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Sensor.SensorHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    const n: usize = 5;

    // Seed: new_only forces the hook to make each one.
    var i: usize = 0;
    while (i < n) : (i += 1) {
        var slot: Slot = null;
        defer pl.put(&slot) catch {};
        try pl.get(parents.Sensor.SensorHelper.ID, .new_only, &slot);
        const sn = parents.Sensor.SensorHelper.mustFromSlot(&slot);
        sn.value = @as(f64, @floatFromInt(i)) * 0.1;
    }
    std.log.info("seeded {d} Sensors into pool", .{n});
    try helpers.expect(error.PoolSeedingFailed, (try pl.countOf(parents.Sensor.SensorHelper.ID)) == n, "wrong stored count");

    // Consume: available_only takes stored parents — nothing is made.
    var consumed: usize = 0;
    while (true) {
        var slot: Slot = null;
        defer parents.Sensor.SensorHelper.destroy(allocator, io, &slot);
        pl.get(parents.Sensor.SensorHelper.ID, .available_only, &slot) catch break;
        std.log.info("consumed Sensor", .{});
        consumed += 1;
    }
    try helpers.expect(error.PoolSeedingFailed, consumed == n, "wrong consumed count");
}

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Slot = matryoshka.inner.Slot;
