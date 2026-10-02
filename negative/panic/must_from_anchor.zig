//! mustFromAnchor on another type panics in every build mode, naming both.

const Msg = struct { link: p.SLink = .{} };
const Job = struct { link: p.DLink = .{} };

pub fn main() void {
    var j: Job = .{};
    p.Typed(Job).stamp(&j);
    _ = p.Typed(Msg).mustFromAnchor(p.Typed(Job).anchor(&j));
}

const p = @import("paternitas");
