// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Pipeline of Masters.
//!
//! - 3 Masters chained: producer, transformer, consumer.
//! - Producer sends Events, then a ShutdownCommand sentinel.
//! - Transformer converts each Event to a Sensor, forwards the sentinel, exits.
//! - Consumer sums received Sensors, exits on the sentinel.
//!
//!
//! ```
//!  producer ──Event──► transformer_mbx ──► transformer
//!                                              │ Event→Sensor conversion
//!                                              ▼
//!  consumer ◄──Sensor── consumer_mbx ◄── transformer
//!  (ShutdownCommand sentinel propagates: producer→transformer→consumer)
//!  fut_prod.await → fut_trans.await → fut_cons.await
//! ```
//!

pub fn pipeline_of_masters(allocator: std.mem.Allocator, io: std.Io) !void {
    const master = try PipelineMaster.init(allocator, io);
    defer master.destroy();
    try master.run();
}

const ProducerCtx = struct {
    out_mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
};

fn producerFn(ctx: *ProducerCtx) anyerror!void {
    for (0..3) |i| {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        try parents.Event.EventHelper.create(ctx.alloc, ctx.io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i + 1);
        try ctx.out_mbx.send(&slot);
        std.log.info("producer: sent Event code={d}", .{i + 1});
    }
    {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        try parents.ShutdownCommand.ShutdownCommandHelper.create(ctx.alloc, ctx.io, &slot);
        try ctx.out_mbx.send(&slot);
        std.log.info("producer: sent ShutdownCommand sentinel", .{});
    }
}

const TransformerCtx = struct {
    in_mbx: *Mbox,
    out_mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
};

fn transformerFn(ctx: *TransformerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        ctx.in_mbx.receive(&slot, null) catch return;
        const poly: *Anchor = slot.?;

        if (parents.Event.EventHelper.fromAnchor(poly)) |ev| {
            const value: f64 = @floatFromInt(ev.code);
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
            parents.Sensor.SensorHelper.create(ctx.alloc, ctx.io, &slot) catch continue;
            parents.Sensor.SensorHelper.mustFromSlot(&slot).value = value;
            ctx.out_mbx.send(&slot) catch {
                parents.destroySlot(&slot, ctx.alloc, ctx.io);
            };
            std.log.info("transformer: Event→Sensor value={d}", .{value});
        } else if (parents.ShutdownCommand.ShutdownCommandHelper.fromAnchor(poly)) |_| {
            ctx.out_mbx.send(&slot) catch {};
            std.log.info("transformer: forwarded ShutdownCommand, done", .{});
            return;
        } else {
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
        }
    }
}

const ConsumerCtx = struct {
    in_mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
    count: usize = 0,
};

fn consumerFn(ctx: *ConsumerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        ctx.in_mbx.receive(&slot, null) catch return;
        const poly: *Anchor = slot.?;

        if (parents.Sensor.SensorHelper.fromAnchor(poly)) |sn| {
            ctx.count += 1;
            std.log.info("consumer: Sensor value={d} (total={d})", .{ sn.value, ctx.count });
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
        } else if (parents.ShutdownCommand.ShutdownCommandHelper.fromAnchor(poly)) |_| {
            std.log.info("consumer: ShutdownCommand received, done", .{});
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
            return;
        } else {
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
        }
    }
}

const PipelineMaster = struct {
    fn run(self: *PipelineMaster) !void {
        try self.runWorkers();
        try helpers.expect(error.PipelineFailed, self.cons_ctx.count == 3, "expected consumer to receive 3 Sensors");
        std.log.info("pipeline done: consumer received {d} items", .{self.cons_ctx.count});
    }

    fn runWorkers(self: *PipelineMaster) !void {
        var fut_prod: std.Io.Future(anyerror!void) = try self.io.concurrent(producerFn, .{&self.prod_ctx});
        var fut_trans: std.Io.Future(anyerror!void) = try self.io.concurrent(transformerFn, .{&self.trans_ctx});
        var fut_cons: std.Io.Future(anyerror!void) = try self.io.concurrent(consumerFn, .{&self.cons_ctx});
        try fut_prod.await(self.io);
        try fut_trans.await(self.io);
        try fut_cons.await(self.io);
    }

    allocator: std.mem.Allocator,
    io: std.Io,
    transformer_mbx: *Mbox,
    consumer_mbx: *Mbox,
    prod_ctx: ProducerCtx,
    trans_ctx: TransformerCtx,
    cons_ctx: ConsumerCtx,

    fn init(allocator: std.mem.Allocator, io: std.Io) !*PipelineMaster {
        const self = try allocator.create(PipelineMaster);
        errdefer allocator.destroy(self);
        self.allocator = allocator;
        self.io = io;

        var transformer_mbx_slot: Slot = null;
        try matryoshka.mbox.new(allocator, io, &transformer_mbx_slot);
        self.transformer_mbx = Mbox.moveFromSlot(&transformer_mbx_slot).?;
        errdefer {
            var rem: Queue = self.transformer_mbx.close();
            parents.destroyQueue(&rem, allocator, io);
            self.transformer_mbx.destroy();
        }

        var consumer_mbx_slot: Slot = null;
        try matryoshka.mbox.new(allocator, io, &consumer_mbx_slot);
        self.consumer_mbx = Mbox.moveFromSlot(&consumer_mbx_slot).?;
        self.prod_ctx = .{ .out_mbx = self.transformer_mbx, .alloc = allocator, .io = io };
        self.trans_ctx = .{ .in_mbx = self.transformer_mbx, .out_mbx = self.consumer_mbx, .alloc = allocator, .io = io };
        self.cons_ctx = .{ .in_mbx = self.consumer_mbx, .alloc = allocator, .io = io };
        return self;
    }

    fn destroy(self: *PipelineMaster) void {
        var rem1: Queue = self.transformer_mbx.close();
        parents.destroyQueue(&rem1, self.allocator, self.io);
        self.transformer_mbx.destroy();
        var rem2: Queue = self.consumer_mbx.close();
        parents.destroyQueue(&rem2, self.allocator, self.io);
        self.consumer_mbx.destroy();
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
const Anchor = matryoshka.inner.Anchor;
