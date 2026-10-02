// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! The pool hooks the layer 3 tests share.
//!
//! Shared test infrastructure, not part of any layer's public surface.
//!
//! One recorder stands in for every policy the scenarios need — it keeps,
//! it releases, or it keeps up to a cap — because what the tests read is
//! the same in each case: what the pool asked, what it was told, and how
//! many parents the close hook was handed.
//!
//! It takes its own mutex around every count. A hook runs with the pool's
//! lock released, and the close hook may be called twice at the same time,
//! so the counts are written from more than one context.

/// What `on_put` does with the parent it is handed.
pub const Policy = enum {
    /// Leave it in the Slot, so the pool stores it.
    keep,

    /// Empty the Slot and release the parent.
    release,

    /// Keep it while fewer than `cap` are stored, release it above that.
    cap,
};

/// A hook set that records what it was asked and answers by policy.
pub const Recorder = struct {
    alloc: std.mem.Allocator,
    io: Io,

    /// What `on_put` does.
    policy: Policy = .keep,

    /// The threshold for `.cap`.
    cap: usize = 0,

    /// Whether `on_get` makes one. False leaves the Slot empty, which the
    /// caller sees as `error.NotCreated`.
    makes: bool = true,

    /// How many extra parents `on_put` appends to `extra`. A composite parent
    /// giving its parts back.
    parts: usize = 0,

    gets: usize = 0,
    puts: usize = 0,
    made: usize = 0,
    released: usize = 0,

    close_calls: usize = 0,
    closed_items: usize = 0,

    last_get_in_pool: usize = 0,
    last_put_in_pool: usize = 0,

    /// False as soon as `on_get` is reached with a parent already in the
    /// Slot. It never is, and that is scenario 280.
    get_slot_always_empty: bool = true,

    /// Set while a hook is running, for the tests that watch from another
    /// context.
    in_hook: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    /// Held while a hook is running, for a test that wants one to sit
    /// inside the pool until it says otherwise.
    hold: ?*std.atomic.Value(bool) = null,

    /// When set, `on_put` asks the pool a question of its own. A hook runs
    /// with the pool's lock released, so this answers rather than
    /// deadlocks — and `isIdle` is the one it must never ask.
    reenter: ?*m.Pool = null,

    /// What that question answered.
    reentered: bool = false,

    mu: Io.Mutex = .init,

    /// The three function pointers and the context, ready for `newPool`.
    pub fn hooks(self: *Recorder) m.Pool.Hooks {
        return .{
            .ctx = self,
            .on_get = onGet,
            .on_put = onPut,
            .on_close = onClose,
        };
    }

    fn of(ctx: *anyopaque) *Recorder {
        return @ptrCast(@alignCast(ctx));
    }

    fn onGet(ctx: *anyopaque, want: m.inner.TypeId, in_pool: usize, slot: *m.inner.Slot) void {
        const self = of(ctx);
        self.in_hook.store(true, .release);
        defer self.in_hook.store(false, .release);

        {
            self.mu.lockUncancelable(self.io);
            defer self.mu.unlock(self.io);

            self.gets += 1;
            self.last_get_in_pool = in_pool;
            if (slot.* != null) self.get_slot_always_empty = false;
        }

        if (!self.makes) return;

        makeOf(want, self.alloc, self.io, slot) catch return;

        self.mu.lockUncancelable(self.io);
        defer self.mu.unlock(self.io);
        self.made += 1;
    }

    fn onPut(ctx: *anyopaque, in_pool: usize, slot: *m.inner.Slot, extra: *m.queue.Queue) void {
        const self = of(ctx);
        self.in_hook.store(true, .release);
        defer self.in_hook.store(false, .release);

        {
            self.mu.lockUncancelable(self.io);
            defer self.mu.unlock(self.io);

            self.puts += 1;
            self.last_put_in_pool = in_pool;
        }

        if (self.reenter) |p| {
            _ = p.countOf(o.MSG.ID) catch {};
            _ = p.isClosed();

            self.mu.lockUncancelable(self.io);
            self.reentered = true;
            self.mu.unlock(self.io);
        }

        if (self.hold) |go| while (!go.load(.acquire)) std.Thread.yield() catch {};

        const let_go = switch (self.policy) {
            .keep => false,
            .release => true,
            .cap => in_pool >= self.cap,
        };

        if (let_go) {
            o.releaseSlot(slot, self.alloc, self.io);

            self.mu.lockUncancelable(self.io);
            defer self.mu.unlock(self.io);
            self.released += 1;
        }

        // The parts of a composite parent, given back with it.
        var made: usize = 0;
        while (made < self.parts) : (made += 1) {
            var part: m.inner.Slot = null;
            o.newMsg(self.alloc, self.io, &part, 0) catch break;
            extra.appendFromSlot(&part);
        }
    }

    fn onClose(ctx: *anyopaque, remaining: m.queue.Queue) void {
        const self = of(ctx);
        self.in_hook.store(true, .release);
        defer self.in_hook.store(false, .release);

        // By value, so this copy is the only way to the items. The hook's
        // own count is bumped first: it may be called more than once, and
        // twice at the same time, so it owns nothing it must tear down here.
        var mine: m.queue.Queue = remaining;

        {
            self.mu.lockUncancelable(self.io);
            defer self.mu.unlock(self.io);
            self.close_calls += 1;
        }

        var seen: usize = 0;
        while (mine.popFirst()) |anchor| : (seen += 1) o.release(anchor, self.alloc, self.io);

        self.mu.lockUncancelable(self.io);
        defer self.mu.unlock(self.io);
        self.closed_items += seen;
    }
};

/// Makes a parent of the identity the pool asked for.
///
/// A hook knows its own types and dispatches on the id. This is that, in
/// the two types the layer 3 tests use.
pub fn makeOf(want: m.inner.TypeId, alloc: std.mem.Allocator, io: Io, slot: *m.inner.Slot) !void {
    if (o.MSG.isIt(want)) return o.newMsg(alloc, io, slot, 0);
    if (o.NOTE.isIt(want)) return o.newNote(alloc, io, slot);

    @panic("makeOf: an identity these tests do not make");
}

const m = @import("matryoshka");
const o = @import("parents.zig");
const Io = std.Io;
const std = @import("std");
