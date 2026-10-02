// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Keeps used parents so they can be used again.
//!
//! Many contexts share one pool. It does its own locking. It keeps each
//! identity apart, in a store of its own, and it works with an `*Anchor`, so
//! it never learns your types.
//!
//! The pool manages the collection. Your hooks decide what reuse means.
//!
//! ## Making one
//!
//! - `newPool` takes the allocator, the `Io`, the identities it will keep,
//!   and your hooks.
//! - The set of identities is fixed there, is not empty, and has no
//!   duplicate. Both are refused where runtime safety is on.
//! - `Pool.destroy` gives the memory back, after `close` and after every
//!   call has returned.
//! - `Pool.ID`, `toAnchor` and `fromAnchor` let a pool travel inside a mailbox
//!   or another pool.
//!
//! ## Getting one out
//!
//! `get` takes a mode, and the mode is the whole policy.
//!
//! - `.available_or_new` — a stored parent if there is one, otherwise your
//!   `on_get`.
//! - `.new_only` — always your `on_get`, even with parents stored.
//! - `.available_only` — a stored parent, or `error.NotAvailable`. It never
//!   reaches `on_get`.
//! - `get` fills an empty Slot. A full one is refused.
//! - `error.NotCreated` is what your `on_get` said by leaving the Slot
//!   empty.
//! - `getWait` waits up to a timeout for a stored parent. It never reaches
//!   `on_get`.
//!
//! ## Giving one back
//!
//! - `put` takes a full Slot and runs your `on_put`.
//! - `put` empties the Slot when the pool took the parent.
//! - A closed pool is silent, and the parent stays with you.
//! - An identity the pool was not made with is `error.UnknownIdentity`.
//!
//! ## Shutting down
//!
//! - `close` moves everything stored into one queue and hands it to
//!   `on_close`.
//! - `close` on an already closed pool does nothing.
//! - Every waiter in `getWait` comes back with `error.Closed`.
//! - `isClosed` is the state. `isIdle` says closed with no call still
//!   inside.
//! - `countOf` is how many of one identity are stored now.
//!
//! ## What it stores them on
//!
//! A stack per identity, so reuse is last in, first out: the parent that came
//! back most recently goes out next, and a writer that went stale meets its
//! next owner at once. The queue keeps its place at the border — `on_close`
//! is handed one, because what leaves the pool leaves in one piece.
//!
//! Examples:
//! https://g41797.github.io/matryoshka-ztk/examples/pool/
const _doc_stub = void;

/// A pool — the tool for keeping parents and handing them out again.
///
/// A pool is itself a parent. Use `toAnchor` and `fromAnchor` to send one
/// through a mailbox or another pool.
///
/// The fields are internal. Their names start with `_` for that reason;
/// Zig has no private field.
pub const Pool = struct {
    /// Which parents `get` will answer with.
    pub const GetMode = enum {
        /// A stored parent if there is one, otherwise `on_get`.
        available_or_new,

        /// `on_get`, even with parents stored.
        new_only,

        /// A stored parent, or `error.NotAvailable`. Never `on_get`.
        available_only,
    };

    /// Everything `get` can end with.
    ///
    /// `NotCreated` is the get hook's own answer, not a failure of the pool.
    pub const GetError = error{ Closed, NotAvailable, NotCreated, UnknownIdentity };

    /// Every outcome of a `getWait`, packed into one value.
    ///
    /// For `Io.Select` and `Io.Group`, through `getWaitResult`.
    pub const Result = union(enum) {
        anchor: *Anchor,
        closed: void,
        timeout: void,
        canceled: void,
        unknown_identity: void,
    };

    /// The one page about code you write, not code you call.
    ///
    /// Three functions and the context they are called with. You implement
    /// them, and the pool calls them. The rules of reuse are yours, and this
    /// is where you state them.
    ///
    /// ## What each one is for
    ///
    /// - `on_get` — a caller asked for a parent and none are stored.
    /// - `on_put` — a parent came back, and you decide whether it stays.
    /// - `on_close` — the pool is closing, and everything it still keeps is
    ///   handed to you.
    ///
    /// ## How to answer
    ///
    /// - In `on_get`, fill the Slot with a new parent, or leave it empty.
    /// - An empty Slot on the way out of `on_get` is `error.NotCreated` for
    ///   the caller.
    /// - In `on_put`, clear the parent and leave it in the Slot to keep it.
    /// - Empty the Slot yourself, and release the parent, to let it go.
    /// - Add more parents to `extra`, and they are taken back the same way,
    ///   with the same checks.
    /// - `on_close` is handed one queue, by value, flattened across every
    ///   identity. No order is promised, and releasing everything on it is
    ///   your job.
    ///
    /// ## What to know before you write one
    ///
    /// - A hook runs with the pool's lock released, so another context can
    ///   be inside the pool while yours runs.
    /// - MUST NOT call `Pool.isIdle` from a hook. It takes the mutex, and a
    ///   hook is caller code running inside a call, so that deadlocks.
    ///   `isClosed` takes no lock and answers the other half.
    /// - `in_pool` is a count read before the lock was given up. It is a
    ///   hint, and it is stale: the count after the removal in `on_get`, and
    ///   before the addition in `on_put`.
    /// - `on_get` fills the Slot with a parent of the identity it was asked
    ///   for. Another one is refused.
    /// - **`on_close` may be called more than once, and twice at the same
    ///   time.** `close` calls it, and so does every `put` that was still
    ///   running its own hook when the pool closed — that is how those
    ///   parents are kept from being lost. So a close hook does not release
    ///   its own state on the first call, and it survives being re-entered.
    /// - Clearing a parent means your own fields. The toolkit keeps the
    ///   Link.
    pub const Hooks = struct {
        /// Yours, handed back to every call. The pool does not read it.
        ctx: *anyopaque,

        /// None are stored. Make one, or leave the Slot empty.
        ///
        /// The Slot is **always empty on entry**: this hook is reached only
        /// when nothing was stored, so it is never asked to look at what is
        /// already there.
        on_get: *const fn (ctx: *anyopaque, want: TypeId, in_pool: usize, slot: *Slot) void,

        /// One came back. Keep it in the Slot, or empty the Slot and
        /// release it.
        ///
        /// `extra` is an empty queue on entry. Parents appended to it are
        /// taken back the same way the one in the Slot is.
        on_put: *const fn (ctx: *anyopaque, in_pool: usize, slot: *Slot, extra: *Queue) void,

        /// The pool is closing, and these are yours.
        ///
        /// The queue arrives **by value**, so after the call there is no way
        /// back to the items. Release every one of them.
        ///
        /// May be called more than once, and twice at the same time.
        on_close: *const fn (ctx: *anyopaque, remaining: Queue) void,
    };

    /// This type's id.
    pub const ID: TypeId = helper.ID;

    /// True when the id is a pool's.
    pub inline fn isIt(id: TypeId) bool {
        return helper.isIt(id);
    }

    /// The Anchor embedded in the pool.
    ///
    /// Use it to send a pool through a mailbox or another pool.
    pub inline fn toAnchor(self: *Pool) *Anchor {
        return helper.toAnchor(self);
    }

    /// The pool, from a bare Anchor. Null when the Anchor is another type.
    pub inline fn fromAnchor(anchor: *Anchor) ?*Pool {
        return helper.fromAnchor(anchor);
    }

    /// The pool, from a bare Anchor. Panics on another type.
    pub inline fn mustFromAnchor(anchor: *Anchor) *Pool {
        return helper.mustFromAnchor(anchor);
    }

    /// The pool, from the Slot holding it. Leaves the Slot full.
    pub inline fn fromSlot(slot: *const Slot) ?*Pool {
        return helper.fromSlot(slot);
    }

    /// The pool, from the Slot holding it. Panics on an empty Slot or
    /// another type.
    pub inline fn mustFromSlot(slot: *const Slot) *Pool {
        return helper.mustFromSlot(slot);
    }

    /// Takes the pool out of the Slot, leaving it empty.
    ///
    /// Null when the Slot is empty or holds another type, and then the Slot
    /// is untouched.
    pub inline fn moveFromSlot(slot: *Slot) ?*Pool {
        return helper.moveFromSlot(slot);
    }

    /// Fetches a parent of `want`, by the policy `mode` names.
    ///
    /// On success the Slot holds it. On every failure the Slot is left
    /// empty, so one look at the Slot says whether you have one.
    ///
    /// - `error.Closed` — the pool is closed.
    /// - `error.NotAvailable` — `.available_only`, and none are stored.
    /// - `error.NotCreated` — your `on_get` left the Slot empty.
    /// - `error.UnknownIdentity` — an identity the pool was not made with.
    ///   An error in **every** build, and a check besides where runtime
    ///   safety is on: it is a caller's mistake about the pool's own shape,
    ///   and a fast build that carried on would call your hook with an
    ///   identity the pool never knew.
    ///
    /// Refuses a Slot that is not empty on entry.
    pub fn get(self: *Pool, want: TypeId, mode: GetMode, slot: *Slot) GetError!void {
        check(slot.* == null, "an acquisition needs an empty Slot on entry");

        if (self._closedFast()) return error.Closed;
        const io: Io = self._io;

        self._mu.lockUncancelable(io);

        if (self._closed) {
            self._mu.unlock(io);
            return error.Closed;
        }

        self._active += 1;

        const bucket = self._bucketFor(want) orelse {
            self._active -= 1;
            self._mu.unlock(io);
            return error.UnknownIdentity;
        };

        if (mode != .new_only) {
            if (bucket.free.pop()) |anchor| {
                self._active -= 1;
                self._mu.unlock(io);

                slot.* = anchor;
                return;
            }
        }

        if (mode == .available_only) {
            self._active -= 1;
            self._mu.unlock(io);
            return error.NotAvailable;
        }

        // Nothing is stored, so the hook's Slot is empty. That is the whole
        // of it: this is the only path that reaches `on_get`.
        const in_pool = bucket.free.len();

        self._mu.unlock(io);
        self._hooks.on_get(self._hooks.ctx, want, in_pool, slot);
        self._mu.lockUncancelable(io);

        self._active -= 1;
        self._mu.unlock(io);

        const made = slot.* orelse return error.NotCreated;

        check(made.type_id == want, "the get hook filled the Slot with a parent of another identity");
    }

    /// Fetches a stored parent, waiting up to `timeout_ns` for one.
    ///
    /// Never reaches `on_get`. Waiting is for a parent another context gives
    /// back, and a hook that could make one would make the wait pointless.
    ///
    /// - `timeout_ns` null waits forever.
    /// - `timeout_ns` zero comes back at once with `error.Timeout`.
    ///
    /// A `close` wakes every waiter, which come back with `error.Closed`.
    ///
    /// Refuses a Slot that is not empty on entry.
    pub fn getWait(
        self: *Pool,
        want: TypeId,
        slot: *Slot,
        timeout_ns: ?u64,
    ) (error{ Closed, Timeout, UnknownIdentity } || Io.Cancelable)!void {
        check(slot.* == null, "an acquisition needs an empty Slot on entry");

        if (self._closedFast()) return error.Closed;
        const io: Io = self._io;

        const wanted: Io.Timeout = if (timeout_ns) |ns|
            .{ .duration = .{ .raw = .{ .nanoseconds = @as(i96, @intCast(ns)) }, .clock = .real } }
        else
            .none;

        // Anchor the deadline once, before the retry loop, exactly as the
        // mailbox does: converting a duration inside the loop would restart
        // the timeout on every spurious wakeup.
        const deadline: Io.Timeout = wanted.toDeadline(io);

        try self._mu.lock(io);
        defer self._mu.unlock(io);

        const bucket = self._bucketFor(want) orelse {
            return error.UnknownIdentity;
        };

        if (self._closed) return error.Closed;

        self._active += 1;
        defer self._active -= 1;

        while (true) {
            if (self._closed) return error.Closed;

            if (bucket.free.pop()) |anchor| {
                slot.* = anchor;
                return;
            }

            cond_timeout.condition_waitTimeout(&self._cv, io, &self._mu, deadline) catch |err| {
                // Whatever ended the wait, something may have arrived first.
                if (self._closed) return error.Closed;

                if (bucket.free.pop()) |anchor| {
                    slot.* = anchor;
                    return;
                }

                return err;
            };
        }
    }

    /// Wraps `getWaitResult` in an `Io.Future`, for `await` or `Io.Group`.
    pub fn getWaitFuture(self: *Pool, want: TypeId, timeout_ns: ?u64) Io.ConcurrentError!Io.Future(Result) {
        return self._io.concurrent(getWaitResult, .{ self, want, timeout_ns });
    }

    /// Gives a parent back and runs your `on_put`.
    ///
    /// The parent leaves your Slot **before** the hook runs, so afterwards
    /// the Slot is empty whatever the hook decided. An empty Slot on entry
    /// is not an error and does nothing.
    ///
    /// A closed pool is silent: the Slot is untouched and the parent stays
    /// with you. That is a race you cannot avoid, so it is not reported.
    ///
    /// `error.UnknownIdentity` is the other half of the pair and is
    /// reported, in every build: it is a caller's mistake about the pool's
    /// own shape, not a race. The Slot is untouched then too.
    ///
    /// **A close while your hook runs loses nothing.** If the pool closed
    /// while `on_put` was running, the parent this call took and everything
    /// the hook added to `extra` go to `on_close` — which is why that hook
    /// may be called more than once, and twice at the same time.
    pub fn put(self: *Pool, slot: *Slot) error{UnknownIdentity}!void {
        const anchor = slot.* orelse return;

        check(!inner.isLinked(anchor), "a parent crosses the border unlinked");

        if (self._closedFast()) return;
        const io: Io = self._io;

        self._mu.lockUncancelable(io);

        if (self._closed) {
            self._mu.unlock(io);
            return;
        }

        self._active += 1;

        const bucket = self._bucketFor(anchor.type_id) orelse {
            self._active -= 1;
            self._mu.unlock(io);
            return error.UnknownIdentity;
        };

        const in_pool = bucket.free.len();

        // The parent is the pool's from here on. The caller's Slot is empty
        // whichever way the rest goes, including the close path below.
        var mine: Slot = anchor;
        slot.* = null;

        var extra: Queue = .{};

        self._mu.unlock(io);
        self._hooks.on_put(self._hooks.ctx, in_pool, &mine, &extra);
        self._mu.lockUncancelable(io);

        if (self._closed) {
            // Closed while the hook ran. Everything this call still holds
            // goes to the close hook rather than being dropped.
            var stragglers: Queue = .{};

            if (mine) |left| {
                mine = null;
                stragglers.append(left);
            }

            stragglers.concat(&extra);

            self._mu.unlock(io);

            if (!stragglers.isEmpty()) {
                const handed: Queue = stragglers;
                stragglers = .{};
                self._hooks.on_close(self._hooks.ctx, handed);
            }

            // `_active` is held across that second hook call, so a `destroy`
            // racing it still aborts.
            self._mu.lockUncancelable(io);
            self._active -= 1;
            self._mu.unlock(io);
            return;
        }

        self._takeBackSlot(&mine);

        while (extra.popFirst()) |one| self._takeBack(one);

        self._cv.broadcast(io);

        self._active -= 1;
        self._mu.unlock(io);
    }

    /// Closes the pool and hands everything still stored to `on_close`.
    ///
    /// Wakes every waiter in `getWait`, which come back with `error.Closed`.
    ///
    /// Safe to call more than once. A later call does nothing and the hook
    /// is not called again by it.
    ///
    /// Cannot fail. Every parent handed to the hook is yours to release —
    /// what those parents are is knowledge the pool does not have.
    pub fn close(self: *Pool) void {
        const io: Io = self._io;

        self._mu.lockUncancelable(io);

        if (self._closed) {
            self._mu.unlock(io);
            return;
        }

        self._active += 1;

        var remaining: Queue = .{};
        self._closeLocked(&remaining);

        self._mu.unlock(io);

        const handed: Queue = remaining;
        remaining = .{};
        self._hooks.on_close(self._hooks.ctx, handed);

        self._mu.lockUncancelable(io);
        self._active -= 1;
        self._mu.unlock(io);
    }

    /// True when the pool is closed.
    ///
    /// One atomic read. It takes no lock, so a hook or a call already inside
    /// the pool may ask it.
    pub inline fn isClosed(self: *Pool) bool {
        return self._closedFast();
    }

    /// True when the pool is closed **and** no call is inside it.
    ///
    /// The readable form of `destroy`'s own precondition: `destroy` aborts
    /// the process when it is wrong, so without this there is no way to ask
    /// whether freeing is allowed yet other than to try it and be right.
    ///
    /// MUST: it takes the mutex. Never call it from inside a call on the
    /// same pool, and **never from a hook** — a hook is caller code running
    /// inside a call, so asking there deadlocks. `isClosed` answers the
    /// other half and takes no lock.
    pub fn isIdle(self: *Pool) bool {
        const io: Io = self._io;

        self._mu.lockUncancelable(io);
        defer self._mu.unlock(io);

        return self._closed and self._active == 0;
    }

    /// How many parents of one identity are stored now.
    ///
    /// `error.UnknownIdentity` for an identity the pool was not made with,
    /// so the whole surface answers a wrong identity one way.
    ///
    /// A hint the moment you have it: another context may take one or give
    /// one back before you read it.
    pub fn countOf(self: *Pool, id: TypeId) error{UnknownIdentity}!usize {
        const io: Io = self._io;

        self._mu.lockUncancelable(io);
        defer self._mu.unlock(io);

        self._active += 1;
        defer self._active -= 1;

        const bucket = self._bucketFor(id) orelse {
            return error.UnknownIdentity;
        };

        return bucket.free.len();
    }

    /// Frees the pool, with the allocator it has held since `newPool`.
    ///
    /// MUST: closed first, and no call still inside it. Both halves are
    /// checked, **in every optimization mode**, and a broken one aborts.
    /// This is not a `check`: freeing a pool another context is still inside
    /// is not a contract a fast build may assume away.
    ///
    /// A hook still running counts as a call inside the pool, so a `destroy`
    /// racing one aborts rather than freeing under it.
    ///
    /// `isIdle` asks the same question without the abort.
    ///
    /// Closing is not done here. `close` hands the stored parents to your
    /// close hook, and they are yours — so doing it here would drop them.
    pub fn destroy(self: *Pool) void {
        const io: Io = self._io;
        const alloc = self._alloc;

        self._mu.lockUncancelable(io);
        const closed = self._closed;
        const active = self._active;
        self._mu.unlock(io);

        if (!closed)
            @panic("Pool.destroy: the pool must be closed first");

        if (active != 0)
            @panic("Pool.destroy: a call is still running on the pool");

        alloc.free(self._buckets);
        alloc.destroy(self);
    }

    /// One identity and what is stored for it.
    const Bucket = struct {
        id: TypeId,
        free: AnchorStack = .{},
    };

    /// The bucket for one identity, or null.
    ///
    /// A plain walk of the array. The set is fixed at creation and small,
    /// and a map would be a second place for the count to live.
    ///
    /// Called with the mutex held.
    fn _bucketFor(self: *Pool, id: TypeId) ?*Bucket {
        for (self._buckets) |*bucket| {
            if (bucket.id == id) return bucket;
        }

        return null;
    }

    /// Closes and empties every bucket into `out`.
    ///
    /// Called with the mutex held, and only when the pool is open.
    fn _closeLocked(self: *Pool, out: *Queue) void {
        self._closed = true;
        self._closed_fast.store(true, .release);

        for (self._buckets) |*bucket| {
            while (bucket.free.pop()) |anchor| out.append(anchor);
        }

        self._cv.broadcast(self._io);
    }

    /// Stores what the Slot holds, if anything, and empties it.
    ///
    /// Called with the mutex held.
    fn _takeBackSlot(self: *Pool, slot: *Slot) void {
        const anchor = slot.* orelse return;
        slot.* = null;
        self._takeBack(anchor);
    }

    /// Stores one parent.
    ///
    /// Called with the mutex held. An identity the pool was not made with is
    /// the hook's own mistake, so it is a check rather than an error return
    /// — there is no caller left to hand it to.
    fn _takeBack(self: *Pool, anchor: *Anchor) void {
        const bucket = self._bucketFor(anchor.type_id) orelse {
            check(false, "the put hook gave back an identity the pool was not created with");
            return;
        };

        bucket.free.push(anchor);
    }

    /// The closed state, without the lock.
    ///
    /// The early answer on every call. A false answer is re-read under the
    /// mutex, so the one that matters is never this one.
    inline fn _closedFast(self: *Pool) bool {
        return self._closed_fast.load(.acquire);
    }

    inline fn init(self: *Pool, alloc: std.mem.Allocator, io: Io) !void {
        _ = self;
        _ = alloc;
        _ = io;
    }

    inline fn finish(self: *Pool, alloc: std.mem.Allocator, io: Io) void {
        _ = self;
        _ = alloc;
        _ = io;
    }

    _link: inner.SLink,

    _mu: Io.Mutex,
    _cv: Io.Condition,

    _io: Io,
    _alloc: std.mem.Allocator,

    _closed: bool,
    _closed_fast: std.atomic.Value(bool),
    _active: usize,

    _buckets: []Pool.Bucket,
    _hooks: Pool.Hooks,
};

/// Makes a pool and puts it in the Slot.
///
/// The allocator is kept for life, and `Pool.destroy` gives the memory back
/// with it.
///
/// `ids` is the fixed set of identities this pool keeps. It is copied into
/// the pool's own buckets, so the caller's slice does not have to outlive
/// the call. Where runtime safety is on, an empty set and a duplicate are
/// both refused.
///
/// Refuses a Slot that is not empty on entry. On failure the Slot is
/// unchanged.
///
/// Take the pointer out with `Pool.moveFromSlot`.
pub fn new(
    alloc: std.mem.Allocator,
    io: Io,
    ids: []const TypeId,
    hooks: Pool.Hooks,
    slot: *Slot,
) !void {
    check(slot.* == null, "an acquisition needs an empty Slot on entry");
    check(ids.len > 0, "a pool keeps at least one identity");

    if (std.debug.runtime_safety) {
        for (ids, 0..) |one, i| {
            for (ids[i + 1 ..]) |other| {
                check(one != other, "the pool's set of identities has a duplicate");
            }
        }
    }

    const pool: *Pool = try alloc.create(Pool);
    errdefer alloc.destroy(pool);

    const buckets: []Pool.Bucket = try alloc.alloc(Pool.Bucket, ids.len);
    errdefer alloc.free(buckets);

    for (buckets, ids) |*bucket, id| bucket.* = .{ .id = id };

    pool.* = .{
        ._link = .{},
        ._mu = .init,
        ._cv = .init,
        ._io = io,
        ._alloc = alloc,
        ._closed = false,
        ._closed_fast = std.atomic.Value(bool).init(false),
        ._active = 0,
        ._buckets = buckets,
        ._hooks = hooks,
    };

    helper.stamp(pool);

    slot.* = Pool.toAnchor(pool);
}

/// Packs every outcome of a `getWait` into a `Pool.Result`.
///
/// Waits. The building block for `Io.Select`, `io.concurrent` and
/// `Io.Group`. The pool's state does not change because of the packing.
pub fn getWaitResult(pool: *Pool, want: TypeId, timeout_ns: ?u64) Pool.Result {
    var slot: Slot = null;

    pool.getWait(want, &slot, timeout_ns) catch |err| return switch (err) {
        error.Closed => .closed,
        error.Timeout => .timeout,
        error.Canceled => .canceled,
        error.UnknownIdentity => .unknown_identity,
    };

    return .{ .anchor = slot.? };
}

const helper = @import("helper.zig").ParentHelper(Pool);

const check = @import("internal/check.zig").check;
const cond_timeout = @import("internal/cond_timeout.zig");
const inner = @import("inner.zig");
const queue = @import("queue.zig");
const Anchor = inner.Anchor;
const AnchorStack = @import("internal/stack.zig").AnchorStack;
const Io = std.Io;
const TypeId = inner.TypeId;
const Queue = queue.Queue;
const Slot = inner.Slot;
const std = @import("std");
