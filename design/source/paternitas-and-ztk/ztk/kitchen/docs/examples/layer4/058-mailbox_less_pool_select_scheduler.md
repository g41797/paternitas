# Pool + Select: job scheduler

## Description

Pool + Select: job scheduler.

- Pool seeded with N empty containers, used as a Select source alongside a timer.
- runEventLoop fills each container with the Master's cycle counter, re-spawns.
- Timer just logs progress from Master state; pool gates the processing rate.
- No mailbox anywhere in this example.

Transfers (mailbox-less):

## Diagram

```
 pool (N_ITEMS empty containers seeded — code=0)
 │ getWaitResult         timer (sleepFn)
 └──────┬────────────────────────┘
        ▼
 Select(MasterEvent)
 │
 .pool_ev .item ──► fill ev.code from Master cycle index ──► pl.put ──► pool
                ──► re-spawn getWaitResult (while cycle < TARGET)
                ──► break (at TARGET, no getWaitResult re-spawned)
 .timer         ──► log cycle from Master state ──► re-spawn timer (while cycle < TARGET)
 │
 sel.cancelDiscard ──► timer cancelled (no items in-flight at this point)
 pl.close ──► on_close ──► freed
```

## Source

```zig
pub fn pool_select_job_scheduler(allocator: std.mem.Allocator, io: std.Io) !void {
    var pool_ctx: hooks.AlwaysCreateHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{parents.Event.EventHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, pool_ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    try seedPool(pl);

    var buf: [8]MasterEvent = undefined;
    var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);
    try setupSelect(pl, io, &sel);

    var cycle: usize = 0;
    var ticks: usize = 0;
    try runEventLoop(pl, io, &sel, &cycle, &ticks);

    try helpers.expect(error.MailboxLessSchedulerFailed, cycle == TARGET, "wrong cycle count");
    std.log.info("done: {d} cycles scheduled by Master counter, {d} timer ticks — Pool+Select, no mailbox", .{ cycle, ticks });
}

const N_ITEMS: usize = 3;
const TARGET: usize = N_ITEMS * 2; // process each container twice
const TIMER_NS: i96 = 20_000_000; // 20 ms

const MasterEvent = union(enum) {
    pool_ev: Pool.Result,
    timer: void,
};

fn sleepFn(sleep_t: std.Io.Timeout, io: std.Io) void {
    std.Io.Timeout.sleep(sleep_t, io) catch {};
}

fn seedPool(pl: *Pool) !void {
    for (0..N_ITEMS) |_| {
        var slot: Slot = null;
        try pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
        try pl.put(&slot);
    }
}

fn setupSelect(pl: *Pool, io: std.Io, sel: *std.Io.Select(MasterEvent)) !void {
    const sleep_t: std.Io.Timeout = .{
        .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
    };
    try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ pl, parents.Event.EventHelper.ID, null });
    try sel.concurrent(.timer, sleepFn, .{ sleep_t, io });
}

fn runEventLoop(pl: *Pool, io: std.Io, sel: *std.Io.Select(MasterEvent), cycle: *usize, ticks: *usize) !void {
    while (true) {
        const event: MasterEvent = try sel.await();
        switch (event) {
            .pool_ev => |r| switch (r) {
                .anchor => |handle| {
                    var slot: Slot = handle;
                    defer pl.put(&slot) catch unreachable;
                    const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
                    ev.code = @intCast(cycle.*);
                    cycle.* += 1;
                    std.log.info("pool_ev: filled container with cycle index={d} ({d}/{d})", .{ ev.code, cycle.*, TARGET });
                    if (cycle.* < TARGET) {
                        try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ pl, parents.Event.EventHelper.ID, null });
                    } else {
                        break;
                    }
                },
                .closed, .canceled, .timeout, .unknown_identity => break,
            },
            .timer => {
                ticks.* += 1;
                std.log.info("timer tick {d}: maintenance — cycles so far: {d}", .{ ticks.*, cycle.* });
                if (cycle.* < TARGET) {
                    const sleep_t: std.Io.Timeout = .{
                        .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
                    };
                    try sel.concurrent(.timer, sleepFn, .{ sleep_t, io });
                }
            },
        }
    }
    sel.cancelDiscard();
}

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Pool = matryoshka.Pool;
const TypeId = matryoshka.inner.TypeId;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
```
