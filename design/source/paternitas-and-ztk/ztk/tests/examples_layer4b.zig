//! Test wrappers: one per example, calling it and failing if it fails.

const allocator = std.testing.allocator;
const single_io = std.Io.Threaded.global_single_threaded.*.io();

test "32 - Pool → Mailbox → Pool roundtrip" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.cross_layer_pool_mailbox_roundtrip.pool_mailbox_pool_roundtrip(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "33 - mixed types through a shared mailbox" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.cross_layer_mixed_types_mailbox.mixed_types_through_shared_mailbox(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "35 - pool hooks + mailbox flow" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.cross_layer_pool_hooks_mailbox_flow.pool_hooks_mailbox_flow(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "36 - close ordering, pool then mailbox" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.cross_layer_close_pool_then_mailbox.close_ordering_pool_then_mailbox(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "37 - close ordering, mailbox then pool" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.cross_layer_close_mailbox_then_pool.close_ordering_mailbox_then_pool(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "38 - pool + mailbox flow" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.cross_layer_pool_mailbox_flow.pool_mailbox_flow(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "41 - master pre-shutdown collect" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.master_multi_mailbox_collect.master_pre_shutdown_collect(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "42 - mailbox receive as Select event source" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.select_mailbox_event.mailbox_receive_as_select_event_source(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "43 - Select direct queue push" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.select_direct_push.select_direct_queue_push(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "44 - Select mailbox close propagation" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.select_mailbox_close.select_mailbox_close_propagation(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "45 - Select cancel propagation" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.select_mailbox_cancel.select_cancel_propagation(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "49 - receive future awaited directly" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.receive_future_direct.receive_future_awaited_directly(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "51 - receive future with timeout" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.receive_future_timeout.receive_future_with_timeout(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "52 - ConcurrencyUnavailable on single-threaded" {
    std.testing.log_level = .debug;
    examples.layer4.b.future_single_threaded.concurrencyunavailable_on_single_threaded(allocator, single_io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "046 - select pool event" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.select_pool_event.pool_get_wait_as_select_event_source(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "047 - select job pool" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.select_job_pool.job_pool_pattern(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "048 - select mailbox pool timer" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.select_mailbox_pool_timer.mixed_mailbox_pool_event_sources_in_select(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "050 - get wait future direct" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.b.get_wait_future_direct.get_wait_future_awaited_directly(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

const examples = @import("examples");
const std = @import("std");
