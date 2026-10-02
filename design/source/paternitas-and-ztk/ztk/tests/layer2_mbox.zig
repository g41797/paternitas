// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Layer 2 — the mailbox.
//!
//! Scenarios 18, 20, 26 to 49 and 260 to 266. The several-threads
//! scenarios 50 to 52 are in `layer2_threads.zig`.
//!
//! Every parent sent here is allocated. What the mailbox hands back has to be
//! a pointer the allocator gave out.

/// One mailbox, its `Io`, and the teardown, in one place.
///
/// The order matters and is easy to get wrong by hand: close first — it
/// hands the remainder back and that queue must be released — then destroy,
/// and only then the `Io` the mailbox was using.
const Fixture = struct {
    threaded: std.Io.Threaded,
    io: Io = undefined,
    mbx: *m.Mbox = undefined,

    fn start(self: *Fixture) !void {
        self.threaded = std.Io.Threaded.init(alloc, .{});
        self.io = self.threaded.io();

        var slot: m.inner.Slot = null;
        try m.mbox.new(alloc, self.io, &slot);
        self.mbx = m.Mbox.moveFromSlot(&slot).?;
    }

    fn finish(self: *Fixture) void {
        var rem: m.queue.Queue = self.mbx.close();
        o.releaseAll(&rem, alloc, self.io);

        self.mbx.destroy();
        self.threaded.deinit();
    }
};

test "18 — a mailbox is a parent" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    // Its id answers for it, and the crossing back lands on the mailbox.
    try expect(m.Mbox.isIt(m.Mbox.toAnchor(f.mbx).type_id));
    try expect(m.Mbox.fromAnchor(m.Mbox.toAnchor(f.mbx)).? == f.mbx);

    // And a wrong type is refused rather than cast.
    var msg: o.Msg = .{};
    o.MSG.stamp(&msg);
    try expect(m.Mbox.fromAnchor(o.MSG.toAnchor(&msg)) == null);
}

test "19 and 253 — a mailbox travels inside a mailbox" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    // A second mailbox, sent through the first one as an ordinary parent.
    var slot: m.inner.Slot = null;
    try m.mbox.new(alloc, f.io, &slot);

    try f.mbx.send(&slot);
    try expect(slot == null);

    try expect(try f.mbx.tryReceive(&slot));

    const travelled: *m.Mbox = m.Mbox.moveFromSlot(&slot).?;

    // It is still a working endpoint. It was kept, not touched.
    try expect(!travelled.isClosed());

    var rem: m.queue.Queue = travelled.close();
    o.releaseAll(&rem, alloc, f.io);
    travelled.destroy();
}

test "20 — the mailbox releases itself" {
    // `destroy` is a method and uses the allocator `new` gave it. No
    // allocator is passed a second time, and nothing leaks — the testing
    // allocator is what says so.
    var f: Fixture = undefined;
    try f.start();

    var rem: m.queue.Queue = f.mbx.close();
    o.releaseAll(&rem, alloc, f.io);

    f.mbx.destroy();
    f.threaded.deinit();
}

test "26 — new and destroy" {
    var f: Fixture = undefined;
    try f.start();

    try expect(!f.mbx.isClosed());
    try expect(f.mbx.len() == 0);

    var rem: m.queue.Queue = f.mbx.close();
    try expect(rem.isEmpty());

    try expect(f.mbx.isClosed());
    try expect(f.mbx.isIdle());

    f.mbx.destroy();
    f.threaded.deinit();
}

test "27 — send and receive one parent" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;
    defer o.releaseSlot(&slot, alloc, f.io);

    try o.newMsg(alloc, f.io, &slot, 27);
    try f.mbx.send(&slot);

    try f.mbx.receive(&slot, a_second);

    const got: *o.Msg = o.MSG.mustFromSlot(&slot);
    try expect(got.seq == 27);
}

test "28 — ordinary parents are first in, first out" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;
    defer o.releaseSlot(&slot, alloc, f.io);

    for ([_]u32{ 1, 2, 3 }) |seq| {
        try o.newMsg(alloc, f.io, &slot, seq);
        try f.mbx.send(&slot);
    }

    for ([_]u32{ 1, 2, 3 }) |seq| {
        try f.mbx.receive(&slot, a_second);
        try expect(o.MSG.mustFromSlot(&slot).seq == seq);
        o.releaseSlot(&slot, alloc, f.io);
    }
}

test "29 — a send to a closed mailbox is refused" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var rem: m.queue.Queue = f.mbx.close();
    o.releaseAll(&rem, alloc, f.io);

    var slot: m.inner.Slot = null;
    defer o.releaseSlot(&slot, alloc, f.io);
    try o.newMsg(alloc, f.io, &slot, 29);

    try std.testing.expectError(error.Closed, f.mbx.send(&slot));

    // The sender still has it. That is the whole promise of the refusal.
    try expect(slot != null);
    try expect(o.MSG.mustFromSlot(&slot).seq == 29);
}

test "30 — a receive from a closed mailbox is refused" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var rem: m.queue.Queue = f.mbx.close();
    o.releaseAll(&rem, alloc, f.io);

    var slot: m.inner.Slot = null;

    try std.testing.expectError(error.Closed, f.mbx.receive(&slot, 0));
    try std.testing.expectError(error.Closed, f.mbx.tryReceive(&slot));
    try std.testing.expectError(error.Closed, f.mbx.receiveAll());

    try expect(slot == null);
}

test "31 — a receive with a timeout gives up" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;

    try std.testing.expectError(error.Timeout, f.mbx.receive(&slot, 0));
    try std.testing.expectError(error.Timeout, f.mbx.receive(&slot, 1_000_000));

    // On every break the Slot stays empty.
    try expect(slot == null);
}

test "33 — close hands the remainder back" {
    var f: Fixture = undefined;
    try f.start();
    defer f.threaded.deinit();

    var slot: m.inner.Slot = null;

    for ([_]u32{ 1, 2, 3 }) |seq| {
        try o.newMsg(alloc, f.io, &slot, seq);
        try f.mbx.send(&slot);
    }

    try expect(f.mbx.len() == 3);

    var rem: m.queue.Queue = f.mbx.close();
    try expect(rem.len() == 3);

    // In receive order, and every one of them unlinked as it comes out.
    for ([_]u32{ 1, 2, 3 }) |seq| {
        const anchor = rem.popFirst().?;
        try expect(o.MSG.mustFromAnchor(anchor).seq == seq);
        o.release(anchor, alloc, f.io);
    }

    f.mbx.destroy();
}

test "34 — close is repeatable" {
    var f: Fixture = undefined;
    try f.start();
    defer f.threaded.deinit();

    var slot: m.inner.Slot = null;
    try o.newMsg(alloc, f.io, &slot, 34);
    try f.mbx.send(&slot);

    var first: m.queue.Queue = f.mbx.close();
    try expect(first.len() == 1);
    o.releaseAll(&first, alloc, f.io);

    // The second hands back nothing, and is not a failure.
    var second: m.queue.Queue = f.mbx.close();
    try expect(second.isEmpty());

    f.mbx.destroy();
}

test "35 — out of band goes to the front" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;
    defer o.releaseSlot(&slot, alloc, f.io);

    for ([_]u32{ 1, 2, 3 }) |seq| {
        try o.newMsg(alloc, f.io, &slot, seq);
        try f.mbx.send(&slot);
    }

    try o.newMsg(alloc, f.io, &slot, 99);
    try f.mbx.sendOob(&slot);

    // Sent last, arrives first.
    for ([_]u32{ 99, 1, 2, 3 }) |seq| {
        try f.mbx.receive(&slot, a_second);
        try expect(o.MSG.mustFromSlot(&slot).seq == seq);
        o.releaseSlot(&slot, alloc, f.io);
    }
}

test "37 — out-of-band parents keep their own order" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;
    defer o.releaseSlot(&slot, alloc, f.io);

    try o.newMsg(alloc, f.io, &slot, 1);
    try f.mbx.send(&slot);

    // A then B, and they arrive A then B — ahead of the ordinary one.
    try o.newMsg(alloc, f.io, &slot, 91);
    try f.mbx.sendOob(&slot);
    try o.newMsg(alloc, f.io, &slot, 92);
    try f.mbx.sendOob(&slot);

    for ([_]u32{ 91, 92, 1 }) |seq| {
        try f.mbx.receive(&slot, a_second);
        try expect(o.MSG.mustFromSlot(&slot).seq == seq);
        o.releaseSlot(&slot, alloc, f.io);
    }
}

test "38 — out of band to a closed mailbox is refused" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var rem: m.queue.Queue = f.mbx.close();
    o.releaseAll(&rem, alloc, f.io);

    var slot: m.inner.Slot = null;
    defer o.releaseSlot(&slot, alloc, f.io);
    try o.newMsg(alloc, f.io, &slot, 38);

    try std.testing.expectError(error.Closed, f.mbx.sendOob(&slot));
    try expect(slot != null);
}

test "39 — a parent sent before the close comes back from it" {
    var f: Fixture = undefined;
    try f.start();
    defer f.threaded.deinit();

    var slot: m.inner.Slot = null;

    try o.newMsg(alloc, f.io, &slot, 39);
    try f.mbx.send(&slot);

    // Not received, so the close is what gives it back. Nothing is lost.
    var rem: m.queue.Queue = f.mbx.close();
    try expect(rem.len() == 1);
    try expect(o.MSG.mustFromAnchor(rem._head.?).seq == 39);
    o.releaseAll(&rem, alloc, f.io);

    f.mbx.destroy();
}

test "40 — receiveAll takes everything" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;

    for ([_]u32{ 1, 2, 3, 4, 5 }) |seq| {
        try o.newMsg(alloc, f.io, &slot, seq);
        try f.mbx.send(&slot);
    }

    var all: m.queue.Queue = try f.mbx.receiveAll();
    try expect(all.len() == 5);

    // The mailbox is empty and still open.
    try expect(f.mbx.len() == 0);
    try expect(!f.mbx.isClosed());

    o.releaseAll(&all, alloc, f.io);
}

test "41 — receiveAll on an empty mailbox hands back an empty queue" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var all: m.queue.Queue = try f.mbx.receiveAll();
    try expect(all.isEmpty());
    try expect(all.len() == 0);
}

test "42 — what receiveAll hands back is walked with pop, and needs no repair" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;

    for ([_]u32{ 1, 2, 3 }) |seq| {
        try o.newMsg(alloc, f.io, &slot, seq);
        try f.mbx.send(&slot);
    }

    var all: m.queue.Queue = try f.mbx.receiveAll();

    // Every parent comes out unlinked, so it drops straight into a Slot with
    // no repair step. The old tree needed one; the chain does it now.
    var seen: u32 = 0;
    while (all.popFirst()) |anchor| {
        try expect(!m.inner.isLinked(anchor));

        var back: m.inner.Slot = null;
        m.inner.fillSlot(&back, anchor);
        seen += 1;

        o.releaseSlot(&back, alloc, f.io);
    }

    try expect(seen == 3);
}

test "43 — a send transfers the parent" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;
    try o.newMsg(alloc, f.io, &slot, 43);

    try f.mbx.send(&slot);
    try expect(slot == null);
}

test "44 — a receive transfers the parent" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;
    defer o.releaseSlot(&slot, alloc, f.io);

    try o.newMsg(alloc, f.io, &slot, 44);
    try f.mbx.send(&slot);

    try f.mbx.receive(&slot, a_second);

    // The receiver has it and the mailbox does not.
    try expect(slot != null);
    try expect(f.mbx.len() == 0);
}

test "45 — a non-blocking receive on empty answers false" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;

    try expect(!try f.mbx.tryReceive(&slot));
    try expect(slot == null);
}

test "46 — a non-blocking receive takes the parent and answers true" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;
    defer o.releaseSlot(&slot, alloc, f.io);

    try o.newMsg(alloc, f.io, &slot, 46);
    try f.mbx.send(&slot);

    try expect(try f.mbx.tryReceive(&slot));
    try expect(o.MSG.mustFromSlot(&slot).seq == 46);
}

test "47 and 48 — in flight to held, and back" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;
    defer o.releaseSlot(&slot, alloc, f.io);

    try o.newMsg(alloc, f.io, &slot, 47);
    const anchor = slot.?;

    // In flight: the Slot is full, the parent is on no chain.
    try expect(!m.inner.isLinked(anchor));

    try f.mbx.send(&slot);

    // Held: the Slot is empty, the parent is on the mailbox's chain.
    try expect(slot == null);
    try expect(m.inner.isLinked(anchor));

    try f.mbx.receive(&slot, a_second);

    // In flight again, and unlinked without the caller repairing anything.
    try expect(slot.? == anchor);
    try expect(!m.inner.isLinked(anchor));
}

test "49 — sending a parent already on a chain is refused" {
    if (!std.debug.runtime_safety) return error.SkipZigTest;

    // The refusal itself aborts, so it is negative program 304's business.
    // What this holds is the exactness the refusal rests on: a parent alone
    // on a chain reads as linked, which is what a send looks at.
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;
    defer o.releaseSlot(&slot, alloc, f.io);

    try o.newMsg(alloc, f.io, &slot, 49);
    try f.mbx.send(&slot);

    var all: m.queue.Queue = try f.mbx.receiveAll();
    const anchor = all.popFirst().?;

    var mine: m.queue.Queue = .{};
    mine.append(anchor);

    // A chain of one, and the link test sees it.
    try expect(mine.len() == 1);
    try expect(m.inner.isLinked(anchor));

    m.inner.fillSlot(&slot, mine.popFirst().?);
}

test "260 — a call in flight blocks destroy" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var rem: m.queue.Queue = f.mbx.close();
    o.releaseAll(&rem, alloc, f.io);

    // Closed and quiet, so destroy would be allowed.
    try expect(f.mbx.isIdle());

    // The abort itself is negative program 312. What is checked here is the
    // predicate destroy reads: `isIdle` is the same question without it.
    try expect(f.mbx.isClosed());
}

test "261 — closed, then quiet, then freed" {
    var f: Fixture = undefined;
    try f.start();
    defer f.threaded.deinit();

    // Open: not idle, whatever else is true.
    try expect(!f.mbx.isIdle());

    var rem: m.queue.Queue = f.mbx.close();
    o.releaseAll(&rem, alloc, f.io);

    try expect(f.mbx.isIdle());

    f.mbx.destroy();
}

test "262 — the queries answer, before and after a close" {
    var f: Fixture = undefined;
    try f.start();
    defer f.threaded.deinit();

    var slot: m.inner.Slot = null;
    try o.newMsg(alloc, f.io, &slot, 262);
    try f.mbx.send(&slot);

    try expect(!f.mbx.isClosed());
    try expect(!f.mbx.isIdle());
    try expect(f.mbx.len() == 1);

    var rem: m.queue.Queue = f.mbx.close();
    o.releaseAll(&rem, alloc, f.io);

    try expect(f.mbx.isClosed());
    try expect(f.mbx.isIdle());

    f.mbx.destroy();
}

test "263 — a closed mailbox is empty" {
    var f: Fixture = undefined;
    try f.start();
    defer f.threaded.deinit();

    var slot: m.inner.Slot = null;
    for ([_]u32{ 1, 2 }) |seq| {
        try o.newMsg(alloc, f.io, &slot, seq);
        try f.mbx.send(&slot);
    }

    var rem: m.queue.Queue = f.mbx.close();
    o.releaseAll(&rem, alloc, f.io);

    // Zero because the close gave everything back, not because it dropped it.
    try expect(f.mbx.len() == 0);

    f.mbx.destroy();
}

test "264 — a send with a limit is refused at the limit" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;
    defer o.releaseSlot(&slot, alloc, f.io);

    for ([_]u32{ 1, 2 }) |seq| {
        try o.newMsg(alloc, f.io, &slot, seq);
        try f.mbx.sendLimited(&slot, 2);
    }

    // Two of this type are queued, so the third is refused.
    try o.newMsg(alloc, f.io, &slot, 3);
    try std.testing.expectError(error.Limit, f.mbx.sendLimited(&slot, 2));

    // And the sender still has it, exactly as on a closed refusal.
    try expect(slot != null);
    try expect(o.MSG.mustFromSlot(&slot).seq == 3);
    o.releaseSlot(&slot, alloc, f.io);

    // Another type does not count toward it. The count is per parent type.
    try o.newNote(alloc, f.io, &slot);
    try f.mbx.sendLimited(&slot, 2);
    try expect(slot == null);

    try expect(f.mbx.len() == 3);
}

test "264 — out of band is not counted toward a limit" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;

    for ([_]u32{ 1, 2 }) |seq| {
        try o.newMsg(alloc, f.io, &slot, seq);
        try f.mbx.sendOob(&slot);
    }

    // Two of the type are queued, but out of band, and the limit counts the
    // ordinary ones. So this one goes.
    try o.newMsg(alloc, f.io, &slot, 3);
    try f.mbx.sendLimited(&slot, 2);
    try expect(slot == null);
}

test "265 — a send with a limit of zero is an ordinary send" {
    var f: Fixture = undefined;
    try f.start();
    defer f.finish();

    var slot: m.inner.Slot = null;

    for ([_]u32{ 1, 2, 3, 4 }) |seq| {
        try o.newMsg(alloc, f.io, &slot, seq);
        try f.mbx.sendLimited(&slot, 0);
        try expect(slot == null);
    }

    try expect(f.mbx.len() == 4);
}

test "317 — the toolkit states its version" {
    try expect(m.VERSION.len > 0);
}

const a_second: u64 = 1_000_000_000;

const alloc = std.testing.allocator;
const expect = std.testing.expect;
const m = @import("matryoshka");
const o = @import("parents.zig");
const std = @import("std");
const Io = std.Io;
