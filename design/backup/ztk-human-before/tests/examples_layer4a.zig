//! Test wrappers for the layer 4a examples: one per example.

const allocator = std.testing.allocator;
test "017 - minimal master" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.minimal_master.minimal_master(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "018 - master with pool" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.master_with_pool.master_with_pool(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "019 - multi worker master" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.multi_worker_master.multi_worker_master(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "020 - pipeline masters" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.pipeline_masters.pipeline_of_masters(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "021 - request response" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.request_response.request_response_between_masters(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "022 - timer via mailbox" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.timer_via_mailbox.timer_via_mailbox(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "023 - oob signal" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.oob_signal.oob_via_send_oob(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "024 - multi source mailbox" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.multi_source_mailbox.multiple_event_sources_one_mailbox(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "025 - select two mailboxes" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.select_two_mailboxes.two_mailboxes_timer_in_select(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "026 - select cancel close" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.select_cancel_close.timer_cancel_close_walk_remaining(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "027 - select cancel master decides" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.select_cancel_master_decides.cancel_reports_master_decides(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "030 - mailbox timeout" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.mailbox_timeout.timeout_on_mailbox(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "032 - cross layer pool mailbox roundtrip" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.cross_layer_pool_mailbox_roundtrip.pool_mailbox_pool_roundtrip(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "033 - cross layer mixed types mailbox" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.cross_layer_mixed_types_mailbox.mixed_types_through_shared_mailbox(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "028 - select mixed sources" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.select_mixed_sources.multiple_event_source_types_in_one_select(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "031 - select graceful shutdown" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.a.select_graceful_shutdown.graceful_shutdown_with_in_flight_items(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

const examples = @import("examples");
const std = @import("std");
