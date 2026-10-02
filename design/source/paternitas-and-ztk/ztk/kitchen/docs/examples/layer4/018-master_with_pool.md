# Master with Pool

## Description

Master with Pool.

- Master owns a pool (with hooks) and a mailbox.
- sendItems fills 3 pool items with Event data, sends each into the mailbox.
- Worker loops on mbx.receive, returns each item to the pool via pl.put.
- Shutdown cancels the worker future, then destroy releases pool and mailbox in order.

## Diagram

```
 master ──pl.get──► slot ──mbx.send──► mailbox
                                                │ worker (io.concurrent)
                                                │ mbx.receive ──► slot
                                                │ pl.put (defer) ──► pool (recycled)
 fut.cancel ──► worker exits at next mbx.receive
 master.destroy ──► pl.close ──► mbx.close ──► free remaining
```

## Source

```zig
pub fn master_with_pool(allocator: std.mem.Allocator, io: std.Io) !void {
    const master = try MasterWithPool.init(allocator, io);
    defer master.destroy();
    try master.run();
}

const WorkerCtx = struct {
    mbx: *Mbox,
    pl: *Pool,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        defer ctx.pl.put(&slot) catch {};
        ctx.mbx.receive(&slot, null) catch return;
    }
}

const MasterWithPool = struct {
    fn run(self: *MasterWithPool) !void {
        try self.sendItems();
        var fut = try self.io.concurrent(workerFn, .{&self.worker_ctx});
        fut.cancel(self.io) catch {};
        std.log.info("master: worker stopped", .{});
    }

    fn sendItems(self: *MasterWithPool) !void {
        for (0..3) |i| {
            var slot: Slot = null;
            defer self.pl.put(&slot) catch {};
            try self.pl.get(parents.Event.EventHelper.ID, .available_or_new, &slot);
            const ev = parents.Event.EventHelper.mustFromSlot(&slot);
            ev.code = @intCast(i + 1);
            std.log.info("master: sending Event code={d}", .{ev.code});
            try self.mbx.send(&slot);
        }
    }

    allocator: std.mem.Allocator,
    io: std.Io,
    pool_ctx: hooks.AlwaysCreateHooks,
    ids: [1]matryoshka.inner.TypeId,
    pl: *Pool,
    mbx: *Mbox,
    worker_ctx: WorkerCtx,

    fn init(allocator: std.mem.Allocator, io: std.Io) !*MasterWithPool {
        const self = try allocator.create(MasterWithPool);
        errdefer allocator.destroy(self);
        self.allocator = allocator;
        self.io = io;
        self.pool_ctx = .{ .alloc = allocator, .io = io };
        self.ids = .{parents.Event.EventHelper.ID};

        var pl_slot: Slot = null;
        try matryoshka.pool.new(allocator, io, &self.ids, self.pool_ctx.poolHooks(), &pl_slot);
        self.pl = Pool.moveFromSlot(&pl_slot).?;
        errdefer {
            self.pl.close();
            self.pl.destroy();
        }

        var mbx_slot: Slot = null;
        try matryoshka.mbox.new(allocator, io, &mbx_slot);
        self.mbx = Mbox.moveFromSlot(&mbx_slot).?;

        self.worker_ctx = .{ .mbx = self.mbx, .pl = self.pl };
        return self;
    }

    fn destroy(self: *MasterWithPool) void {
        self.pl.close();
        self.pl.destroy();
        var rem: Queue = self.mbx.close();
        parents.destroyQueue(&rem, self.allocator, self.io);
        self.mbx.destroy();
        self.allocator.destroy(self);
    }
};

const parents = @import("../parents/parents.zig");
const hooks = @import("../hooks/hooks.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Pool = matryoshka.Pool;
const Slot = matryoshka.inner.Slot;
const Queue = matryoshka.queue.Queue;
```
