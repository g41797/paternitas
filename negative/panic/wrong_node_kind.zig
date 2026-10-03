//! TypeInfo.node with the wrong Node kind panics in every build mode.

const Msg = struct { tnode: p.SinglyTypedNode = .{} };

pub fn main() void {
    var m: Msg = .{};
    p.Typed(Msg).setTypeId(&m);
    const a = p.Typed(Msg).anchor(&m);
    _ = a.info().?.node(a, std.DoublyLinkedList.Node);
}

const p = @import("paternitas");
const std = @import("std");
