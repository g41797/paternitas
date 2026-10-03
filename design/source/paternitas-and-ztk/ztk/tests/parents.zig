// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! The parent types the layer 1 tests share.
//!
//! Shared test infrastructure, not part of any layer's public surface.
//!
//! No inner field is called `inner`, and they are not all at the same offset.
//! The helper finds the field by type, and these types are what says so.

/// Fields ahead of the inner, so its offset is not zero.
pub const Msg = struct {
    seq: u32 = 0,
    payload: u64 = 0,
    hdr: SinglyTypedNode = .{},

    pub fn init(self: *Msg, alloc: std.mem.Allocator, io: Io) !void {
        _ = io;
        _ = alloc;
        self.seq = 0;
        self.payload = 0;
    }

    pub fn finish(self: *Msg, alloc: std.mem.Allocator, io: Io) void {
        _ = io;
        _ = self;
        _ = alloc;
    }
};

/// The inner first, so its offset is zero.
pub const Chunk = struct {
    mtk: SinglyTypedNode = .{},
    size: usize = 0,

    pub fn init(self: *Chunk, alloc: std.mem.Allocator, io: Io) !void {
        _ = io;
        _ = alloc;
        self.size = 0;
    }

    pub fn finish(self: *Chunk, alloc: std.mem.Allocator, io: Io) void {
        _ = io;
        _ = self;
        _ = alloc;
    }
};

/// A third type, so a wrong-type test has two ways to be wrong.
pub const Note = struct {
    chain: SinglyTypedNode = .{},
    text: [8]u8 = @splat(0),

    pub fn init(self: *Note, alloc: std.mem.Allocator, io: Io) !void {
        _ = io;
        _ = alloc;
        self.text = @splat(0);
    }

    pub fn finish(self: *Note, alloc: std.mem.Allocator, io: Io) void {
        _ = io;
        _ = self;
        _ = alloc;
    }
};

/// Allocates in `init` and releases in `finish`.
pub const Buf = struct {
    hdr: SinglyTypedNode = .{},
    bytes: []u8 = &.{},

    pub const size = 32;

    pub fn init(self: *Buf, alloc: std.mem.Allocator, io: Io) !void {
        _ = io;
        self.bytes = try alloc.alloc(u8, size);
    }

    pub fn finish(self: *Buf, alloc: std.mem.Allocator, io: Io) void {
        _ = io;
        alloc.free(self.bytes);
        self.bytes = &.{};
    }
};

/// Its `init` always fails. The parent must be freed again.
pub const BadInit = struct {
    hdr: SinglyTypedNode = .{},

    pub const Failed = error{InitRefused};

    pub fn init(self: *BadInit, alloc: std.mem.Allocator, io: Io) !void {
        _ = io;
        _ = self;
        _ = alloc;
        return Failed.InitRefused;
    }

    pub fn finish(self: *BadInit, alloc: std.mem.Allocator, io: Io) void {
        _ = io;
        _ = self;
        _ = alloc;
    }
};

/// A container: it allocates itself, so it declares neither hook.
///
/// This is `Mbox` and `Pool` in miniature. The helper still gives it an id
/// and the crossings; only create and destroy are out of reach, and asking
/// for them does not compile.
pub const FakeMbox = struct {
    hdr: SinglyTypedNode = .{},
    closed: bool = false,
};

/// The helpers for the four types a test may put on a chain.
pub const MSG = m.helper.ParentHelper(Msg);
pub const CHUNK = m.helper.ParentHelper(Chunk);
pub const NOTE = m.helper.ParentHelper(Note);
pub const BUF = m.helper.ParentHelper(Buf);

/// Makes a `Msg` on the heap, in the Slot, with `seq` set.
///
/// Layer 2 and 3 send what the allocator made. A parent living in a test's
/// own frame would have the mailbox hand back a pointer the allocator never
/// gave out.
pub fn newMsg(alloc: std.mem.Allocator, io: Io, slot: *m.inner.Slot, seq: u32) !void {
    try MSG.create(alloc, io, slot);
    MSG.mustFromSlot(slot).seq = seq;
}

/// Makes a `Note` on the heap, in the Slot. A second type, for the tests
/// that need one.
pub fn newNote(alloc: std.mem.Allocator, io: Io, slot: *m.inner.Slot) !void {
    try NOTE.create(alloc, io, slot);
}

/// Releases one parent, whatever of these four types it is.
///
/// Test infrastructure, and a small stand-in for what a real caller does
/// with what `close` hands back: it knows its own types, and it dispatches
/// on the id.
pub fn release(anchor: *Anchor, alloc: std.mem.Allocator, io: Io) void {
    var slot: m.inner.Slot = null;
    m.inner.fillSlot(&slot, anchor);

    if (MSG.isIt(anchor.typeId())) return MSG.destroy(alloc, io, &slot);
    if (CHUNK.isIt(anchor.typeId())) return CHUNK.destroy(alloc, io, &slot);
    if (NOTE.isIt(anchor.typeId())) return NOTE.destroy(alloc, io, &slot);
    if (BUF.isIt(anchor.typeId())) return BUF.destroy(alloc, io, &slot);

    @panic("release: a parent of a type these tests do not know");
}

/// Releases every parent on the queue, leaving it empty.
pub fn releaseAll(q: *m.queue.Queue, alloc: std.mem.Allocator, io: Io) void {
    while (q.popFirst()) |anchor| release(anchor, alloc, io);
}

/// Releases what the Slot holds, if anything, leaving it empty.
pub fn releaseSlot(slot: *m.inner.Slot, alloc: std.mem.Allocator, io: Io) void {
    const anchor = slot.* orelse return;
    slot.* = null;
    release(anchor, alloc, io);
}

const m = @import("matryoshka");
const Anchor = m.inner.Anchor;
const SinglyTypedNode = m.inner.SinglyTypedNode;
const Io = std.Io;
const std = @import("std");
