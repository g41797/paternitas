//! A bare std Node is not a TypedNode. A struct without a TypedNode gets only
//! the id calls. A list call does not compile.

const BareNode = struct {
    node: std.DoublyLinkedList.Node = .{},
};

export fn listCall() void {
    var b: BareNode = .{};
    _ = p.Typed(BareNode).node(&b);
}

const p = @import("paternitas");
const std = @import("std");
