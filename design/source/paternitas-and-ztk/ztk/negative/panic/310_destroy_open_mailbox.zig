// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 310 — destroying an open mailbox is refused.
//!
//! In all four modes. `Mbox.destroy` does not use `check`: freeing a mailbox
//! that is still open is not a contract a fast build may assume away, and
//! the process that got it wrong is the one that must not continue.
//!
//! The mailbox here is empty, so nothing is leaked by the abort. What is
//! refused is the open state itself, not the items — `close` is what hands
//! those back, and skipping it is exactly the mistake.

pub fn main() void {
    var threaded: std.Io.Threaded = std.Io.Threaded.init(std.heap.page_allocator, .{});
    const io: std.Io = threaded.io();

    var slot: m.inner.Slot = null;
    m.mbox.new(std.heap.page_allocator, io, &slot) catch @panic("310: the mailbox was not made");

    const mbx: *m.Mbox = m.Mbox.moveFromSlot(&slot).?;

    // Never closed. The next line aborts.
    mbx.destroy();
}

const m = @import("matryoshka");
const std = @import("std");
