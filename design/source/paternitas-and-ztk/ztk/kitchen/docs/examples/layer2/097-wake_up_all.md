# Wake blocked receiver without a message

## Description

Wake blocked receiver without a message.

- Worker thread blocks in mbx.receive with no item ever sent.
- Coordinator flips a shutdown flag, then calls mbx.wakeUpAll —
  no item is sent, no message crosses the mailbox.
- Worker wakes with error.Wakeup, re-checks the flag, exits.

## Diagram

```
 worker thread
 mbx.receive (blocks — mailbox stays empty)
      │
 coordinator: shutdown.store(true) ──► mbx.wakeUpAll
      │ error.Wakeup
      ▼
 worker re-checks shutdown flag ──► exits
```

## Source

```zig
pub fn wake_blocked_receiver_without_a_message(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: matryoshka.queue.Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var ctx: WorkerCtx = .{ .mbx = mbx };
    var fut = try io.concurrent(workerFn, .{&ctx});

    // Give the worker time to reach mbx.receive and block.
    std.Io.Timeout.sleep(.{ .duration = .{ .raw = .{ .nanoseconds = 50_000_000 }, .clock = .real } }, io) catch {};

    ctx.shutdown.store(true, .release);
    try mbx.wakeUpAll();

    fut.await(io);

    std.log.info("wake up all: worker woke on error.Wakeup, saw shutdown flag, exited", .{});
    try helpers.expect(error.WakeUpAllFailed, ctx.woke_on_wakeup, "worker did not see error.Wakeup");
}

const WorkerCtx = struct {
    mbx: *Mbox,
    shutdown: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    woke_on_wakeup: bool = false,
};

fn workerFn(ctx: *WorkerCtx) void {
    var slot: Slot = null;
    ctx.mbx.receive(&slot, null) catch |err| {
        if (err == error.Wakeup and ctx.shutdown.load(.acquire)) {
            ctx.woke_on_wakeup = true;
        }
        return;
    };
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
```
