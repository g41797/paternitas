// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! 306 — a parent with no SinglyTypedNode or DoublyTypedNode field does not compile.

const NoInner = struct {
    seq: u32 = 0,
};

comptime {
    _ = m.helper.ParentHelper(NoInner).ID;
}

const m = @import("matryoshka");
