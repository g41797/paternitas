# Minimal Master

## Description

Minimal Master.

- Master spawns one worker via io.concurrent.
- sendItems pushes 3 Events into the shared mailbox.
- awaitWorker closes the mailbox, frees anything left, awaits the worker.
- Shutdown cleanup uses a plain stdlib list — no Matryoshka-specific cleanup API.

## Diagram

```
 master ──alloc.create──► slot ──mbx.send──► mailbox
                                                     │ worker (io.concurrent)
                                                     │ mbx.receive ──► freeSlot
 mbx.close ──► remaining list ──► freeList
 fut.await ──► worker done
```

## Source

```zig
pub fn minimal_master(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var ctx: WorkerCtx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    var fut = try io.concurrent(workerFn, .{&ctx});
    try sendItems(mbx, allocator, io);
    try awaitWorker(mbx, allocator, io, &fut);
    std.log.info("master: worker done", .{});
}

const WorkerCtx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        ctx.mbx.receive(&slot, null) catch return;
    }
}

fn sendItems(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io) !void {
    for (0..3) |i| {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(alloc, io, &slot);
        try parents.Event.EventHelper.create(alloc, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 1);
        try mbx.send(&slot);
        std.log.info("master: sent Event code={d}", .{i + 1});
    }
}

fn awaitWorker(mbx: *Mbox, alloc: std.mem.Allocator, io: std.Io, fut: *Io.Future(anyerror!void)) !void {
    var remaining: Queue = mbx.close();
    parents.destroyQueue(&remaining, alloc, io);
    try fut.await(io);
}

const parents = @import("../parents/parents.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
const Io = std.Io;
const Queue = matryoshka.queue.Queue;
```
