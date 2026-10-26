// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! What the toolkit refuses, in one place.
//!
//! - `check` panics where runtime safety is on.
//! - It is compiled out where runtime safety is off.
//! - A broken contract never becomes something the optimizer may assume.
//!
//! Internal. `@import("matryoshka")` does not reach it.
//!
const _doc_stub = void;

/// Panics with `msg` when `ok` is false and runtime safety is on.
///
/// ReleaseFast and ReleaseSmall compile it out. No call, no branch and no
/// message stay in the binary.
///
/// It is not `std.debug.assert`. In those two modes `assert` is
/// `unreachable`. A broken contract then becomes undefined behaviour, and the
/// optimizer may build on it. `check` leaves nothing behind.
///
/// The caller evaluates `ok` in every mode. Put a costly condition inside
/// `if (std.debug.runtime_safety)`.
pub inline fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}

const std = @import("std");
