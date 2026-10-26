// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! The one root of the test build. Every test file is imported from here.

test "the module builds and imports" {
    // The setup stage's whole claim: the build graph holds together from the
    // module root to a test binary, in all four optimization modes.
    try std.testing.expect(@TypeOf(matryoshka) == type);
}

comptime {
    _ = @import("layer1_id.zig");
    _ = @import("layer1_queue.zig");
    _ = @import("layer1_helper.zig");
    _ = @import("layer1_any.zig");
    _ = @import("layer2_mbox.zig");
    _ = @import("layer2_threads.zig");
    _ = @import("layer3_pool.zig");
    _ = @import("layer3_threads.zig");
    _ = @import("layer4_pool_futures.zig");
    _ = @import("examples_layer1.zig");
    _ = @import("examples_layer2.zig");
    _ = @import("examples_layer3.zig");
    _ = @import("examples_layer4a.zig");
    _ = @import("examples_layer4b.zig");
    _ = @import("examples_layer4c.zig");
    _ = @import("examples_bridge.zig");
}

const matryoshka = @import("matryoshka");
const std = @import("std");
