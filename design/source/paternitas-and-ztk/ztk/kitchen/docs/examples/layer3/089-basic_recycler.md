# Basic recycler

## Description

Basic recycler.

- Create a pool with hooks for the Event id.
- pl.get with available_or_new makes a fresh parent through on_get.
- pl.put returns it — the hook resets it to defaults on put.
- pl.get again recycles the same parent, now holding default data.

## Diagram

```
 pl.get (available_or_new) ──► slot (new via on_get)
      │ pl.put ──► on_put resets data ──► pool (recycled)
      │ pl.get (available_or_new) ──► slot (same parent, data reset)
      │ EventHelper.destroy ──► released
```

## Source

```zig
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
```
