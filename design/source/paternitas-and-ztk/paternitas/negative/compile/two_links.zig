// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Two Links in one Parent do not compile.

const Two = struct {
    a: p.SLink = .{},
    b: p.DLink = .{},
};

comptime {
    _ = p.Info(Two).typeId();
}

const p = @import("paternitas");
