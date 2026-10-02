// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 314 — a bare std Node is not a Link. A parent with one and no Link does
//! not compile.

const BareNode = struct {
    node: std.DoublyLinkedList.Node = .{},
    seq: u32 = 0,
};

comptime {
    _ = m.helper.ParentHelper(BareNode).ID;
}

const m = @import("matryoshka");
const std = @import("std");
