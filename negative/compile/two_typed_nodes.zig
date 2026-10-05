//! Two TypedNodes in one struct do not compile.

const TwoTypedNodes = struct {
    a: p.SinglyTypedNode = .{},
    b: p.DoublyTypedNode = .{},
};

comptime {
    _ = p.Typed(TwoTypedNodes).typeId();
}

const p = @import("paternitas");
