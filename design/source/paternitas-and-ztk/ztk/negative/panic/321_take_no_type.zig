// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 321 — taking a parent whose setTypeId was never called out of a
//! Slot is refused.

const Msg = struct {
    seq: u32 = 0,
    hdr: m.inner.SinglyTypedNode = .{},
};

pub fn main() void {
    var msg: Msg = .{};

    var slot: m.inner.Slot = &msg.hdr.anchor;
    _ = m.inner.takeFromSlot(&slot);
}

const m = @import("matryoshka");
