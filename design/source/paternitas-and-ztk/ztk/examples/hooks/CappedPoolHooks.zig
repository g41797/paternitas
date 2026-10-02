//! Sample hook, for demo purposes only.
//!
//! Keeps at most `cap` parents. The put hook releases the rest, so the get
//! hook only ever makes one.
alloc: std.mem.Allocator,
cap: usize,
io: std.Io,
mutex: Io.Mutex = .init,
count: usize = 0,

pub fn poolHooks(self: *Self) Pool.Hooks {
    return .{
        .ctx = self,
        .on_get = onGet,
        .on_put = onPut,
        .on_close = onClose,
    };
}

pub fn onGet(ptr: *anyopaque, want: TypeId, _: usize, slot: *Slot) void {
    const self: *Self = @ptrCast(@alignCast(ptr));

    // Nothing was stored, so the Slot is empty. Make a fresh one. It is not
    // counted until it is put back.
    parents.createById(want, self.alloc, self.io, slot) catch return;
}

pub fn onPut(ptr: *anyopaque, _: usize, slot: *Slot, _: *Queue) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    self.mutex.lockUncancelable(self.io);
    defer self.mutex.unlock(self.io);

    if (self.count >= self.cap) {
        parents.destroySlot(slot, self.alloc, self.io);
    } else {
        parents.resetOnPut(slot);
        self.count += 1;
    }
}

pub fn onClose(ptr: *anyopaque, remaining: Queue) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    var rest = remaining;
    parents.destroyQueue(&rest, self.alloc, self.io);
    self.count = 0;
}

const Self = @This();
const parents = @import("../parents/parents.zig");
const matryoshka = @import("matryoshka");
const Io = std.Io;
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
const std = @import("std");
