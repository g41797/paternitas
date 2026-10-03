//! The std doubly Node, passed where a SinglyTypedNode Parent expects the std
//! singly Node, does not compile.

const Msg = struct {
    tnode: p.SinglyTypedNode = .{},
};

export fn run() bool {
    var n: std.DoublyLinkedList.Node = .{};
    return p.Typed(Msg).is(&n);
}

const p = @import("paternitas");
const std = @import("std");
