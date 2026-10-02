# ConcurrencyUnavailable on single-threaded

## Description

ConcurrencyUnavailable on single-threaded.

- On a single-threaded Io backend, mbx.receive_future returns error.ConcurrencyUnavailable.
- No concurrent task can be spawned to service the future.
- Synchronous mbx.receive still works — it needs no concurrency.

## Diagram

```
 mailbox (single-threaded io)
 │
 receive_future ──► error.ConcurrencyUnavailable
 (no concurrent task can be spawned on single-threaded backend)
 │
 mbx.receive (synchronous) still works
```

## Source

```zig
pub fn concurrencyunavailable_on_single_threaded(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    try testFutureUnavailable(mbx);
    try testSynchronousReceive(mbx, allocator, io);
}

fn testFutureUnavailable(mbx: *Mbox) !void {
    if (mbx.receiveFuture(null)) |_| {
        return error.FutureSingleThreadedFailed;
    } else |_| {}
    std.log.info("receive_future: ConcurrencyUnavailable on single-threaded backend as expected", .{});
}

fn testSynchronousReceive(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    var slot: Slot = null;
    defer parents.Event.EventHelper.destroy(alloc, io, &slot);
    try parents.Event.EventHelper.create(alloc, io, &slot);
    parents.Event.EventHelper.mustFromSlot(&slot).code = 1;
    try mbx.send(&slot);

    var received: Slot = null;
    defer parents.destroySlot(&received, alloc, io);
    try mbx.receive(&received, null);
    std.log.info("synchronous receive still works: code={d}", .{parents.Event.EventHelper.mustFromSlot(&received).code});
}

const parents = @import("../parents/parents.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
```
