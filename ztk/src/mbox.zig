// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! A queue between contexts that answers the hard questions.
//!
//! Many senders, many receivers. It does its own locking. It moves an
//! `*Anchor` and never learns your type.
//!
//! The mailbox keeps items. It never touches them. Nothing is allocated when
//! a parent is sent and nothing is freed when one arrives.
//!
//! - No inspection.
//! - No copy.
//! - No release.
//!
//! ## Making one
//!
//! - `new` fills a Slot, and keeps the allocator for life.
//! - `Mbox.destroy` is a method and gives that memory back.
//! - A mailbox is made by this call, not by the helper: it allocates itself,
//!   so it declares no `init` and no `finish`, and asking `ParentHelper` for
//!   `create` does not compile.
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
//! - `receiveAll` hands back everything queued, in receive order.
//! - `wakeUpAll` returns every waiter at once.
//! - Out-of-band parents come out first.
//!
//! ## Where the parent is afterwards
//!
//! - A send that worked leaves your Slot empty.
//! - A send refused leaves the parent in your Slot, whichever refusal it was.
//!   So the Slot answers it, and you do not have to remember which failure
//!   took the item.
//! - `tryReceive` and `receive` fill an empty Slot. A full one is refused.
//!
//! ## Shutting down
//!
//! - `close` hands back everything still queued, and loses nothing.
//! - You release those parents by your own rules, or give them back to a pool.
//! - `close` on an already closed mailbox hands back an empty queue, and is
//!   not an error.
//! - Every waiter in `receive` comes back with `error.Closed`.
//! - `isClosed` is the state. `isIdle` says closed with no call still inside.
//! - `len` is how many parents are queued now.
//!
//! Examples:
//! https://g41797.github.io/matryoshka-ztk/examples/mailbox/
const _doc_stub = void;

/// A mailbox — the tool for moving parents between contexts.
///
/// A mailbox is itself a parent. Use `toAnchor` and `fromAnchor` to send one
/// through another mailbox or pool.
///
/// The fields are internal. Their names start with `_` for that reason;
/// Zig has no private field.
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

    /// The mailbox, from the Slot holding it. Leaves the Slot full.
    pub inline fn fromSlot(slot: *const Slot) ?*Mbox {
        return helper.fromSlot(slot);
    }

    /// The mailbox, from the Slot holding it. Panics on an empty Slot or
    /// another type.
    pub inline fn mustFromSlot(slot: *const Slot) *Mbox {
        return helper.mustFromSlot(slot);
    }

    /// Takes the mailbox out of the Slot, leaving it empty.
    ///
    /// Null when the Slot is empty or holds another type, and then the Slot
    /// is untouched.
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
    /// The count is of the sender's own parent type among the **ordinary**
    /// queued parents. Other types do not count toward it, and out-of-band
    /// parents are not counted.
    ///
    /// A limit of zero is an ordinary `send`.
    ///
    /// On `error.Limit` the Slot is unchanged, exactly as on `error.Closed`.
    /// So one look at the Slot says whether the parent moved.
    pub fn sendLimited(self: *Mbox, slot: *Slot, limit: usize) error{ Closed, Limit }!void {
        return self._sendAt(slot, .ordinary, limit);
    }

    /// Sends a parent ahead of every ordinary one.
    ///
    /// Out-of-band parents keep their own order among themselves, and every
    /// one of them sits ahead of every ordinary one. Two queues do that, so
    /// nothing is inserted into the middle of a chain.
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
    /// - `timeout_ns` zero comes back at once on an empty mailbox, with
    ///   `error.Timeout`. The same reach as `tryReceive`, reported as an
    ///   error rather than as false.
    ///
    /// It breaks on a timeout, on a cancel, and on `wakeUpAll`. On every
    /// break the Slot stays empty. A cancel does not close the mailbox.
    ///
    /// Several receivers compete for each parent and one gets it. The order
    /// among them is the `Io` runtime's, and it is not first in, first out.
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

    /// Receives a parent if one is there now. Never waits.
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

    /// Hands back every queued parent at once, in receive order.
    ///
    /// The mailbox stays open and is empty afterwards. An empty mailbox
    /// hands back an empty queue, which is not an error. This never waits.
    ///
    /// The queue is **moved** to you, and every parent on it is yours to
    /// release — free them, or give them back to a pool.
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

    /// Closes the mailbox and hands back everything still queued.
    ///
    /// Wakes every waiting receiver, which come back with `error.Closed`.
    ///
    /// Safe to call more than once. A later call hands back an empty queue.
    ///
    /// Cannot fail.
    ///
    /// Every parent on the returned queue is yours to release. What those
    /// parents are — heap parents to free, pool parents to give back — is
    /// knowledge the mailbox does not have and never had.
    ///
    /// Run the release loop unconditionally. An empty queue costs nothing,
    /// so no call site has to know whether the mailbox was emptied first:
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

    /// Wakes every blocked receiver, which come back with `error.Wakeup`.
    ///
    /// Receivers that start waiting later are not affected: the effect does
    /// not outlive the call. The mailbox stays open.
    ///
    /// Not a cancel.
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
    /// One atomic read. It takes no lock, so a hook or a call already inside
    /// the mailbox may ask it.
    pub inline fn isClosed(self: *Mbox) bool {
        return self._closedFast();
    }

    /// True when the mailbox is closed **and** no call is inside it.
    ///
    /// This is the readable form of `destroy`'s own precondition, and that
    /// is what it is for: `destroy` aborts the process when it is wrong, so
    /// without this there is no way to ask whether freeing is allowed yet
    /// other than to try it and be right.
    ///
    /// MUST: it takes the mutex. Never call it from inside a call on the
    /// same mailbox. `isClosed` answers the other half and takes no lock.
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

    /// Frees the mailbox, with the allocator it has held since `new`.
    ///
    /// MUST: closed first, and no call still inside it. Both halves are
    /// checked, **in every optimization mode**, and a broken one aborts.
    /// This is not a `check`: freeing a mailbox another context is still
    /// inside is not a contract a fast build may assume away.
    ///
    /// `isIdle` asks the same question without the abort.
    ///
    /// Closing is not done here. `close` hands back the parents the mailbox
    /// keeps, and that queue belongs to the caller — so doing it here would
    /// drop them.
    ///
    /// The mailbox's own TypedNode is not consulted. A mailbox that is still
    /// on a chain is a caller who freed something another container holds,
    /// and the chain is the place that notices.
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
/// The allocator is kept for life, and `Mbox.destroy` gives the memory back
/// with it.
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
/// Waits. The building block for `Io.Select`, `io.concurrent` and
/// `Io.Group`. The mailbox's state does not change because of the packing.
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
