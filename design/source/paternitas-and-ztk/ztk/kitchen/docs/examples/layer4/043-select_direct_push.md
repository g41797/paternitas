# Select direct queue push

## Description

Select direct queue push.

- A separate thread pushes a value directly into the Select queue via putOneUncancelable.
- This bypasses the usual sel.concurrent path — it's a raw queue push.
- sel.await() receives the .direct value directly, then cancels the blocked inbox source.

## Diagram

```
 wild thread ──sel.queue.putOneUncancelable──► Select queue
              (bypasses concurrent fn mechanism)
 │
 sel.await() ──► .direct u32 value
 │
 sel.cancelDiscard() ──► cancels blocking .inbox source
```

## Source

```zig
pub fn select_direct_queue_push(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var buf: [4]MasterEvent = undefined;
    var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);
    var pusher_fut = try setupSourcesAndPusher(mbx, io, &sel);
    try awaitDirectPushAndShutdown(&sel, &pusher_fut, io);
    std.log.info("done: direct push bypassed concurrent fn path", .{});
}

const MasterEvent = union(enum) {
    inbox: Mbox.Result,
    direct: u32,
};

fn pusherFn(sel_ptr: *std.Io.Select(MasterEvent)) void {
    sel_ptr.queue.putOneUncancelable(sel_ptr.io, .{ .direct = 99 }) catch {};
}

fn setupSourcesAndPusher(mbx: *Mbox, io: std.Io, sel: *std.Io.Select(MasterEvent)) !std.Io.Future(void) {
    try sel.concurrent(.inbox, matryoshka.mbox.receiveResult, .{ mbx, null });
    return io.concurrent(pusherFn, .{sel});
}

fn awaitDirectPushAndShutdown(sel: *std.Io.Select(MasterEvent), pusher_fut: *std.Io.Future(void), io: std.Io) !void {
    const event: MasterEvent = try sel.await();
    switch (event) {
        .direct => |v| {
            try helpers.expect(error.SelectDirectPushFailed, v == 99, "wrong direct push value");
            std.log.info("direct push: received {d}", .{v});
        },
        .inbox => return error.SelectDirectPushFailed,
    }
    pusher_fut.await(io);
    sel.cancelDiscard();
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
```
