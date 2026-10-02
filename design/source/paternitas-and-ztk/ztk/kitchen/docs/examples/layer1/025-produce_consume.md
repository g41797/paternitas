# Produce-consume with defer cleanup

## Description

Produce-consume with defer cleanup.

- Append 5 Events to a queue (producer).
- Pop each, sum the codes (consumer).
- defer releases any parents remaining on error, before or after the loop.

## Diagram

```
 create × 5 ──► queue (producer)
      │ queue.popFirst × 5
      ▼
 destroySlot per parent (consumer)
```

## Source

```zig
pub fn produce_consume_with_defer_cleanup(allocator: std.mem.Allocator, io: std.Io) !void {
    var queue: Queue = .{};

    defer parents.destroyQueue(&queue, allocator, io);

    var i: i32 = 0;
    while (i < 5) : (i += 1) {
        var slot: Slot = null;
        try parents.Event.EventHelper.create(allocator, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = i;
        queue.appendFromSlot(&slot);
    }

    var sum: i32 = 0;
    while (queue.popFirst()) |anchor| {
        var slot: Slot = anchor;
        defer parents.destroySlot(&slot, allocator, io);
        const ev: *parents.Event = parents.Event.EventHelper.fromAnchor(anchor) orelse return error.CastFailed;
        sum += ev.code;
    }

    try helpers.expect(error.ProduceConsumeFailed, sum == 0 + 1 + 2 + 3 + 4, "wrong sum");
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
const std = @import("std");
```
