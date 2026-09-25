//! Tests of the paternitas module.

test "the module imports and names a version" {
    std.testing.log_level = .debug;

    try testing.expect(paternitas.VERSION.len > 0);
}

const paternitas = @import("paternitas");
const std = @import("std");
const testing = std.testing;
