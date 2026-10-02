//! mustParentFromNode on an unstamped Parent panics in every build mode.

const Msg = struct { link: p.SLink = .{} };

pub fn main() void {
    var m: Msg = .{};
    _ = p.Info(Msg).mustParentFromNode(p.Info(Msg).node(&m));
}

const p = @import("paternitas");
