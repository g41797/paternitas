// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! A Parent must be a struct.

comptime {
    _ = p.Info(u32).typeId();
}

const p = @import("paternitas");
