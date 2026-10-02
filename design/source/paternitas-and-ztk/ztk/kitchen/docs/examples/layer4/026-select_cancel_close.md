# Timer cancel → close → walk remaining

## Description

Timer cancel → close → walk remaining.

- Two mailboxes + timer in Select, both mailboxes empty.
- Timer triggers first, calls sel.cancel() on both mailbox sources.
- Both return .canceled; cancel and close are kept as separate operations.
- Both mailboxes are then closed, remaining items freed via freeList.

## Diagram

```
 mbx1 (empty)    mbx2 (empty)
 │ receiveResult  │ receiveResult
 └────────┬───────┘
          ▼
 Select(MasterEvent) ◄── sleepFn (short timer triggers first)
 │
 .timer ──► sel.cancel() loop
            .inbox1 .canceled ──► log
            .inbox2 .canceled ──► log
 │
 mbx1.close() ──► freeList
 mbx2.close() ──► freeList
```

## Source

```zig
pub fn timer_cancel_close_walk_remaining(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx1_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx1_slot);
    const mbx1: *Mbox = Mbox.moveFromSlot(&mbx1_slot).?;

    var mbx2_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx2_slot);
    const mbx2: *Mbox = Mbox.moveFromSlot(&mbx2_slot).?;
    defer {
        var rem1: Queue = mbx1.close();
        parents.destroyQueue(&rem1, allocator, io);
        mbx1.destroy();
        var rem2: Queue = mbx2.close();
        parents.destroyQueue(&rem2, allocator, io);
        mbx2.destroy();
    }

    var buf: [8]MasterEvent = undefined;
    var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);
    var ctx: Ctx = .{ .mbx1 = mbx1, .mbx2 = mbx2, .alloc = allocator, .io = io };
    try ctx.setupSelect(&sel);
    try Ctx.awaitTimerFirst(&sel);
    ctx.clearCanceled(&sel);

    try helpers.expect(error.SelectCancelCloseFailed, ctx.canceled1 and ctx.canceled2, "expected both inboxes canceled");
    std.log.info("done: timer triggered, sel.cancel() stopped both inbox sources", .{});
}

const TIMER_NS: i96 = 8_000_000; // 8 ms

const MasterEvent = union(enum) {
    inbox1: Mbox.Result,
    inbox2: Mbox.Result,
    timer: void,
};

fn sleepFn(sleep_t: std.Io.Timeout, io: std.Io) void {
    std.Io.Timeout.sleep(sleep_t, io) catch {};
}

const Ctx = struct {
    mbx1: *Mbox,
    mbx2: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
    canceled1: bool = false,
    canceled2: bool = false,

    fn setupSelect(self: *Ctx, sel: *std.Io.Select(MasterEvent)) !void {
        const sleep_t: std.Io.Timeout = .{
            .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
        };
        try sel.concurrent(.inbox1, matryoshka.mbox.receiveResult, .{ self.mbx1, null });
        try sel.concurrent(.inbox2, matryoshka.mbox.receiveResult, .{ self.mbx2, null });
        try sel.concurrent(.timer, sleepFn, .{ sleep_t, self.io });
    }

    fn awaitTimerFirst(sel: *std.Io.Select(MasterEvent)) !void {
        const first: MasterEvent = try sel.await();
        switch (first) {
            .timer => std.log.info("timer: canceling both inbox sources", .{}),
            else => return error.SelectCancelCloseFailed,
        }
    }

    fn clearCanceled(self: *Ctx, sel: *std.Io.Select(MasterEvent)) void {
        while (sel.cancel()) |event| {
            switch (event) {
                .inbox1 => |r| switch (r) {
                    .canceled => {
                        std.log.info("inbox1: .canceled", .{});
                        self.canceled1 = true;
                    },
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        parents.destroySlot(&slot, self.alloc, self.io);
                    },
                    .closed, .timeout, .wakeup => {},
                },
                .inbox2 => |r| switch (r) {
                    .canceled => {
                        std.log.info("inbox2: .canceled", .{});
                        self.canceled2 = true;
                    },
                    .anchor => |handle| {
                        var slot: Slot = handle;
                        parents.destroySlot(&slot, self.alloc, self.io);
                    },
                    .closed, .timeout, .wakeup => {},
                },
                .timer => {},
            }
        }
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
