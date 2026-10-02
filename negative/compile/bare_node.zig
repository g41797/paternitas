//! A bare std Node is not a Link. A Parent without a Link does not compile.

const BareNode = struct {
    node: std.DoublyLinkedList.Node = .{},
};

comptime {
    _ = p.Info(BareNode).typeId();
}

const p = @import("paternitas");
const std = @import("std");
