//! Test wrappers: one per example, calling it and failing if it fails.

const allocator = std.testing.allocator;
const io = std.Io.Threaded.global_single_threaded.*.io();

test "21 - define a parent type" {
    std.testing.log_level = .debug;
    examples.layer1.define_type.define_a_parent_type(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "22 - parent transfer via Slot" {
    std.testing.log_level = .debug;
    examples.layer1.ownership_transfer.parent_transfer_via_slot(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "23 - id-dispatch consume loop" {
    std.testing.log_level = .debug;
    examples.layer1.tag_dispatch.id_dispatch_consume_loop(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "24 - builder pattern" {
    std.testing.log_level = .debug;
    examples.layer1.builder.builder_pattern(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "25 - produce-consume with defer cleanup" {
    std.testing.log_level = .debug;
    examples.layer1.produce_consume.produce_consume_with_defer_cleanup(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "26 - id-first dispatch" {
    std.testing.log_level = .debug;
    examples.layer1.tag_first_dispatch.id_first_dispatch_loop(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "27 - table dispatch" {
    std.testing.log_level = .debug;
    examples.layer1.table_dispatch.table_dispatch_loop(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "98 - border pair" {
    std.testing.log_level = .debug;
    examples.layer1.border_pair.border_pair(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

const examples = @import("examples");
const std = @import("std");
