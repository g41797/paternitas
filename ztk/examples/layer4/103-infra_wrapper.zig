// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Infrastructure wrapper.
//!
//! - Channel is a parent of your own. Its `init` makes a mailbox, its `finish` closes it.
//! - The helper creates and releases a Channel like any other parent.
//! - Nobody outside Channel closes or destroys the mailbox — one owner, one place.
//! - Whatever is still queued at the end is released by `finish`, so a Channel
//!   dropped with traffic in flight leaks nothing.
//!
//!
//! ```
//!  ChannelHelper.create ──► Channel.init ──► newMbox
//!       │ channel.send(Event) ──► inbox
//!       │ channel.receive ──► slot
//!       ▼
//!  ChannelHelper.destroy ──► Channel.finish ──► close + destroyQueue + destroy
//! ```
//!

pub fn infra_wrapper(allocator: std.mem.Allocator, io: std.Io) !void {
    var slot: Slot = null;
    defer ChannelHelper.destroy(allocator, io, &slot);
    try ChannelHelper.create(allocator, io, &slot);
    const channel: *Channel = ChannelHelper.mustFromSlot(&slot);

    {
        var ev: Slot = null;
        defer parents.destroySlot(&ev, allocator, io);
        try parents.Event.EventHelper.create(allocator, io, &ev);
        parents.Event.EventHelper.mustFromSlot(&ev).code = 103;
        try channel.send(&ev);
    }

    // One more is left queued, and finish releases it.
    {
        var ev: Slot = null;
        defer parents.destroySlot(&ev, allocator, io);
        try parents.Event.EventHelper.create(allocator, io, &ev);
        try channel.send(&ev);
    }

    var got: Slot = null;
    defer parents.destroySlot(&got, allocator, io);
    try channel.receive(&got);
    const ev = parents.Event.EventHelper.mustFromSlot(&got);
    try helpers.expect(error.InfraWrapperFailed, ev.code == 103, "wrong event code");
    std.log.info("channel: received code={d}, one still queued for finish", .{ev.code});
}

/// A parent that owns a mailbox.
const Channel = struct {
    inner: SinglyTypedNode = .{},
    inbox: *Mbox = undefined,
    alloc: std.mem.Allocator = undefined,
    io: std.Io = undefined,

    pub fn init(self: *Channel, alloc: std.mem.Allocator, io: std.Io) !void {
        var mbx_slot: Slot = null;
        try matryoshka.mbox.new(alloc, io, &mbx_slot);
        self.* = .{ .inbox = Mbox.moveFromSlot(&mbx_slot).?, .alloc = alloc, .io = io };
    }

    pub fn finish(self: *Channel, alloc: std.mem.Allocator, io: std.Io) void {
        var rem: Queue = self.inbox.close();
        parents.destroyQueue(&rem, alloc, io);
        self.inbox.destroy();
    }

    fn send(self: *Channel, slot: *Slot) !void {
        try self.inbox.send(slot);
    }

    fn receive(self: *Channel, slot: *Slot) !void {
        try self.inbox.receive(slot, 1_000_000_000);
    }
};

const ChannelHelper = matryoshka.helper.ParentHelper(Channel);

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Anchor = matryoshka.inner.Anchor;
const SinglyTypedNode = matryoshka.inner.SinglyTypedNode;
const Mbox = matryoshka.Mbox;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
