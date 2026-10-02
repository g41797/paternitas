//! Test wrappers for layer 4, part c: one per example, calling it and failing if it fails.

const allocator = std.testing.allocator;

test "53 - pool fan-in: many workers return" {
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    examples.layer4.c.pool_fan_in.pool_fan_in_many_workers_return(allocator, threaded.io()) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "54 - pool fan-out: many workers acquire" {
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    examples.layer4.c.pool_fan_out.pool_fan_out_many_workers_acquire(allocator, threaded.io()) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "55 - producer to consumer with recycling" {
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    examples.layer4.c.producer_consumer_recycle.producer_consumer_with_recycling(allocator, threaded.io()) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "57 - pool and future: simple worker" {
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    examples.layer4.c.mailbox_less_pool_future_worker.pool_future_simple_worker(allocator, threaded.io()) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "59 - pool and group: worker pool" {
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    examples.layer4.c.mailbox_less_pool_group_workers.pool_group_worker_pool(allocator, threaded.io()) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "63 - two Masters, two tables" {
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    examples.layer4.c.table_dispatch_masters.table_dispatch_two_masters(allocator, threaded.io()) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "95 - worker finish signal via mailbox return" {
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    examples.layer4.c.mailbox_as_item.worker_finish_signal_via_mailbox_return(allocator, threaded.io()) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "96 - pool holds pools at teardown" {
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    examples.layer4.c.pool_as_item.pool_holds_pools_at_teardown(allocator, threaded.io()) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "103 - infrastructure wrapper" {
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    examples.layer4.c.infra_wrapper.infra_wrapper(allocator, threaded.io()) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "056 - job pool circular" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.c.job_pool_circular.job_pool_circular_flow(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "058 - pool select scheduler" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.c.mailbox_less_pool_select_scheduler.pool_select_job_scheduler(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "060 - pool select network" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.c.mailbox_less_pool_select_network.pool_select_network(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "061 - when to add mailbox" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io: std.Io = threaded.io();
    examples.layer4.c.mailbox_less_to_mailbox_transition.when_to_add_mailbox(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

const examples = @import("examples");
const std = @import("std");
