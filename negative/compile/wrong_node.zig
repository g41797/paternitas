//! A DNode passed where an SLink Parent expects an SNode does not compile.

const Msg = struct {
    link: p.SLink = .{},
};

export fn run() bool {
    var n: std.DoublyLinkedList.Node = .{};
    return p.Typed(Msg).is(&n);
}

const p = @import("paternitas");
const std = @import("std");
