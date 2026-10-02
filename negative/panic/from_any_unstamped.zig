//! fromAny of a hand-built AnyParent whose Parent was never stamped.
//!
//! - Debug, ReleaseSafe: aborts, and says why.
//! - ReleaseFast, ReleaseSmall: the contract check compiles to nothing. Exits 0.

const Msg = struct { link: p.SLink = .{} };

pub fn main() void {
    var m: Msg = .{};
    const forged: p.AnyParent = .{ .ptr = &m, .type_id = p.Info(Msg).typeId() };
    _ = p.Info(Msg).fromAny(forged);
}

const p = @import("paternitas");
