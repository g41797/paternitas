// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 307 — a parent with two TypedNode fields does not compile.

const TwoInners = struct {
    first: m.inner.SinglyTypedNode = .{},
    second: m.inner.SinglyTypedNode = .{},
};

comptime {
    _ = m.helper.ParentHelper(TwoInners).ID;
}

const m = @import("matryoshka");
