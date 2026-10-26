// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Title: A builder
//!
//! A small struct makes and releases parents for you.
//!
//! - Keep an allocator and an `Io` in a `Builder`. Nothing else.
//! - Build a typed parent into a Slot with `createEvent` or `createSensor`.
//! - Get the typed pointer with `mustFromSlot`, and set its fields.
//! - Release whatever type the Slot has with `release`.
//!
//! ```
//!  Builder.createEvent ──► Slot (full)
//!       │ mustFromSlot, set fields
//!       ▼
//!  Builder.release ──► Slot empty
//! ```
//!

pub fn builder_pattern(allocator: std.mem.Allocator, io: std.Io) !void {
    const b: Builder = .{ .alloc = allocator, .io = io };

    {
        var slot: Slot = null;
        defer b.release(&slot);
        try b.createEvent(100, &slot);
        const ev = parents.Event.EventHelper.mustFromSlot(&slot);
        try helpers.expect(error.BuilderFailed, ev.code == 100, "wrong event code");
    }

    {
        var slot: Slot = null;
        defer b.release(&slot);
        try b.createSensor(9.8, &slot);
        const sn = parents.Sensor.SensorHelper.mustFromSlot(&slot);
        try helpers.expect(error.BuilderFailed, sn.value == 9.8, "wrong sensor value");
    }
}

pub const Builder = struct {
    alloc: std.mem.Allocator,
    io: std.Io,

    pub fn createEvent(self: Builder, code: i32, slot: *Slot) !void {
        try parents.Event.EventHelper.create(self.alloc, self.io, slot);
        parents.Event.EventHelper.mustFromSlot(slot).code = code;
    }

    pub fn createSensor(self: Builder, value: f64, slot: *Slot) !void {
        try parents.Sensor.SensorHelper.create(self.alloc, self.io, slot);
        parents.Sensor.SensorHelper.mustFromSlot(slot).value = value;
    }

    pub fn release(self: Builder, slot: *Slot) void {
        parents.destroySlot(slot, self.alloc, self.io);
    }
};

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const Slot = @import("matryoshka").inner.Slot;
const std = @import("std");
