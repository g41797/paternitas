// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 307 — a parent with two Link fields does not compile.

const TwoInners = struct {
    first: m.inner.SLink = .{},
    second: m.inner.SLink = .{},
};

comptime {
    _ = m.helper.ParentHelper(TwoInners).ID;
}

const m = @import("matryoshka");
