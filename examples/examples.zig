//! Print the package version.
//!
//! - read the version from the module
//! - check it is not empty
//! - log it

pub fn print_version(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = allocator;
    _ = io;

    const version: []const u8 = paternitas.VERSION;

    if (version.len == 0) return error.PrintVersionFailed;

    std.log.info("paternitas {s}", .{version});
}

const paternitas = @import("paternitas");
const std = @import("std");
