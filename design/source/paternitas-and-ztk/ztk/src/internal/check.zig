// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! What the toolkit refuses, stated once.
//!
//! - `check` panics where runtime safety is on.
//! - It is compiled out where runtime safety is off.
//! - So a broken contract is never an assumption the optimizer may act on.
//!
//! Internal. Not reachable from `@import("matryoshka")`.
//!
const _doc_stub = void;

/// Panics with `msg` when `ok` is false and runtime safety is on.
///
/// Compiled out of ReleaseFast and ReleaseSmall. There the body is dead at
/// comptime: no call, no branch, no message in the binary.
///
/// Why not `std.debug.assert`: it is `unreachable` in those two modes, so a
/// broken contract becomes undefined behaviour and the optimizer may reason
/// from it. This leaves nothing behind instead.
///
/// `ok` is evaluated by the caller in every mode. A condition that costs
/// something goes inside `if (std.debug.runtime_safety)`.
pub inline fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}

const std = @import("std");
