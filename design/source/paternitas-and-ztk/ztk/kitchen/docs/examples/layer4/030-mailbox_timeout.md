# Timeout on mailbox

## Description

Timeout on mailbox.

- receiveTimeouts calls mbx.receive with a non-null timeout, twice, on an empty mailbox.
- Each call returns error.Timeout; Io.sleep runs between retries.
- sendAndReceive sends one Event, then receives it back within the same timeout.

## Diagram

```
 mailbox (initially empty)
 │
 master: receive(50ms) ──► error.Timeout ──► Io.sleep retry
         receive(50ms) ──► error.Timeout ──► (second retry)
 │
 EventHelper.create ──► slot ──mbx.send──► mailbox
 │
 master: receive(50ms) ──► slot ──► freeSlot
```

## Source

```zig
pub fn timeout_on_mailbox(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var ctx: Ctx = .{ .mbx = mbx, .alloc = allocator, .io = io };
    const retries = try ctx.receiveTimeouts();
    try helpers.expect(error.MailboxTimeoutFailed, retries == 2, "expected 2 timeouts");
    try ctx.sendAndReceive();
    std.log.info("done: {d} timeouts then 1 successful receive", .{retries});
}

const TIMEOUT_NS: u64 = 50_000_000; // 50 ms
const SLEEP_NS: i96 = 10_000_000; // 10 ms between retries

const Ctx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,

    fn receiveTimeouts(self: *Ctx) !usize {
        const sleep_t: std.Io.Timeout = .{
            .duration = .{ .raw = .{ .nanoseconds = SLEEP_NS }, .clock = .real },
        };
        var retries: usize = 0;
        while (retries < 2) {
            var slot: Slot = null;
            self.mbx.receive(&slot, TIMEOUT_NS) catch |err| switch (err) {
                error.Timeout => {
                    retries += 1;
                    std.log.info("receive: .Timeout (retry {d})", .{retries});
                    std.Io.Timeout.sleep(sleep_t, self.io) catch {};
                    continue;
                },
                else => return err,
            };
            defer parents.destroySlot(&slot, self.alloc, self.io);
            std.log.info("receive: got item (unexpected)", .{});
            break;
        }
        return retries;
    }

    fn sendAndReceive(self: *Ctx) !void {
        var slot: Slot = null;
        defer parents.Event.EventHelper.destroy(self.alloc, self.io, &slot);
        try parents.Event.EventHelper.create(self.alloc, self.io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = 9;
        try self.mbx.send(&slot);

        var received: Slot = null;
        defer parents.destroySlot(&received, self.alloc, self.io);
        try self.mbx.receive(&received, TIMEOUT_NS);
        std.log.info("receive after send: code={d}", .{parents.Event.EventHelper.mustFromSlot(&received).code});
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
