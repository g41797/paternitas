// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Pipeline.
//!
//! - Chain of 3 stages: producer, transformer, consumer.
//! - Producer sends 5 Events, then a sentinel (code == -1).
//! - Transformer squares each code, forwards the sentinel, then exits.
//! - Consumer sums results, frees the sentinel, exits.
//!
//!
//! ```
//!  producer ──Event──► stage1 mailbox ──► transformer
//!                                              │ Event→Event (code²)
//!                                              ▼
//!  consumer ◄──Event── stage2 mailbox ◄── transformer
//!  (sentinel: Event code=-1 terminates each stage; consumer frees)
//! ```
//!

pub fn pipeline(allocator: std.mem.Allocator, io: std.Io) !void {
    var stage1_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &stage1_slot);
    const stage1: *Mbox = Mbox.moveFromSlot(&stage1_slot).?;

    var stage2_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &stage2_slot);
    const stage2: *Mbox = Mbox.moveFromSlot(&stage2_slot).?;
    defer {
        var r1: matryoshka.queue.Queue = stage1.close();
        parents.destroyQueue(&r1, allocator, io);
        var r2: matryoshka.queue.Queue = stage2.close();
        parents.destroyQueue(&r2, allocator, io);
        stage1.destroy();
        stage2.destroy();
    }

    var prod_ctx: ProducerCtx = .{ .outbox = stage1, .alloc = allocator, .io = io };
    var tran_ctx: StageCtx = .{ .inbox = stage1, .outbox = stage2, .alloc = allocator, .io = io };
    var cons_ctx: ConsumerCtx = .{ .mbx = stage2, .alloc = allocator, .io = io };

    var f_prod = try io.concurrent(producerFn, .{&prod_ctx});
    var f_tran = try io.concurrent(transformerFn, .{&tran_ctx});
    var f_cons = try io.concurrent(consumerFn, .{&cons_ctx});

    f_prod.await(io);
    f_tran.await(io);
    f_cons.await(io);

    // 0²+1²+2²+3²+4² = 30.
    std.log.info("pipeline: count={d} sum={d}", .{ cons_ctx.count, cons_ctx.sum });
    try helpers.expect(error.PipelineFailed, cons_ctx.count == 5, "wrong item count");
    try helpers.expect(error.PipelineFailed, cons_ctx.sum == 30, "wrong sum");
}

const ProducerCtx = struct {
    outbox: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
};

fn producerFn(ctx: *ProducerCtx) void {
    var i: i32 = 0;
    while (i < 5) : (i += 1) {
        var slot: Slot = null;
        parents.Event.EventHelper.create(ctx.alloc, ctx.io, &slot) catch return;
        parents.Event.EventHelper.mustFromSlot(&slot).code = i;
        ctx.outbox.send(&slot) catch {
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
            return;
        };
    }
    {
        var slot: Slot = null;
        parents.Event.EventHelper.create(ctx.alloc, ctx.io, &slot) catch return;
        parents.Event.EventHelper.mustFromSlot(&slot).code = -1;
        ctx.outbox.send(&slot) catch parents.destroySlot(&slot, ctx.alloc, ctx.io);
    }
}

const StageCtx = struct {
    inbox: *Mbox,
    outbox: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
};

fn transformerFn(ctx: *StageCtx) void {
    while (true) {
        var slot: Slot = null;
        ctx.inbox.receive(&slot, null) catch return;
        const ev: *parents.Event = parents.Event.EventHelper.fromSlot(&slot) orelse {
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
            continue;
        };
        if (ev.code == -1) {
            ctx.outbox.send(&slot) catch parents.destroySlot(&slot, ctx.alloc, ctx.io);
            return;
        }
        ev.code = ev.code * ev.code;
        ctx.outbox.send(&slot) catch parents.destroySlot(&slot, ctx.alloc, ctx.io);
    }
}

const ConsumerCtx = struct {
    mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
    sum: i32 = 0,
    count: usize = 0,
};

fn consumerFn(ctx: *ConsumerCtx) void {
    while (true) {
        var slot: Slot = null;
        ctx.mbx.receive(&slot, null) catch return;
        const ev: *parents.Event = parents.Event.EventHelper.fromSlot(&slot) orelse {
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
            continue;
        };
        if (ev.code == -1) {
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
            return;
        }
        std.log.info("pipeline: result={d}", .{ev.code});
        ctx.sum += ev.code;
        ctx.count += 1;
        parents.destroySlot(&slot, ctx.alloc, ctx.io);
    }
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
