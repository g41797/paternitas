//! A bare std Node is not a TypedNode. A Parent without a TypedNode does not
//! compile.

const BareNode = struct {
    node: std.DoublyLinkedList.Node = .{},
};

comptime {
    _ = p.Typed(BareNode).typeId();
}

const p = @import("paternitas");
const std = @import("std");
