//! mustFromAnchor on another type panics in every build mode, naming both.

const Msg = struct { tnode: p.SinglyTypedNode = .{} };
const Job = struct { tnode: p.DoublyTypedNode = .{} };

pub fn main() void {
    var j: Job = .{};
    p.Typed(Job).setTypeId(&j);
    _ = p.Typed(Msg).mustFromAnchor(p.Typed(Job).anchor(&j));
}

const p = @import("paternitas");
