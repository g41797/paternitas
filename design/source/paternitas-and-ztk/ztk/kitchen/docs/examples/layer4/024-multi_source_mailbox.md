# Multiple event sources, one mailbox

## Description

Multiple event sources, one mailbox.

- Timer task, event sender, and signal sender all send into one mailbox.
- Worker has a single receive loop, dispatches on id.
- Senders finish, then the mailbox is closed to end the worker.
- Ctx groups the flow: spawnSenders, then awaitSendersAndClose.

## Diagram

```
 timerSenderFn ──Timer×2──►
 eventSenderFn ──Event×3──► mailbox ──► workerFn (id dispatch; close-based exit)
 signalSenderFn ──ShutdownCommand──►
 senders await → mbx.close → workerFn exits → fut_worker.await
```

## Source

```zig
pub fn multiple_event_sources_one_mailbox(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var sender_ctx: SenderCtx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    var worker_ctx: WorkerCtx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    var ctx: Ctx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    var futs = try ctx.spawnSenders(&sender_ctx, &worker_ctx);
    ctx.awaitSendersAndClose(&futs);

    std.log.info("done: {d} events, {d} timer ticks, {d} signals — fan-in to one mailbox", .{
        worker_ctx.event_count,
        worker_ctx.timer_count,
        worker_ctx.signal_count,
    });
}

const TICK_NS: i96 = 20_000_000; // 20 ms
const N_EVENTS: usize = 3;
const N_TICKS: usize = 2;

const SenderCtx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
};

fn timerSenderFn(ctx: *SenderCtx) anyerror!void {
    const sleep_t: std.Io.Timeout = .{
        .duration = .{ .raw = .{ .nanoseconds = TICK_NS }, .clock = .real },
    };
    for (0..N_TICKS) |_| {
        try std.Io.Timeout.sleep(sleep_t, ctx.io);
        var slot: Slot = null;
        try parents.Timer.TimerHelper.create(ctx.alloc, ctx.io, &slot);
        ctx.mbx.send(&slot) catch {
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
            return;
        };
    }
}

fn eventSenderFn(ctx: *SenderCtx) anyerror!void {
    for (0..N_EVENTS) |i| {
        var slot: Slot = null;
        try parents.Event.EventHelper.create(ctx.alloc, ctx.io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 1);
        ctx.mbx.send(&slot) catch {
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
            return;
        };
    }
}

fn signalSenderFn(ctx: *SenderCtx) anyerror!void {
    var slot: Slot = null;
    try parents.ShutdownCommand.ShutdownCommandHelper.create(ctx.alloc, ctx.io, &slot);
    ctx.mbx.send(&slot) catch parents.destroySlot(&slot, ctx.alloc, ctx.io);
}

const WorkerCtx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
    timer_count: usize = 0,
    event_count: usize = 0,
    signal_count: usize = 0,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        ctx.mbx.receive(&slot, null) catch return;

        if (parents.Timer.TimerHelper.fromSlot(&slot)) |_| {
            ctx.timer_count += 1;
            std.log.info("worker: timer tick {d}", .{ctx.timer_count});
        } else if (parents.Event.EventHelper.fromSlot(&slot)) |ev| {
            ctx.event_count += 1;
            std.log.info("worker: Event code={d}", .{ev.code});
        } else if (parents.ShutdownCommand.ShutdownCommandHelper.fromSlot(&slot)) |_| {
            ctx.signal_count += 1;
            std.log.info("worker: ShutdownCommand signal", .{});
        }
    }
}

const Futs = struct {
    timer: Io.Future(anyerror!void),
    events: Io.Future(anyerror!void),
    signal: Io.Future(anyerror!void),
    worker: Io.Future(anyerror!void),
};

const Ctx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,

    fn spawnSenders(self: *Ctx, sender_ctx: *SenderCtx, worker_ctx: *WorkerCtx) !Futs {
        return .{
            .timer = try self.io.concurrent(timerSenderFn, .{sender_ctx}),
            .events = try self.io.concurrent(eventSenderFn, .{sender_ctx}),
            .signal = try self.io.concurrent(signalSenderFn, .{sender_ctx}),
            .worker = try self.io.concurrent(workerFn, .{worker_ctx}),
        };
    }

    fn awaitSendersAndClose(self: *Ctx, futs: *Futs) void {
        futs.timer.await(self.io) catch {};
        futs.events.await(self.io) catch {};
        futs.signal.await(self.io) catch {};

        var remaining: Queue = self.mbx.close();
        parents.destroyQueue(&remaining, self.alloc, self.io);

        futs.worker.await(self.io) catch {};
    }
};

const parents = @import("../parents/parents.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
const Io = std.Io;
const Queue = matryoshka.queue.Queue;
```
