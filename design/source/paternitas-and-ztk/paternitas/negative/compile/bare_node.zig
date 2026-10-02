// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! A bare std Node is not a Link. A Parent without a Link does not compile.

const Bad = struct {
    node: std.DoublyLinkedList.Node = .{},
};

comptime {
    _ = p.Info(Bad).typeId();
}

const p = @import("paternitas");
const std = @import("std");
