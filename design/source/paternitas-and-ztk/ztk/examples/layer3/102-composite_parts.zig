// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Composite parent gives its parts back.
//!
//! - A Composite holds two Events, taken from the same pool.
//! - Put of the Composite runs on_put. The hook moves the parts onto `extra`.
//! - The pool takes the parts back the same way as the parent in the Slot.
//! - One put stores three parents: the Composite and both Events.
//!
//!
//! ```
//!  Composite { a, b } ──► pl.put
//!       │ on_put: extra ◄── a, b
//!       ▼
//!  pool holds Composite, Event, Event
//! ```
//!

pub fn composite_parts(allocator: std.mem.Allocator, io: std.Io) !void {
    var ctx: Parts = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{ Composite.Helper.ID, parents.Event.EventHelper.ID };

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    var slot: Slot = null;
    try pl.get(Composite.Helper.ID, .new_only, &slot);
    const comp = Composite.Helper.mustFromSlot(&slot);

    try pl.get(parents.Event.EventHelper.ID, .new_only, &comp.a);
    try pl.get(parents.Event.EventHelper.ID, .new_only, &comp.b);
    try helpers.expect(error.CompositePartsFailed, (try pl.countOf(parents.Event.EventHelper.ID)) == 0, "parts should be out");

    try pl.put(&slot);
    try helpers.expect(error.CompositePartsFailed, slot == null, "slot should be empty after put");

    try helpers.expect(error.CompositePartsFailed, (try pl.countOf(Composite.Helper.ID)) == 1, "composite not stored");
    try helpers.expect(error.CompositePartsFailed, (try pl.countOf(parents.Event.EventHelper.ID)) == 2, "parts not given back");
    std.log.info("one put stored the composite and both parts", .{});
}

const Composite = struct {
    inner: SinglyTypedNode = .{},
    a: Slot = null,
    b: Slot = null,

    const Helper = matryoshka.helper.ParentHelper(Composite);

    pub fn init(self: *Composite, alloc: std.mem.Allocator, io: std.Io) !void {
        _ = .{ alloc, io };
        self.a = null;
        self.b = null;
    }

    pub fn finish(self: *Composite, alloc: std.mem.Allocator, io: std.Io) void {
        parents.destroySlot(&self.a, alloc, io);
        parents.destroySlot(&self.b, alloc, io);
    }
};

const Parts = struct {
    alloc: std.mem.Allocator,
    io: std.Io,

    fn poolHooks(self: *Parts) Pool.Hooks {
        return .{ .ctx = self, .on_get = onGet, .on_put = onPut, .on_close = onClose };
    }

    fn onGet(ptr: *anyopaque, want: TypeId, _: usize, slot: *Slot) void {
        const self: *Parts = @ptrCast(@alignCast(ptr));
        if (Composite.Helper.isIt(want)) {
            Composite.Helper.create(self.alloc, self.io, slot) catch return;
        } else {
            parents.createById(want, self.alloc, self.io, slot) catch return;
        }
    }

    fn onPut(_: *anyopaque, _: usize, slot: *Slot, extra: *Queue) void {
        const comp = Composite.Helper.fromSlot(slot) orelse return;
        if (comp.a != null) extra.append(matryoshka.inner.takeFromSlot(&comp.a));
        if (comp.b != null) extra.append(matryoshka.inner.takeFromSlot(&comp.b));
    }

    fn onClose(ptr: *anyopaque, remaining: Queue) void {
        const self: *Parts = @ptrCast(@alignCast(ptr));
        var rest = remaining;
        while (rest.popFirst()) |anchor| {
            var s: Slot = anchor;
            if (Composite.Helper.isIt(anchor.typeId())) {
                Composite.Helper.destroy(self.alloc, self.io, &s);
            } else {
                parents.destroySlot(&s, self.alloc, self.io);
            }
        }
    }
};

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Anchor = matryoshka.inner.Anchor;
const SinglyTypedNode = matryoshka.inner.SinglyTypedNode;
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
