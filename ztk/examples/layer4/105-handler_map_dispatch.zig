// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: Dispatch through a handler map
//!
//! A handler takes the Slot, not a pointer. The parent stays in the Slot until
//! its handler takes it.
//!
//! - Keep a map from TypeId to a handler.
//! - Send Events and Sensors, mixed, into a mailbox.
//! - Receive into a Slot in the consumer. Read the id, find the handler, and
//!   pass it the Slot.
//! - Get the parent from the Slot in the handler, with its own helper, and
//!   handle it.
//! - Check after each call that the Slot is empty. A handler that forgot the
//!   parent is caught at once.
//!
//! The consumer never casts. It reads only the id.
//!
//! ```
//!  mailbox ──mbx.receive──► Slot ── typeId ──► handlers ──► handler(&slot)
//!                                                              │ mustFromSlot, destroy
//!                                                              ▼
//!                                                         slot == null
//! ```
//!

const Ctx = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    code_sum: i32 = 0,
    value_sum: f64 = 0.0,
};

const Handler = *const fn (slot: *Slot, ctx: *Ctx) void;

const Entry = struct { id: TypeId, handler: Handler };

fn onEvent(slot: *Slot, ctx: *Ctx) void {
    ctx.code_sum += parents.Event.EventHelper.mustFromSlot(slot).code;
    parents.Event.EventHelper.destroy(ctx.allocator, ctx.io, slot);
}

fn onSensor(slot: *Slot, ctx: *Ctx) void {
    ctx.value_sum += parents.Sensor.SensorHelper.mustFromSlot(slot).value;
    parents.Sensor.SensorHelper.destroy(ctx.allocator, ctx.io, slot);
}

const handlers = [_]Entry{
    .{ .id = parents.Event.EventHelper.ID, .handler = onEvent },
    .{ .id = parents.Sensor.SensorHelper.ID, .handler = onSensor },
};

fn find(id: TypeId) ?Handler {
    for (handlers) |e| if (e.id == id) return e.handler;
    return null;
}

pub fn handler_map_dispatch(allocator: std.mem.Allocator, io: std.Io) !void {
    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: matryoshka.queue.Queue = mbx.close();
        parents.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    // Producer: Event 1, Sensor 0.5, Event 2, Sensor 1.5.
    for (0..4) |i| {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        if (i % 2 == 0) {
            try parents.Event.EventHelper.create(allocator, io, &slot);
            parents.Event.EventHelper.mustFromSlot(&slot).code = @intCast(i / 2 + 1);
        } else {
            try parents.Sensor.SensorHelper.create(allocator, io, &slot);
            parents.Sensor.SensorHelper.mustFromSlot(&slot).value = @as(f64, @floatFromInt(i / 2)) + 0.5;
        }
        try mbx.send(&slot);
    }

    // Consumer.
    var ctx: Ctx = .{ .allocator = allocator, .io = io };
    for (0..4) |_| {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        try mbx.receive(&slot, 1_000_000_000);

        const h = find(slot.?.typeId()) orelse return error.UnknownType;
        h(&slot, &ctx);
        try helpers.expect(error.HandlerMapDispatchFailed, slot == null, "the handler left its parent in the Slot");
    }

    try helpers.expect(error.HandlerMapDispatchFailed, ctx.code_sum == 3, "wrong event sum");
    try helpers.expect(error.HandlerMapDispatchFailed, ctx.value_sum == 2.0, "wrong sensor sum");
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
const TypeId = matryoshka.inner.TypeId;
