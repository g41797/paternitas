// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Request-response.
//!
//! - Main sends an Event (code=42) to the worker's request mailbox.
//! - Worker adds 1000 to the code, sends it to the response mailbox.
//! - Main receives the response, verifies the value.
//!
//!
//! ```
//!  main ──Event(code=42)──► req_mbx ──► worker
//!                                          │ code += 1000
//!                                          ▼
//!  main ◄──Event(code=1042)── resp_mbx ◄── worker
//! ```
//!

pub fn request_response(allocator: std.mem.Allocator, io: std.Io) !void {
    var req_mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &req_mbx_slot);
    const req_mbx: *Mbox = Mbox.moveFromSlot(&req_mbx_slot).?;
    defer req_mbx.destroy();

    var resp_mbx_slot: Slot = null;
    try matryoshka.mbox.new(allocator, io, &resp_mbx_slot);
    const resp_mbx: *Mbox = Mbox.moveFromSlot(&resp_mbx_slot).?;
    defer resp_mbx.destroy();

    var ctx: WorkerCtx = .{ .req_mbx = req_mbx, .resp_mbx = resp_mbx, .alloc = allocator, .io = io };
    var fut = try io.concurrent(workerFn, .{&ctx});

    {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        try parents.Event.EventHelper.create(allocator, io, &slot);
        parents.Event.EventHelper.mustFromSlot(&slot).code = 42;
        try req_mbx.send(&slot);
    }

    {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, allocator, io);
        try resp_mbx.receive(&slot, 5_000_000_000);
        const resp: *parents.Event = parents.Event.EventHelper.fromSlot(&slot) orelse return error.WrongTag;
        std.log.info("request_response: response code={d}", .{resp.*.code});
        try helpers.expect(error.RequestResponseFailed, resp.*.code == 1042, "wrong response code");
    }

    var rem_req: matryoshka.queue.Queue = req_mbx.close();
    parents.destroyQueue(&rem_req, allocator, io);
    fut.await(io);

    var rem_resp: matryoshka.queue.Queue = resp_mbx.close();
    parents.destroyQueue(&rem_resp, allocator, io);
}

const WorkerCtx = struct {
    req_mbx: *Mbox,
    resp_mbx: *Mbox,
    alloc: std.mem.Allocator,
    io: std.Io,
};

fn workerFn(ctx: *WorkerCtx) void {
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        ctx.req_mbx.receive(&slot, null) catch return;
        const ev: *parents.Event = parents.Event.EventHelper.fromSlot(&slot) orelse continue;
        std.log.debug("worker: request code={d}", .{ev.*.code});
        ev.*.code += 1000;
        ctx.resp_mbx.send(&slot) catch {};
    }
}

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const std = @import("std");
const Mbox = matryoshka.Mbox;
const Slot = matryoshka.inner.Slot;
