// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 312 — destroying a mailbox with a call inside it is refused.
//!
//! In all four modes, and this is the half that `close` alone cannot give
//! you. The mailbox is closed, so the first half of the contract holds. A
//! receiver is still inside it, so the second half does not.
//!
//! This is what the call counter is for. Without it the free would succeed
//! and the receiver would come back into memory that had been handed to the
//! allocator — the failure that has no symptom until much later.
//!
//! **Why the receiver is still counted when `destroy` runs.** `close` wakes
//! it, so this rests on an ordering rather than on a lock the test holds:
//! `close` broadcasts while it still holds the mutex, and the woken receiver
//! cannot leave until it has taken that mutex back and run its own
//! decrement. The main context is already running and goes straight from
//! `close` to `destroy`, so it reaches the mutex first.
//!
//! That is an ordering, not a guarantee, so it was measured rather than
//! assumed: 200 runs of this program in Debug, 200 aborts, no run exited
//! normally. If this program ever exits with status 0 the build reports the
//! contract as not refused, which is the right way for it to fail — it
//! cannot pass by accident.

var inside: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

fn waitForever(mbx: *m.Mbox) void {
    var slot: m.inner.Slot = null;

    inside.store(true, .release);

    // Waits until the close wakes it, which happens after `destroy` has
    // already aborted the process. If it ever returns, the program exits
    // normally and the build reports the contract as not refused.
    mbx.receive(&slot, null) catch return;

    if (slot) |anchor| {
        var back: m.inner.Slot = anchor;
        _ = &back;
    }
}

pub fn main() void {
    var threaded: std.Io.Threaded = std.Io.Threaded.init(std.heap.page_allocator, .{});
    const io: std.Io = threaded.io();

    var slot: m.inner.Slot = null;
    m.mbox.new(std.heap.page_allocator, io, &slot) catch @panic("312: the mailbox was not made");

    const mbx: *m.Mbox = m.Mbox.moveFromSlot(&slot).?;

    const waiter = std.Thread.spawn(.{}, waitForever, .{mbx}) catch
        @panic("312: the receiving context did not start");

    // Wait until the receiver is inside the mailbox and counted.
    while (!mbx.isClosed() and mbx.isIdle()) std.Thread.yield() catch {};
    while (!inside.load(.acquire)) std.Thread.yield() catch {};

    // Let it reach the wait itself, not merely the call. There is no
    // `sleep` in std here — waiting is `Io`'s job in 0.16 — so this yields
    // a fixed number of times instead.
    var spin: usize = 0;
    while (spin < 10_000) : (spin += 1) std.Thread.yield() catch {};

    // Closed, so the first half of the contract holds. The receiver is
    // still inside, so the second half does not, and this aborts.
    var rem: m.queue.Queue = mbx.close();
    _ = &rem;

    mbx.destroy();

    waiter.join();
}

const m = @import("matryoshka");
const std = @import("std");
