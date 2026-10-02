# Cancel reports, Master decides

## Description

Cancel reports, Master decides.

- Phase 1: two mailboxes in Select, timer triggers first (both empty).
- sel.cancel() reports both as .canceled — mailboxes stay open.
- Master decides: close mbx1 permanently, keep mbx2 for phase 2.
- Phase 2: fresh Select on mbx2 only, sends and receives 2 items.

## Diagram

```
 mbx1 (empty)    mbx2 (empty)
 │ receiveResult  │ receiveResult
 └────────┬───────┘
           ▼
 Select(MasterEvent) ◄── sleepFn (timer triggers first — both mailboxes empty)
 │
 .timer ──► sel.cancel() loop
            .inbox1 .canceled ──► master decides: close mbx1 permanently
            .inbox2 .canceled ──► master decides: keep mbx2, re-spawn later
 │
 Phase 2: new Select, mbx2 only
 send 2 items to mbx2 ──► receive them via fresh Select
```

## Source

```zig
pub fn cancel_reports_master_decides(allocator: std.mem.Allocator, io: std.Io) !void {
    const master = try CancelDecideMaster.init(allocator, io);
    defer master.destroy();
    try master.run();
}

const TIMER_NS: i96 = 6_000_000; // 6 ms — triggers first (both mailboxes are empty)

const MasterEvent = union(enum) {
    inbox1: Mbox.Result,
    inbox2: Mbox.Result,
    timer: void,
};

fn sleepFn(sleep_t: std.Io.Timeout, io: std.Io) void {
    std.Io.Timeout.sleep(sleep_t, io) catch {};
}

const CancelDecideMaster = struct {
    fn run(self: *CancelDecideMaster) !void {
        const respawn_inbox2: bool = try self.phase1Cancel();
        try helpers.expect(error.SelectCancelMasterDecidesFailed, self.mbx1_closed, "mbx1 should be closed");
        try helpers.expect(error.SelectCancelMasterDecidesFailed, respawn_inbox2, "expected inbox2 to be canceled");
        const items_after: usize = try self.phase2Receive();
        try helpers.expect(error.SelectCancelMasterDecidesFailed, items_after == 2, "expected 2 items from mbx2 in phase 2");
        std.log.info("done: mbx1 closed; mbx2 continued with {d} items in phase 2", .{items_after});
    }

    fn phase1Cancel(self: *CancelDecideMaster) !bool {
        const sleep_t: std.Io.Timeout = .{
            .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
        };
        var buf: [8]MasterEvent = undefined;
        var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(self.io, &buf);
        defer sel.cancelDiscard();

        try sel.concurrent(.inbox1, matryoshka.mbox.receiveResult, .{ self.mbx1, null });
        try sel.concurrent(.inbox2, matryoshka.mbox.receiveResult, .{ self.mbx2, null });
        try sel.concurrent(.timer, sleepFn, .{ sleep_t, self.io });

        const first: MasterEvent = try sel.await();
        try helpers.expect(error.SelectCancelMasterDecidesFailed, first == .timer, "expected timer to trigger first");
        std.log.info("timer: making per-source decisions", .{});

        var respawn_inbox2: bool = false;
        while (sel.cancel()) |event| {
            switch (event) {
                .inbox1 => |r| switch (r) {
                    .canceled, .closed => {
                        std.log.info("inbox1: stopped — master closes mbx1", .{});
                        var rem: Queue = self.mbx1.close();
                        parents.destroyQueue(&rem, self.allocator, self.io);
                        self.mbx1_closed = true;
                    },
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        parents.destroySlot(&slot, self.allocator, self.io);
                    },
                    .timeout, .wakeup => {},
                },
                .inbox2 => |r| switch (r) {
                    .canceled => {
                        std.log.info("inbox2: canceled — master will continue using mbx2", .{});
                        respawn_inbox2 = true;
                    },
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        parents.destroySlot(&slot, self.allocator, self.io);
                    },
                    .closed, .timeout, .wakeup => {},
                },
                .timer => {},
            }
        }
        return respawn_inbox2;
    }

    fn phase2Receive(self: *CancelDecideMaster) !usize {
        for (0..2) |i| {
            var slot: Slot = null;
            defer parents.Event.EventHelper.destroy(self.allocator, self.io, &slot);
            try parents.Event.EventHelper.create(self.allocator, self.io, &slot);
            parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 10);
            try self.mbx2.send(&slot);
        }

        var buf2: [4]MasterEvent = undefined;
        var sel2: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(self.io, &buf2);
        defer sel2.cancelDiscard();

        try sel2.concurrent(.inbox2, matryoshka.mbox.receiveResult, .{ self.mbx2, null });

        var items_after: usize = 0;
        while (items_after < 2) {
            const event: MasterEvent = try sel2.await();
            switch (event) {
                .inbox2 => |r| switch (r) {
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        defer parents.destroySlot(&slot, self.allocator, self.io);
                        items_after += 1;
                        std.log.info("inbox2 phase2: item code={d}", .{parents.Event.EventHelper.mustFromSlot(&slot).code});
                        if (items_after < 2) {
                            try sel2.concurrent(.inbox2, matryoshka.mbox.receiveResult, .{ self.mbx2, null });
                        }
                    },
                    .closed, .canceled, .timeout, .wakeup => break,
                },
                else => break,
            }
        }
        return items_after;
    }

    allocator: std.mem.Allocator,
    io: std.Io,
    mbx1: *Mbox,
    mbx2: *Mbox,
    mbx1_closed: bool,

    fn init(allocator: std.mem.Allocator, io: std.Io) !*CancelDecideMaster {
        const self = try allocator.create(CancelDecideMaster);
        errdefer allocator.destroy(self);
        self.allocator = allocator;
        self.io = io;
        self.mbx1_closed = false;

        var mbx1_slot: Slot = null;
        try matryoshka.mbox.new(allocator, io, &mbx1_slot);
        self.mbx1 = Mbox.moveFromSlot(&mbx1_slot).?;
        errdefer {
            var rem: Queue = self.mbx1.close();
            parents.destroyQueue(&rem, allocator, io);
            self.mbx1.destroy();
        }

        var mbx2_slot: Slot = null;
        try matryoshka.mbox.new(allocator, io, &mbx2_slot);
        self.mbx2 = Mbox.moveFromSlot(&mbx2_slot).?;
        return self;
    }

    fn destroy(self: *CancelDecideMaster) void {
        if (!self.mbx1_closed) {
            var rem: Queue = self.mbx1.close();
            parents.destroyQueue(&rem, self.allocator, self.io);
        }
        self.mbx1.destroy();
        var rem2: Queue = self.mbx2.close();
        parents.destroyQueue(&rem2, self.allocator, self.io);
        self.mbx2.destroy();
        self.allocator.destroy(self);
    }
};

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
const Queue = matryoshka.queue.Queue;
```
