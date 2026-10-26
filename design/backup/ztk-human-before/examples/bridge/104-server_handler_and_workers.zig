//! The bridge: requests from the io side, workers on the Matryoshka side.
//!
//! - The io side owns an `Io.Queue(Msg)` and puts requests into it.
//! - A handler waits on that queue and dispatches on the tag.
//! - A request becomes a greeting from the pool, sent to a shared mailbox.
//! - Workers receive from the mailbox and change the greeting.
//! - A worker takes the greeting's bare Anchor out of its Slot and puts it on the queue.
//! - The handler puts it back into a Slot, hands the text to the io side.
//! - The greeting goes back to the pool.
//! - Shutdown: `stop` ends the handler, then the mailbox closes and the workers leave.
//!
//!
//! ```
//!  io side ──request──► Io.Queue(Msg) ──► handler ──► pool.get, mbx.send
//!                            ▲                              │
//!                            │                              ▼
//!                       reply (*Anchor) ◄──  worker ◄── shared mailbox
//!
//!  handler ──reply──► answers (Io.Queue(Text)) ──► io side
//!  handler ──reply──► pool.put
//! ```
//!

pub fn greeting_bridge(allocator: std.mem.Allocator, io: std.Io) !void {
    var hooks_ctx: PoolHooks = .{ .alloc = allocator, .io = io };
    const ids = [_]TypeId{Greeting.GreetingHelper.ID};

    var pl_slot: Slot = null;
    try matryoshka.pool.new(allocator, io, &ids, hooks_ctx.poolHooks(), &pl_slot);
    const pl: *Pool = Pool.moveFromSlot(&pl_slot).?;
    defer {
        pl.close();
        pl.destroy();
    }

    var mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &mbx_slot);
    const mbx: *Mbox = Mbox.moveFromSlot(&mbx_slot).?;
    defer {
        var rem: Queue = mbx.close();
        Greeting.destroyQueue(&rem, allocator, io);
        mbx.destroy();
    }

    var msgs_buf: [8]Msg = undefined;
    var msgs: Io.Queue(Msg) = .init(&msgs_buf);
    var answers_buf: [8]Greeting.Text = undefined;
    var answers: Io.Queue(Greeting.Text) = .init(&answers_buf);

    var ctx: Ctx = .{ .alloc = allocator, .io = io, .pl = pl, .mbx = mbx, .msgs = &msgs, .answers = &answers };
    var group: Io.Group = .init;
    defer group.cancel(io);

    try spawnHandlerAndWorkers(&ctx, &group);
    try sendRequests(&ctx);
    try collectAnswers(&ctx);
    try shutdown(&ctx, &group);
}

/// What the handler waits for. Three kinds of thing arrive on one queue.
const Msg = union(enum) {
    /// From the io side. A plain value, no toolkit type.
    request: Greeting.Text,
    /// From the Matryoshka side. Any parent, whatever its type.
    reply: *Anchor,
    /// A control message.
    stop,
};

const request_count = 3;

const Ctx = struct {
    alloc: std.mem.Allocator,
    io: std.Io,
    pl: *Pool,
    mbx: *Mbox,
    msgs: *Io.Queue(Msg),
    answers: *Io.Queue(Greeting.Text),
};

fn spawnHandlerAndWorkers(ctx: *Ctx, group: *Io.Group) !void {
    try group.concurrent(ctx.io, handlerFn, .{ctx});
    try group.concurrent(ctx.io, workerFn, .{ctx});
    try group.concurrent(ctx.io, workerFn, .{ctx});
}

fn sendRequests(ctx: *Ctx) !void {
    for (0..request_count) |_| {
        try ctx.msgs.putOne(ctx.io, .{ .request = Greeting.Text.of("Hello, Matryoshka!") });
    }
}

fn collectAnswers(ctx: *Ctx) !void {
    for (0..request_count) |_| {
        const answer: Greeting.Text = try ctx.answers.getOne(ctx.io);
        std.log.info("io side received: {s}", .{answer.slice()});
        try helpers.expect(error.BridgeFailed, std.mem.eql(u8, answer.slice(), "Hello, Io"), "wrong answer");
    }
}

fn shutdown(ctx: *Ctx, group: *Io.Group) !void {
    try ctx.msgs.putOne(ctx.io, .stop);
    var rem: Queue = ctx.mbx.close();
    Greeting.destroyQueue(&rem, ctx.alloc, ctx.io);
    try group.await(ctx.io);
}

fn handlerFn(ctx: *Ctx) error{Canceled}!void {
    while (true) {
        const msg: Msg = ctx.msgs.getOne(ctx.io) catch |err| switch (err) {
            error.Canceled => return error.Canceled,
            error.Closed => return,
        };
        switch (msg) {
            .request => |text| forwardRequest(ctx, text),
            .reply => |any| takeReply(ctx, any),
            .stop => return,
        }
    }
}

fn forwardRequest(ctx: *Ctx, text: Greeting.Text) void {
    var slot: Slot = null;
    defer Greeting.GreetingHelper.destroy(ctx.alloc, ctx.io, &slot);
    ctx.pl.get(Greeting.GreetingHelper.ID, .new_only, &slot) catch |err| {
        std.log.err("handler: no greeting: {s}", .{@errorName(err)});
        return;
    };
    Greeting.GreetingHelper.mustFromSlot(&slot).text = text;
    ctx.mbx.send(&slot) catch |err| std.log.err("handler: not sent: {s}", .{@errorName(err)});
}

fn takeReply(ctx: *Ctx, reply: *Anchor) void {
    if (Greeting.GreetingHelper.fromAnchor(reply) == null) {
        std.log.err("handler: a reply of an unknown type", .{});
        return;
    }

    var slot: Slot = null;
    defer Greeting.GreetingHelper.destroy(ctx.alloc, ctx.io, &slot);
    matryoshka.inner.fillSlot(&slot, reply);
    const greeting: *Greeting = Greeting.GreetingHelper.mustFromSlot(&slot);
    ctx.answers.putOne(ctx.io, greeting.text) catch |err| std.log.err("handler: answer lost: {s}", .{@errorName(err)});
    ctx.pl.put(&slot) catch |err| std.log.err("handler: not returned: {s}", .{@errorName(err)});
}

fn workerFn(ctx: *Ctx) error{Canceled}!void {
    while (true) {
        var slot: Slot = null;
        defer Greeting.GreetingHelper.destroy(ctx.alloc, ctx.io, &slot);
        ctx.mbx.receive(&slot, null) catch |err| switch (err) {
            error.Canceled => return error.Canceled,
            error.Closed, error.Timeout, error.Wakeup => return,
        };
        Greeting.GreetingHelper.mustFromSlot(&slot).text = Greeting.Text.of("Hello, Io");

        const bare: *Anchor = matryoshka.inner.takeFromSlot(&slot);
        ctx.msgs.putOne(ctx.io, .{ .reply = bare }) catch |err| {
            matryoshka.inner.fillSlot(&slot, bare);
            return switch (err) {
                error.Canceled => error.Canceled,
                error.Closed => {},
            };
        };
    }
}

const PoolHooks = struct {
    alloc: std.mem.Allocator,
    io: std.Io,

    fn poolHooks(self: *PoolHooks) Pool.Hooks {
        return .{ .ctx = self, .on_get = onGet, .on_put = onPut, .on_close = onClose };
    }

    fn onGet(ptr: *anyopaque, _: TypeId, _: usize, slot: *Slot) void {
        const self: *PoolHooks = @ptrCast(@alignCast(ptr));
        Greeting.GreetingHelper.create(self.alloc, self.io, slot) catch return;
    }

    fn onPut(_: *anyopaque, _: usize, slot: *Slot, _: *Queue) void {
        if (Greeting.GreetingHelper.fromSlot(slot)) |greeting| greeting.text = .{};
    }

    fn onClose(ptr: *anyopaque, remaining: Queue) void {
        const self: *PoolHooks = @ptrCast(@alignCast(ptr));
        var rest: Queue = remaining;
        Greeting.destroyQueue(&rest, self.alloc, self.io);
    }
};

const Greeting = @import("Greeting.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Anchor = matryoshka.inner.Anchor;
const Io = std.Io;
const Mbox = matryoshka.Mbox;
const TypeId = matryoshka.inner.TypeId;
const Pool = matryoshka.Pool;
const Queue = matryoshka.queue.Queue;
const Slot = matryoshka.inner.Slot;
