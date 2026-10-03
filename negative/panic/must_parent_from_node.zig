//! mustParentFromNode panics in every build mode when setTypeId was never
//! called on the Parent.

const Msg = struct { tnode: p.SinglyTypedNode = .{} };

pub fn main() void {
    var m: Msg = .{};
    _ = p.Typed(Msg).mustParentFromNode(p.Typed(Msg).node(&m));
}

const p = @import("paternitas");
