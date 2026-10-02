// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Layer 3 — the pool.
//!
//! Scenarios 63 to 80, 85 to 88, and 280, 281, 284 to 287, 289, 291. The
//! ones that need a second context — 81, 82, 83, 84, 282, 283, 288, 290 —
//! are in `layer3_threads.zig`.
//!
//! Every parent here is allocated. What the pool hands back has to be a
//! pointer the allocator gave out.

/// One pool, its hooks, its `Io`, and the teardown, in one place.
///
/// The order matters and is the mailbox's: close first — the close hook
/// releases what was still stored — then destroy, and only then the `Io`
/// the pool was using.
const Fixture = struct {
    threaded: std.Io.Threaded,
    io: Io = undefined,
    rec: h.Recorder = undefined,
    pool: *m.Pool = undefined,

    /// The identities every test uses unless it says otherwise.
    const both: [2]m.inner.TypeId = .{ o.MSG.ID, o.NOTE.ID };

    fn start(self: *Fixture, ids: []const m.inner.TypeId) !void {
        self.threaded = std.Io.Threaded.init(alloc, .{});
        self.io = self.threaded.io();
        self.rec = .{ .alloc = alloc, .io = self.io };

        var slot: m.inner.Slot = null;
        try m.pool.new(alloc, self.io, ids, self.rec.hooks(), &slot);
        self.pool = m.Pool.moveFromSlot(&slot).?;
    }

    fn finish(self: *Fixture) void {
        self.pool.close();
        self.pool.destroy();
        self.threaded.deinit();
    }

    /// Takes one parent out of the pool, whatever it costs to get it.
    fn take(self: *Fixture, want: m.inner.TypeId, slot: *m.inner.Slot) !void {
        try self.pool.get(want, .available_or_new, slot);
    }
};

test "63 — a pool is made, detached, closed and destroyed" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    // The identities are their own argument now, not a field of the hooks.
    // And a pool is a parent like any other: it has an id and it crosses.
    try expect(m.Pool.isIt(m.Pool.toAnchor(f.pool).type_id));
    try expect(m.Pool.fromAnchor(m.Pool.toAnchor(f.pool)).? == f.pool);

    try expect(!f.pool.isClosed());
    try expectEqual(@as(usize, 0), try f.pool.countOf(o.MSG.ID));
}

test "64 and 280 — the get hook is reached with an empty Slot and makes one" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var slot: m.inner.Slot = null;
    try f.take(o.MSG.ID, &slot);
    defer o.releaseSlot(&slot, alloc, f.io);

    try expect(slot != null);
    try expectEqual(@as(usize, 1), f.rec.gets);
    try expectEqual(@as(usize, 1), f.rec.made);

    // Nothing was stored, so the count the hook was told is zero.
    try expectEqual(@as(usize, 0), f.rec.last_get_in_pool);
    try expect(f.rec.get_slot_always_empty);
}

test "65 and 280 — a stored parent is reused, and the get hook is not reached" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var slot: m.inner.Slot = null;
    try f.take(o.MSG.ID, &slot);

    const first = slot.?;
    try f.pool.put(&slot);
    try expect(slot == null);

    try f.take(o.MSG.ID, &slot);
    defer o.releaseSlot(&slot, alloc, f.io);

    // The same parent, and the hook was called once in the whole test.
    try expect(slot.? == first);
    try expectEqual(@as(usize, 1), f.rec.gets);
    try expect(f.rec.get_slot_always_empty);
}

test "67 and 80 — the put hook is told the count before the addition" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var one: m.inner.Slot = null;
    var two: m.inner.Slot = null;
    try f.take(o.MSG.ID, &one);
    try f.take(o.MSG.ID, &two);

    try f.pool.put(&one);
    try expectEqual(@as(usize, 1), f.rec.puts);
    try expectEqual(@as(usize, 0), f.rec.last_put_in_pool);

    try f.pool.put(&two);
    try expectEqual(@as(usize, 2), f.rec.puts);
    try expectEqual(@as(usize, 1), f.rec.last_put_in_pool);

    try expectEqual(@as(usize, 2), try f.pool.countOf(o.MSG.ID));

    // And the get hook reads it from the other side: one is taken, one is
    // left, so a hook reached after that would be told one.
    var out: m.inner.Slot = null;
    try f.take(o.MSG.ID, &out);
    try f.pool.put(&out);
}

test "68 and 87 — the put hook may release the parent" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    f.rec.policy = .release;

    var slot: m.inner.Slot = null;
    try f.take(o.MSG.ID, &slot);

    try f.pool.put(&slot);

    // The Slot is empty whatever the hook decided, and nothing is stored.
    try expect(slot == null);
    try expectEqual(@as(usize, 1), f.rec.released);
    try expectEqual(@as(usize, 0), try f.pool.countOf(o.MSG.ID));
}

test "69, 86 and 88 — the put hook may keep the parent" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var slot: m.inner.Slot = null;
    try f.take(o.MSG.ID, &slot);

    const anchor = slot.?;
    try f.pool.put(&slot);

    try expect(slot == null);
    try expectEqual(@as(usize, 1), try f.pool.countOf(o.MSG.ID));

    // 88: it is on the pool's own chain now, so a caller who kept the
    // pointer and put it a second time is refused by the insert guard
    // rather than storing it twice.
    try expect(m.inner.isLinked(anchor));
}

test "70 — new-only always reaches the get hook" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var stored: m.inner.Slot = null;
    try f.take(o.MSG.ID, &stored);
    try f.pool.put(&stored);
    try expectEqual(@as(usize, 1), try f.pool.countOf(o.MSG.ID));

    var fresh: m.inner.Slot = null;
    try f.pool.get(o.MSG.ID, .new_only, &fresh);
    defer o.releaseSlot(&fresh, alloc, f.io);

    // The stored one was left alone, and the hook was reached with an empty
    // Slot even though one was there.
    try expectEqual(@as(usize, 1), try f.pool.countOf(o.MSG.ID));
    try expectEqual(@as(usize, 2), f.rec.gets);
    try expect(f.rec.get_slot_always_empty);
}

test "71 — available-only on an empty pool is refused" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var slot: m.inner.Slot = null;
    try expectError(error.NotAvailable, f.pool.get(o.MSG.ID, .available_only, &slot));

    // The Slot is empty on every failure, and the hook was never reached.
    try expect(slot == null);
    try expectEqual(@as(usize, 0), f.rec.gets);
}

test "72 — available-only takes a stored parent" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var slot: m.inner.Slot = null;
    try f.take(o.MSG.ID, &slot);
    const first = slot.?;
    try f.pool.put(&slot);

    try f.pool.get(o.MSG.ID, .available_only, &slot);
    defer o.releaseSlot(&slot, alloc, f.io);

    try expect(slot.? == first);
    try expectEqual(@as(usize, 1), f.rec.gets);
}

test "73 — one store per identity" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var msg: m.inner.Slot = null;
    try f.take(o.MSG.ID, &msg);
    try f.pool.put(&msg);

    // A note is asked for, and the stored message is not what comes back.
    var note: m.inner.Slot = null;
    try f.take(o.NOTE.ID, &note);
    defer o.releaseSlot(&note, alloc, f.io);

    try expect(o.NOTE.fromSlot(&note) != null);
    try expectEqual(@as(usize, 1), try f.pool.countOf(o.MSG.ID));
    try expectEqual(@as(usize, 0), try f.pool.countOf(o.NOTE.ID));
}

test "74 and 284 — close hands every stored parent to the close hook" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var msg: m.inner.Slot = null;
    var note: m.inner.Slot = null;
    try f.take(o.MSG.ID, &msg);
    try f.take(o.NOTE.ID, &note);
    try f.pool.put(&msg);
    try f.pool.put(&note);

    f.pool.close();

    // Flattened across both identities, by value. The queue the hook was
    // handed is the only way to those parents, and the pool kept nothing:
    // 284 is that the hook's copy is the whole of it.
    try expectEqual(@as(usize, 1), f.rec.close_calls);
    try expectEqual(@as(usize, 2), f.rec.closed_items);
    try expect(f.pool.isClosed());
}

test "75 — close is repeatable" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var slot: m.inner.Slot = null;
    try f.take(o.MSG.ID, &slot);
    try f.pool.put(&slot);

    f.pool.close();
    f.pool.close();
    f.pool.close();

    // The hook is called by the close that did the work, and by no other.
    try expectEqual(@as(usize, 1), f.rec.close_calls);
    try expectEqual(@as(usize, 1), f.rec.closed_items);
}

test "76 — get on a closed pool is refused" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    f.pool.close();

    var slot: m.inner.Slot = null;
    try expectError(error.Closed, f.pool.get(o.MSG.ID, .available_or_new, &slot));
    try expectError(error.Closed, f.pool.get(o.MSG.ID, .new_only, &slot));
    try expectError(error.Closed, f.pool.get(o.MSG.ID, .available_only, &slot));
    try expectError(error.Closed, f.pool.getWait(o.MSG.ID, &slot, 0));

    try expect(slot == null);
    try expectEqual(@as(usize, 0), f.rec.gets);
}

test "77 — put on a closed pool leaves the parent with the caller" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var slot: m.inner.Slot = null;
    try f.take(o.MSG.ID, &slot);

    f.pool.close();

    // Silent, and the Slot is untouched. A closed pool is a race the caller
    // cannot avoid, so it is not reported — the Slot is where you look.
    try f.pool.put(&slot);

    try expect(slot != null);
    try expectEqual(@as(usize, 0), f.rec.puts);

    o.releaseSlot(&slot, alloc, f.io);
}

test "78 — a capped pool releases above the threshold" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    f.rec.policy = .cap;
    f.rec.cap = 2;

    // Four out, four back. The put hook reads the stored count, because the
    // get hook is no longer reached on a reuse and could not do this.
    var slots: [4]m.inner.Slot = @splat(null);
    for (&slots) |*s| try f.take(o.MSG.ID, s);
    for (&slots) |*s| try f.pool.put(s);

    try expectEqual(@as(usize, 2), try f.pool.countOf(o.MSG.ID));
    try expectEqual(@as(usize, 2), f.rec.released);
}

test "79 — seeding with new-only" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var slots: [5]m.inner.Slot = @splat(null);
    for (&slots) |*s| try f.pool.get(o.MSG.ID, .new_only, s);
    for (&slots) |*s| try f.pool.put(s);

    try expectEqual(@as(usize, 5), try f.pool.countOf(o.MSG.ID));
    try expectEqual(@as(usize, 5), f.rec.made);

    // And from there, five gets reach no hook at all.
    for (&slots) |*s| try f.pool.get(o.MSG.ID, .available_only, s);
    for (&slots) |*s| try f.pool.put(s);

    try expectEqual(@as(usize, 5), f.rec.gets);
}

test "85 — held becomes in flight" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var slot: m.inner.Slot = null;
    try f.take(o.MSG.ID, &slot);
    try f.pool.put(&slot);

    try f.take(o.MSG.ID, &slot);
    defer o.releaseSlot(&slot, alloc, f.io);

    // Off the pool's chain, in the caller's Slot, and the count says so.
    try expect(!m.inner.isLinked(slot.?));
    try expectEqual(@as(usize, 0), try f.pool.countOf(o.MSG.ID));
}

test "281 — the waiting get never creates" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var slot: m.inner.Slot = null;
    try expectError(error.Timeout, f.pool.getWait(o.MSG.ID, &slot, 0));

    try expect(slot == null);
    try expectEqual(@as(usize, 0), f.rec.gets);
}

test "285 — an unknown identity is refused by every call" {
    // The error return is the whole surface's answer, in every build.
    var f: Fixture = undefined;
    try f.start(&.{o.MSG.ID});
    defer f.finish();

    var slot: m.inner.Slot = null;

    try expectError(error.UnknownIdentity, f.pool.get(o.NOTE.ID, .available_or_new, &slot));
    try expectError(error.UnknownIdentity, f.pool.get(o.NOTE.ID, .new_only, &slot));
    try expectError(error.UnknownIdentity, f.pool.getWait(o.NOTE.ID, &slot, 0));
    try expectError(error.UnknownIdentity, f.pool.countOf(o.NOTE.ID));

    // The get hook was never reached with an identity the pool never knew,
    // and the waiting get did not sit out its timeout.
    try expectEqual(@as(usize, 0), f.rec.gets);

    try o.newNote(alloc, f.io, &slot);
    try expectError(error.UnknownIdentity, f.pool.put(&slot));

    // Refused, so the parent is still the caller's.
    try expect(slot != null);
    o.releaseSlot(&slot, alloc, f.io);
}

test "287 — the queries answer" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    try expect(!f.pool.isClosed());
    try expect(!f.pool.isIdle());
    try expectEqual(@as(usize, 0), try f.pool.countOf(o.NOTE.ID));

    var slot: m.inner.Slot = null;
    try f.take(o.MSG.ID, &slot);
    try f.pool.put(&slot);
    try expectEqual(@as(usize, 1), try f.pool.countOf(o.MSG.ID));

    f.pool.close();

    // Closed, and no call is inside it, so freeing is allowed — which is
    // the question `isIdle` exists to answer without the abort.
    try expect(f.pool.isClosed());
    try expect(f.pool.isIdle());
}

test "289 — reuse is last in, first out" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    var first: m.inner.Slot = null;
    var second: m.inner.Slot = null;
    try f.take(o.MSG.ID, &first);
    try f.take(o.MSG.ID, &second);

    const last_in = second.?;

    try f.pool.put(&first);
    try f.pool.put(&second);

    var out: m.inner.Slot = null;
    try f.pool.get(o.MSG.ID, .available_only, &out);
    defer o.releaseSlot(&out, alloc, f.io);

    // The one that came back most recently goes out next, so a parent that
    // went stale while nothing was happening meets its next owner at once.
    try expect(out.? == last_in);
}

test "291 — the put hook's extra queue is taken" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    // A composite parent gives its two parts back with itself.
    f.rec.parts = 2;

    var slot: m.inner.Slot = null;
    try f.take(o.MSG.ID, &slot);
    try f.pool.put(&slot);

    // The parent in the Slot and both parts are stored the same way, with
    // the same checks.
    try expectEqual(@as(usize, 3), try f.pool.countOf(o.MSG.ID));
}

test "the get hook may decline to make one" {
    var f: Fixture = undefined;
    try f.start(&Fixture.both);
    defer f.finish();

    f.rec.makes = false;

    var slot: m.inner.Slot = null;
    try expectError(error.NotCreated, f.pool.get(o.MSG.ID, .available_or_new, &slot));

    // An empty Slot on the way out of the hook is the hook's own answer,
    // reported as an error rather than as a Slot the caller must inspect.
    try expect(slot == null);
    try expectEqual(@as(usize, 1), f.rec.gets);
}

const alloc = std.testing.allocator;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;
const h = @import("hooks.zig");
const m = @import("matryoshka");
const o = @import("parents.zig");
const Io = std.Io;
const std = @import("std");
