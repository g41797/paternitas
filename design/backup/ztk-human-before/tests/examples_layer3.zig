//! Test wrappers: one per example, calling it and failing if it fails.

const allocator = std.testing.allocator;

test "89 - basic recycler" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();
    examples.layer3.basic_recycler.basic_recycler(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "90 - backpressure pool" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();
    examples.layer3.capped_pool.backpressure_pool(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "91 - pool seeding" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();
    examples.layer3.pool_seeding.pool_seeding(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "92 - pool teardown" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();
    examples.layer3.pool_teardown.pool_teardown(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "101 - refused put" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();
    examples.layer3.refused_put.refused_put(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "102 - composite gives its parts back" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();
    examples.layer3.composite_parts.composite_parts(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

const examples = @import("examples");
const std = @import("std");
