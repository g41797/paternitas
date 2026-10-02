# Refused put

## Description

Refused put.

- A pool keeps parents of the ids it was made with, and no others.
- Put into a closed pool is silent: the Slot keeps the parent, and the
  caller releases it.
- Put of an unknown id is error.UnknownIdentity, and the Slot is untouched.
  The same answer in every build.

## Diagram

```
 pl (Event only) ◄── pl.put (Sensor) ──► error.UnknownIdentity
      │ pl.close
      ▼
 pl.put (Event) ──► silent, Slot still full ──► caller releases
```

## Source

```zig
pub fn refused_put(allocator: std.mem.Allocator, io: std.Io) !void {
    var ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer pl.destroy();

    {
        var sensor: Slot = null;
        defer parents.destroySlot(&sensor, allocator, io);
        try parents.Sensor.SensorHelper.create(allocator, io, &sensor);

        const refused = pl.put(&sensor);
        try helpers.expect(error.RefusedPutFailed, refused == error.UnknownIdentity, "expected UnknownIdentity");
        try helpers.expect(error.RefusedPutFailed, sensor != null, "refused put took the parent");
    }

    var slot: Slot = null;
    defer parents.destroySlot(&slot, allocator, io);
    try parents.Event.EventHelper.create(allocator, io, &slot);

    pl.close();

    try pl.put(&slot);
    try helpers.expect(error.RefusedPutFailed, slot != null, "put into a closed pool took the parent");
}

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Slot = matryoshka.inner.Slot;
```
