//! TypeInfo.node with the wrong Node kind panics in every build mode.

const Msg = struct { link: p.SLink = .{} };

pub fn main() void {
    var m: Msg = .{};
    p.Typed(Msg).stamp(&m);
    const a = p.Typed(Msg).anchor(&m);
    _ = a.info().?.node(a, std.DoublyLinkedList.Node);
}

const p = @import("paternitas");
const std = @import("std");
