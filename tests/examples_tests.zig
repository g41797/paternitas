//! Test wrappers. Each one runs an example and checks it returned.

test "01 - stamp and recover" {
    std.testing.log_level = .debug;

    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();

    examples.stamp_and_recover.stamp_and_recover(std.testing.allocator, threaded.io()) catch |err| {
        std.log.err("stamp_and_recover failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "02 - mixed list" {
    std.testing.log_level = .debug;

    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();

    examples.mixed_list.mixed_list(std.testing.allocator, threaded.io()) catch |err| {
        std.log.err("mixed_list failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "03 - timeout list" {
    std.testing.log_level = .debug;

    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();

    examples.timeout_list.timeout_list(std.testing.allocator, threaded.io()) catch |err| {
        std.log.err("timeout_list failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "04 - handler map" {
    std.testing.log_level = .debug;

    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();

    examples.handler_map.handler_map(std.testing.allocator, threaded.io()) catch |err| {
        std.log.err("handler_map failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "05 - anchor in union" {
    std.testing.log_level = .debug;

    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();

    examples.anchor_in_union.anchor_in_union(std.testing.allocator, threaded.io()) catch |err| {
        std.log.err("anchor_in_union failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "06 - anchor chain" {
    std.testing.log_level = .debug;

    var threaded: std.Io.Threaded = .init(std.testing.allocator, .{});
    defer threaded.deinit();

    examples.anchor_chain.anchor_chain(std.testing.allocator, threaded.io()) catch |err| {
        std.log.err("anchor_chain failed: {s}", .{@errorName(err)});
        return err;
    };
}

const examples = @import("examples");
const std = @import("std");
