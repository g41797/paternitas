// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! mustParentFromNode on an unstamped Parent panics in every build mode.

const Msg = struct { link: p.SLink = .{} };

pub fn main() void {
    var m: Msg = .{};
    _ = p.Info(Msg).mustParentFromNode(p.Info(Msg).node(&m));
}

const p = @import("paternitas");
