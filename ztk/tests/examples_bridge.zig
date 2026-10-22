//! Test wrappers for the bridge examples: one per example, calling it and failing if it fails.

const allocator = std.testing.allocator;

test "104 - server handler and workers" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    examples.bridge.server_handler_and_workers.greeting_bridge(allocator, threaded.io()) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

const examples = @import("examples");
const std = @import("std");
