//! Test wrappers. Each one runs an example and checks it returned.

test "print_version" {
    std.testing.log_level = .debug;

    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();

    examples.print_version(std.testing.allocator, threaded.io()) catch |err| {
        std.log.err("print_version failed: {s}", .{@errorName(err)});
        return err;
    };
}

const examples = @import("examples");
const std = @import("std");
