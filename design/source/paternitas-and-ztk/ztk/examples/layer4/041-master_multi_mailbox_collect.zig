// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Master pre-shutdown collect.
//!
//! - Fill mailbox_a with 2 Events, mailbox_b with 3 Sensors.
//! - closeAndMerge closes both, merges the queues with concat.
//! - collectAndRelease walks the combined queue once, releases every parent.
//!
//!
//! ```
//!  mailbox_a (2 items)    mailbox_b (3 items)
//!  │
//!  mailbox_a.close ──► list_a (Queue, 2 parents)
//!  mailbox_b.close ──► list_b (Queue, 3 parents)
//!  list_a.concat(&list_b) ──► combined (5 items)
//!  walk combined: popFirst ──► destroySlot (×5)
//!  │
//!  One walk handles parents from multiple mailboxes — no special API.
//! ```
//!

pub fn master_pre_shutdown_collect(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_a_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_a_slot);
    const mbx_a: *Mbox = Mbox.moveFromSlot(&mbx_a_slot).?;

    var mbx_b_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_b_slot);
    const mbx_b: *Mbox = Mbox.moveFromSlot(&mbx_b_slot).?;

    var ctx: Ctx = .{ .mbx_a = mbx_a, .mbx_b = mbx_b, .alloc = allocator, .io = io };
    try ctx.fillMailboxA();
    try ctx.fillMailboxB();
    std.log.info("before collect: {d} in mailbox_a, {d} in mailbox_b", .{ N_A, N_B });

    var combined: Queue = ctx.closeAndMerge();
    const freed = collectAndRelease(&combined, allocator, io);

    try helpers.expect(error.MasterMultiMailboxFailed, freed == N_A + N_B, "freed count mismatch");
    std.log.info("done: {d} items from {d} mailboxes — Queue.concat + popFirst walk", .{ freed, 2 });
}

const N_A: usize = 2;
const N_B: usize = 3;

const Ctx = struct {
    mbx_a: *Mbox,
    mbx_b: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,

    fn fillMailboxA(self: *Ctx) !void {
        for (0..N_A) |i| {
            var slot: Slot = null;
            defer parents.Event.EventHelper.destroy(self.alloc, self.io, &slot);
            try parents.Event.EventHelper.create(self.alloc, self.io, &slot);
            parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 1);
            try self.mbx_a.send(&slot);
        }
    }

    fn fillMailboxB(self: *Ctx) !void {
        for (0..N_B) |i| {
            var slot: Slot = null;
            defer parents.Sensor.SensorHelper.destroy(self.alloc, self.io, &slot);
            try parents.Sensor.SensorHelper.create(self.alloc, self.io, &slot);
            parents.Sensor.SensorHelper.mustFromSlot(&slot).value = @floatFromInt(i + 10);
            try self.mbx_b.send(&slot);
        }
    }

    fn closeAndMerge(self: *Ctx) Queue {
        var list_a: Queue = self.mbx_a.close();
        self.mbx_a.destroy();
        var list_b: Queue = self.mbx_b.close();
        self.mbx_b.destroy();
        list_a.concat(&list_b);
        std.log.info("concat: combined queue has {d} parents", .{N_A + N_B});
        return list_a;
    }
};

fn collectAndRelease(combined: *Queue, alloc: std.mem.Allocator, io: std.Io) usize {
    var freed: usize = 0;
    while (combined.popFirst()) |anchor| {
        var slot: Slot = anchor;
        parents.destroySlot(&slot, alloc, io);
        freed += 1;
    }
    return freed;
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
