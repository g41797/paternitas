# Pool + Select + Network

## Description

Pool + Select + Network.

- Pool seeded with items, a mock network read runs alongside it in Select.
- Two independent event sources: pool availability and simulated network data.
- Both re-spawn until their target counts are met; no mailbox anywhere.

Transfers (mailbox-less):

## Diagram

```
 pool (seeded)            mock network (sleepFn)
 │ getWaitResult           │ networkReadFn
 └──────────┬──────────────┘
            ▼
 Select(MasterEvent)
 │
 .pool_ev .item ──► process ──► pl.put ──► pool (re-spawn)
 .network       ──► log receipt ──► re-spawn (until targets met)
 │
 sel.cancelDiscard ──► pl.close ──► on_close ──► freed
```

## Source

```zig
pub fn pool_select_network(allocator: std.mem.Allocator, io: std.Io) !void {
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

    var pool_done: usize = 0;
    var net_done: usize = 0;
    try runEventLoop(pl, io, &sel, &pool_done, &net_done);

    try helpers.expect(error.MailboxLessNetworkFailed, pool_done == N_POOL_ITEMS, "pool items not all processed");
    try helpers.expect(error.MailboxLessNetworkFailed, net_done == N_NET_ROUNDS, "network rounds not complete");
    std.log.info("done: pool={d} net={d} — Pool+Select+Network, no mailbox", .{ pool_done, net_done });
}

const NET_DELAY_NS: i96 = 15_000_000; // 15 ms simulated network latency
const N_POOL_ITEMS: usize = 2;
const N_NET_ROUNDS: usize = 2;

const NetworkResult = struct { bytes: usize };

const MasterEvent = union(enum) {
    pool_ev: Pool.Result,
    network: NetworkResult,
};

fn seedPool(pl: *Pool) !void {
    for (0..N_POOL_ITEMS) |i| {
        var slot: Slot = null;
        try pl.get(parents.Event.EventHelper.ID, .new_only, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 1);
        try pl.put(&slot);
    }
}

fn networkReadFn(delay: std.Io.Timeout, io: std.Io) NetworkResult {
    std.Io.Timeout.sleep(delay, io) catch {};
    return .{ .bytes = 64 };
}

fn setupSelect(pl: *Pool, io: std.Io, sel: *std.Io.Select(MasterEvent)) !void {
    const net_delay: std.Io.Timeout = .{
        .duration = .{ .raw = .{ .nanoseconds = NET_DELAY_NS }, .clock = .real },
    };
    try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ pl, parents.Event.EventHelper.ID, null });
    try sel.concurrent(.network, networkReadFn, .{ net_delay, io });
}

fn runEventLoop(pl: *Pool, io: std.Io, sel: *std.Io.Select(MasterEvent), pool_done: *usize, net_done: *usize) !void {
    while (pool_done.* < N_POOL_ITEMS or net_done.* < N_NET_ROUNDS) {
        const event: MasterEvent = try sel.await();
        switch (event) {
            .pool_ev => |r| switch (r) {
                .anchor => |handle| {
                    var slot: Slot = handle;
                    defer pl.put(&slot) catch unreachable;
                    const ev: *parents.Event = parents.Event.EventHelper.mustFromSlot(&slot);
                    ev.code += 10;
                    pool_done.* += 1;
                    std.log.info("pool_ev: processed code={d} ({d}/{d})", .{ ev.code, pool_done.*, N_POOL_ITEMS });
                    if (pool_done.* < N_POOL_ITEMS) {
                        try sel.concurrent(.pool_ev, matryoshka.pool.getWaitResult, .{ pl, parents.Event.EventHelper.ID, null });
                    }
                },
                .closed, .canceled, .timeout, .unknown_identity => break,
            },
            .network => |r| {
                net_done.* += 1;
                std.log.info("network: {d} bytes received ({d}/{d})", .{ r.bytes, net_done.*, N_NET_ROUNDS });
                if (net_done.* < N_NET_ROUNDS) {
                    const net_delay: std.Io.Timeout = .{
                        .duration = .{ .raw = .{ .nanoseconds = NET_DELAY_NS }, .clock = .real },
                    };
                    try sel.concurrent(.network, networkReadFn, .{ net_delay, io });
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
