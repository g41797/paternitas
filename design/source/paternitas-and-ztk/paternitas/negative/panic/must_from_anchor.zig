// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! mustFromAnchor on another type panics in every build mode, naming both.

const Msg = struct { link: p.SLink = .{} };
const Job = struct { link: p.DLink = .{} };

pub fn main() void {
    var j: Job = .{};
    p.Info(Job).stamp(&j);
    _ = p.Info(Msg).mustFromAnchor(p.Info(Job).anchor(&j));
}

const p = @import("paternitas");
