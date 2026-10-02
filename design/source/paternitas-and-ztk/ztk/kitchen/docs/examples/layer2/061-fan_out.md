# Fan-out

## Description

Fan-out.

- Main sends 5 Events and 4 Sensors into one mailbox.
- 3 worker threads share the mailbox, compete for items.
- Main closes the mailbox, frees any items left unclaimed.
- Verifies every item was either received or freed.

## Diagram

```
 main ──Event×5 + Sensor×4──► mailbox ──► worker A
                                     ├──► worker B  (compete; each item goes to one)
                                     └──► worker C
 mbx.close ──► remaining queue ──► destroySlot (main)
```

## Source

```zig
pub fn fan_out(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer mbx.destroy();

    var ctx_a: WorkerCtx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    var ctx_b: WorkerCtx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    var ctx_c: WorkerCtx = .{ .mbx = mbx, .alloc = allocator, .io = io };

    var fa = try io.concurrent(fanOutWorkerFn, .{&ctx_a});
    var fb = try io.concurrent(fanOutWorkerFn, .{&ctx_b});
    var fc = try io.concurrent(fanOutWorkerFn, .{&ctx_c});

    const n_events: usize = 5;
    const n_sensors: usize = 4;

    var i: usize = 0;
    while (i < n_events) : (i += 1) {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(allocator, io, &slot);
        try parents.Event.EventHelper.create(allocator, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i);
        try mbx.send(&slot);
    }

    i = 0;
    while (i < n_sensors) : (i += 1) {
        var slot: Slot = null;
        defer parents.Sensor.SensorHelper.destroy(allocator, io, &slot);
        try parents.Sensor.SensorHelper.create(allocator, io, &slot);
        parents.Sensor.SensorHelper.mustFromSlot(&slot).value = @as(f64, @floatFromInt(i));
        try mbx.send(&slot);
    }

    var rem: matryoshka.queue.Queue = mbx.close();
    var remaining: usize = 0;
    while (rem.popFirst()) |anchor| {
        {
            var s: Slot = anchor;
            parents.destroySlot(&s, allocator, io);
        }
        remaining += 1;
    }

    fa.await(io);
    fb.await(io);
    fc.await(io);

    const total: usize = ctx_a.received + ctx_b.received + ctx_c.received;
    std.log.info("fan-out: a={d} b={d} c={d} remaining={d}", .{ ctx_a.received, ctx_b.received, ctx_c.received, remaining });
    try helpers.expect(error.FanOutFailed, total + remaining == n_events + n_sensors, "wrong total");
}

const WorkerCtx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
    received: usize = 0,
};

fn fanOutWorkerFn(ctx: *WorkerCtx) void {
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        ctx.mbx.receive(&slot, null) catch return;
        ctx.received += 1;
    }
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
```
