// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! A queue between threads and tasks that answers the hard questions.
//!
//! Many senders, many receivers. It does its own locking. It moves an
//! `*Anchor` and never learns your type.
//!
//! The mailbox keeps parents. It never touches them. Nothing is allocated when
//! a parent is sent and nothing is freed when one arrives.
//!
//! - No inspection.
//! - No copy.
//! - No release.
//!
//! ## Making one
//!
//! - `new` fills a Slot with the new mailbox. The mailbox keeps the
//!   allocator until it is destroyed.
//! - `Mbox.destroy` is a method. It frees the mailbox with that allocator.
//! - Only `new` makes a mailbox, not the helper.
//!   - The mailbox allocates itself.
//!   - It declares no `init` and no `finish`.
//!   - So `ParentHelper(Mbox).create` does not compile.
//! - `Mbox.ID`, `toAnchor` and `fromAnchor` let a mailbox travel inside
//!   another mailbox or pool.
//!
//! ## Sending
//!
//! - `send` takes a full Slot and empties it.
//! - `sendLimited` refuses when the sender's own type already has that many
//!   ordinary parents queued.
//! - `sendOob` puts the parent ahead of every ordinary one, for work that
//!   must not wait behind the rest. It takes no limit.
//!
//! ## Receiving
//!
//! - `tryReceive` takes what is there and does not wait.
//! - `receive` waits up to a timeout, or forever.
//! - `receiveAll` returns everything queued, in receive order.
//! - `wakeUpAll` returns every waiter at once.
//! - Out-of-band parents come out first.
//!
//! ## Where the parent is afterwards
//!
//! - A send that worked leaves your Slot empty.
//! - A refused send leaves the parent in your Slot, whatever the reason.
//!   - Look at the Slot to know where the parent is.
//!   - No error ever takes it from you.
//! - `tryReceive` and `receive` fill an empty Slot. A full one is refused.
//!
//! ## Shutting down
//!
//! - `close` returns everything still queued. It loses nothing.
//! - You release those parents by your own rules, or give them back to a pool.
//! - `close` on a closed mailbox returns an empty queue. It is not an error.
//! - Every waiter in `receive` comes back with `error.Closed`.
//! - `isClosed` is the state. `isIdle` says closed with no call still inside.
//! - `len` is how many parents are queued now.
//!
//! Examples:
//! https://g41797.github.io/matryoshka-ztk/examples/mailbox/
const _doc_stub = void;

/// A mailbox. It moves parents between threads and tasks.
///
/// A mailbox is itself a parent. Use `toAnchor` and `fromAnchor` to send one
/// through another mailbox or pool.
///
/// The fields are internal. Their names start with `_`, because Zig has no
/// private fields.
pub const Mbox = struct {
    /// Every outcome of a receive, packed into one value.
    ///
    /// For `Io.Select` and `Io.Group`, through `receiveResult`.
    pub const Result = union(enum) {
        anchor: *Anchor,
        closed: void,
        timeout: void,
        canceled: void,
        wakeup: void,
    };

    /// This type's id.
    pub const ID: TypeId = helper.ID;

    /// True when the id is a mailbox's.
    pub inline fn isIt(id: TypeId) bool {
        return helper.isIt(id);
    }

    /// The Anchor embedded in the mailbox.
    ///
    /// Use it to send a mailbox through another mailbox or pool.
    pub inline fn toAnchor(self: *Mbox) *Anchor {
        return helper.toAnchor(self);
    }

    /// The mailbox, from a bare Anchor. Null when the Anchor is another type.
    pub inline fn fromAnchor(anchor: *Anchor) ?*Mbox {
        return helper.fromAnchor(anchor);
    }

    /// The mailbox, from a bare Anchor. Panics on another type.
    pub inline fn mustFromAnchor(anchor: *Anchor) *Mbox {
        return helper.mustFromAnchor(anchor);
    }

    /// The mailbox, from the Slot it sits in. The Slot stays full.
    pub inline fn fromSlot(slot: *const Slot) ?*Mbox {
        return helper.fromSlot(slot);
    }

    /// The mailbox, from the Slot it sits in. Panics on an empty Slot or
    /// another type.
    pub inline fn mustFromSlot(slot: *const Slot) *Mbox {
        return helper.mustFromSlot(slot);
    }

    /// Takes the mailbox out of the Slot. On success the Slot is empty.
    ///
    /// Null when the Slot is empty or has another type. The Slot is untouched
    /// then.
    pub inline fn moveFromSlot(slot: *Slot) ?*Mbox {
        return helper.moveFromSlot(slot);
    }

    /// Sends a parent. It goes behind every parent already queued.
    ///
    /// On success the Slot is empty. On `error.Closed` the Slot is
    /// unchanged and the sender still has the parent.
    ///
    /// Refuses an empty Slot, and a parent still on a chain.
    pub fn send(self: *Mbox, slot: *Slot) error{Closed}!void {
        return self._sendAt(slot, .ordinary, 0) catch |err| switch (err) {
            error.Closed => error.Closed,
            error.Limit => unreachable, // a limit of zero never refuses
        };
    }

    /// Sends a parent, unless this many of its own type are already queued.
    ///
    /// It counts only the sender's own type, and only **ordinary** queued
    /// parents.
    ///
    /// - Other types do not count.
    /// - Out-of-band parents do not count.
    ///
    /// A limit of zero is an ordinary `send`.
    ///
    /// On `error.Limit` the Slot is unchanged, as on `error.Closed`. One look
    /// at the Slot tells you whether the parent moved.
    pub fn sendLimited(self: *Mbox, slot: *Slot, limit: usize) error{ Closed, Limit }!void {
        return self._sendAt(slot, .ordinary, limit);
    }

    /// Sends a parent ahead of every ordinary one.
    ///
    /// Out-of-band parents keep their order among themselves. Every one of
    /// them comes out before every ordinary one.
    ///
    /// ```text
    /// send(R1), send(R2):   oob []        ordinary [R1, R2]
    /// sendOob(O1):          oob [O1]      ordinary [R1, R2]
    /// send(R3):             oob [O1]      ordinary [R1, R2, R3]
    /// sendOob(O2):          oob [O1, O2]  ordinary [R1, R2, R3]
    /// receive -> O1, then O2, then R1, R2, R3
    /// ```
    ///
    /// It takes no limit.
    pub fn sendOob(self: *Mbox, slot: *Slot) error{Closed}!void {
        return self._sendAt(slot, .out_of_band, 0) catch |err| switch (err) {
            error.Closed => error.Closed,
            error.Limit => unreachable, // out of band is never limited
        };
    }

    /// Receives a parent, waiting until one is there.
    ///
    /// - `timeout_ns` null waits forever.
    /// - `timeout_ns` zero returns at once on an empty mailbox, with
    ///   `error.Timeout`. It is `tryReceive`, with an error in place of false.
    ///
    /// It stops waiting on a timeout, a cancel or `wakeUpAll`. The Slot stays
    /// empty then. A cancel does not close the mailbox.
    ///
    /// When several receivers wait, one of them gets each parent. The `Io`
    /// runtime picks which. It is not first in, first out.
    ///
    /// Refuses a Slot that is not empty on entry.
    pub fn receive(
        self: *Mbox,
        slot: *Slot,
        timeout_ns: ?u64,
    ) (error{ Closed, Timeout, Wakeup } || Io.Cancelable)!void {
        check(slot.* == null, "an acquisition needs an empty Slot on entry");

        if (self._closedFast()) return error.Closed;
        const io: Io = self._io;

        const wanted: Io.Timeout = if (timeout_ns) |ns|
            .{ .duration = .{ .raw = .{ .nanoseconds = @as(i96, @intCast(ns)) }, .clock = .real } }
        else
            .none;

        // Anchor the deadline once, before the retry loop.
        // `condition_waitTimeout` calls `toDeadline` itself, but converting a
        // duration inside the loop would restart the timeout on every
        // spurious wakeup.
        const deadline: Io.Timeout = wanted.toDeadline(io);

        try self._mu.lock(io);
        defer self._mu.unlock(io);

        if (self._closed) return error.Closed;

        self._active += 1;
        defer self._active -= 1;

        const my_epoch: u64 = self._wake_epoch;

        while (true) {
            if (self._closed) return error.Closed;

            if (self._dequeue()) |anchor| {
                slot.* = anchor;
                return;
            }

            if (self._wake_epoch != my_epoch) return error.Wakeup;

            cond_timeout.condition_waitTimeout(&self._cv, io, &self._mu, deadline) catch |err| {
                // Whatever ended the wait, something may have arrived first.
                if (self._closed) return error.Closed;

                if (self._dequeue()) |anchor| {
                    slot.* = anchor;
                    return;
                }

                if (self._wake_epoch != my_epoch) return error.Wakeup;

                return err;
            };
        }
    }

    /// Receives a parent if one is there now. It never waits.
    ///
    /// True when a parent was received, false when the mailbox was empty.
    /// An empty mailbox is not an error.
    ///
    /// Refuses a Slot that is not empty on entry.
    pub fn tryReceive(self: *Mbox, slot: *Slot) error{Closed}!bool {
        check(slot.* == null, "an acquisition needs an empty Slot on entry");

        if (self._closedFast()) return error.Closed;
        const io: Io = self._io;

        self._mu.lockUncancelable(io);
        defer self._mu.unlock(io);

        if (self._closed) return error.Closed;

        self._active += 1;
        defer self._active -= 1;

        const anchor = self._dequeue() orelse return false;
        slot.* = anchor;
        return true;
    }

    /// Returns every queued parent at once, in receive order.
    ///
    /// The mailbox stays open, and is empty afterwards. An empty mailbox
    /// returns an empty queue. That is not an error. It never waits.
    ///
    /// The queue is **moved** to you. Every parent on it is yours to release:
    /// free it, or give it back to a pool.
    pub fn receiveAll(self: *Mbox) error{Closed}!Queue {
        if (self._closedFast()) return error.Closed;
        const io: Io = self._io;

        self._mu.lockUncancelable(io);
        defer self._mu.unlock(io);

        if (self._closed) return error.Closed;

        self._active += 1;
        defer self._active -= 1;

        return self._takeAll();
    }

    /// Closes the mailbox and returns everything still queued.
    ///
    /// Every waiting receiver wakes up, with `error.Closed`.
    ///
    /// You may call it more than once. A later call returns an empty queue.
    ///
    /// Cannot fail.
    ///
    /// Every parent on the returned queue is yours to release. Only you know
    /// what each one is: a heap parent to free, or a pool parent to give back.
    ///
    /// Always run the release loop. An empty queue costs nothing, so you never
    /// need to know whether the mailbox was emptied first:
    ///
    /// ```zig
    /// var rem: Queue = mbx.close();
    /// while (rem.popFirst()) |item| {
    ///     // release it
    /// }
    /// ```
    ///
    /// Never write `_ = mbx.close()`. It drops the parents the mailbox just
    /// gave back.
    pub fn close(self: *Mbox) Queue {
        const io: Io = self._io;

        // Read and set `_closed` inside the mutex, so a `destroy` cannot race
        // a `close` that was preempted between the two.
        self._mu.lockUncancelable(io);
        defer self._mu.unlock(io);

        self._active += 1;
        defer self._active -= 1;

        if (self._closed) return .{};

        self._closed = true;
        self._closed_fast.store(true, .release);

        const out = self._takeAll();

        self._cv.broadcast(io);

        return out;
    }

    /// Wakes every waiting receiver, with `error.Wakeup`.
    ///
    /// A receiver that starts waiting later is not affected. The mailbox stays
    /// open.
    ///
    /// It is not a cancel.
    pub fn wakeUpAll(self: *Mbox) error{Closed}!void {
        if (self._closedFast()) return error.Closed;
        const io: Io = self._io;

        self._mu.lockUncancelable(io);
        defer self._mu.unlock(io);

        if (self._closed) return error.Closed;

        self._active += 1;
        defer self._active -= 1;

        self._wake_epoch += 1;
        self._cv.broadcast(io);
    }

    /// True when the mailbox is closed.
    ///
    /// It takes no lock. So a hook, or a call already inside the mailbox, may
    /// ask it.
    pub inline fn isClosed(self: *Mbox) bool {
        return self._closedFast();
    }

    /// True when the mailbox is closed **and** no call is inside it.
    ///
    /// Ask it before `destroy`. `destroy` aborts the process when this is
    /// false.
    ///
    /// It takes the lock. You MUST NOT call it from inside a call on the same
    /// mailbox. `isClosed` takes no lock.
    pub fn isIdle(self: *Mbox) bool {
        const io: Io = self._io;

        self._mu.lockUncancelable(io);
        defer self._mu.unlock(io);

        return self._closed and self._active == 0;
    }

    /// How many parents are queued now, out of band and ordinary together.
    pub fn len(self: *Mbox) usize {
        const io: Io = self._io;

        self._mu.lockUncancelable(io);
        defer self._mu.unlock(io);

        self._active += 1;
        defer self._active -= 1;

        return self._oob.len() + self._regular.len();
    }

    /// Frees the mailbox, with the allocator it got in `new`.
    ///
    /// The mailbox MUST be closed first, with no call still inside it. Both
    /// are checked **in every optimization mode**. A broken one aborts the
    /// process.
    ///
    /// `isIdle` asks the same question without the abort.
    ///
    /// `destroy` does not close. Call `close` first, and release the parents
    /// it returns.
    ///
    /// `destroy` does not look at the mailbox's own TypedNode. Do not free a
    /// mailbox that is still on a chain.
    pub fn destroy(self: *Mbox) void {
        const io: Io = self._io;
        const alloc = self._alloc;

        self._mu.lockUncancelable(io);
        const closed = self._closed;
        const active = self._active;
        self._mu.unlock(io);

        if (!closed)
            @panic("Mbox.destroy: the mailbox must be closed first");

        if (active != 0)
            @panic("Mbox.destroy: a call is still running on the mailbox");

        alloc.destroy(self);
    }

    /// Wraps `receiveResult` in an `Io.Future`, for `await` or `Io.Group`.
    pub fn receiveFuture(self: *Mbox, timeout_ns: ?u64) Io.ConcurrentError!Io.Future(Result) {
        return self._io.concurrent(receiveResult, .{ self, timeout_ns });
    }

    /// Which of the two queues a parent joins.
    const Lane = enum { ordinary, out_of_band };

    /// Send, in one place. The three public forms differ by lane and limit.
    fn _sendAt(self: *Mbox, slot: *Slot, lane: Lane, limit: usize) error{ Closed, Limit }!void {
        check(slot.* != null, "Mbox.send from an empty Slot");

        const anchor = slot.* orelse return;

        check(!inner.isLinked(anchor), "a parent crosses the border unlinked");

        if (self._closedFast()) return error.Closed;
        const io: Io = self._io;

        self._mu.lockUncancelable(io);
        defer self._mu.unlock(io);

        if (self._closed) return error.Closed;

        self._active += 1;
        defer self._active -= 1;

        if (lane == .ordinary and limit > 0) {
            if (self._regular.countOfId(anchor.typeId(), limit) >= limit) return error.Limit;
        }

        switch (lane) {
            .ordinary => self._regular.append(anchor),
            .out_of_band => self._oob.append(anchor),
        }

        slot.* = null;

        self._cv.signal(io);
    }

    /// The next parent out: out of band first, then ordinary.
    ///
    /// Called with the mutex held.
    inline fn _dequeue(self: *Mbox) ?*Anchor {
        return self._oob.popFirst() orelse self._regular.popFirst();
    }

    /// Both queues, moved out in receive order, leaving the mailbox empty.
    ///
    /// Called with the mutex held.
    inline fn _takeAll(self: *Mbox) Queue {
        var out: Queue = .{};
        out.concat(&self._oob);
        out.concat(&self._regular);
        return out;
    }

    /// The closed state, without the lock.
    ///
    /// The early answer on every call. A false answer is re-read under the
    /// mutex, so the one that matters is never this one.
    inline fn _closedFast(self: *Mbox) bool {
        return self._closed_fast.load(.acquire);
    }

    inline fn init(self: *Mbox, alloc: std.mem.Allocator, io: Io) !void {
        _ = self;
        _ = alloc;
        _ = io;
    }

    inline fn finish(self: *Mbox, alloc: std.mem.Allocator, io: Io) void {
        _ = self;
        _ = alloc;
        _ = io;
    }

    _tnode: inner.SinglyTypedNode,

    _mu: Io.Mutex,
    _cv: Io.Condition,

    _io: Io,
    _alloc: std.mem.Allocator,

    _closed: bool,
    _closed_fast: std.atomic.Value(bool),
    _active: usize,

    _oob: Queue,
    _regular: Queue,

    _wake_epoch: u64,
};

/// Makes a mailbox and puts it in the Slot.
///
/// The mailbox keeps the allocator. `Mbox.destroy` frees the mailbox with
/// it.
///
/// Refuses a Slot that is not empty on entry. On failure the Slot is
/// unchanged.
///
/// Take the pointer out with `Mbox.moveFromSlot`.
pub fn new(alloc: std.mem.Allocator, io: Io, slot: *Slot) !void {
    check(slot.* == null, "an acquisition needs an empty Slot on entry");

    const mbx: *Mbox = try alloc.create(Mbox);
    errdefer alloc.destroy(mbx);

    mbx.* = .{
        ._tnode = .{},
        ._mu = .init,
        ._cv = .init,
        ._io = io,
        ._alloc = alloc,
        ._closed = false,
        ._closed_fast = std.atomic.Value(bool).init(false),
        ._active = 0,
        ._oob = .{},
        ._regular = .{},
        ._wake_epoch = 0,
    };

    helper.setTypeId(mbx);

    slot.* = Mbox.toAnchor(mbx);
}

/// Packs every outcome of a `receive` into a `Mbox.Result`.
///
/// It waits. Use it with `Io.Select`, `io.concurrent` and `Io.Group`. The
/// packing does not change the mailbox.
pub fn receiveResult(mbx: *Mbox, timeout_ns: ?u64) Mbox.Result {
    var slot: Slot = null;

    mbx.receive(&slot, timeout_ns) catch |err| return switch (err) {
        error.Closed => .closed,
        error.Timeout => .timeout,
        error.Canceled => .canceled,
        error.Wakeup => .wakeup,
    };

    return .{ .anchor = slot.? };
}

const helper = @import("helper.zig").ParentHelper(Mbox);

const check = @import("internal/check.zig").check;
const cond_timeout = @import("internal/cond_timeout.zig");
const inner = @import("inner.zig");
const queue = @import("queue.zig");
const Anchor = inner.Anchor;
const Io = std.Io;
const TypeId = inner.TypeId;
const Queue = queue.Queue;
const Slot = inner.Slot;
const std = @import("std");
