//! fromAny of a hand-built Any, when setTypeId was never called on the
//! Parent.
//!
//! - Debug, ReleaseSafe: aborts, and says why.
//! - ReleaseFast, ReleaseSmall: the contract check compiles to nothing. Exits 0.

const Msg = struct { tnode: p.SinglyTypedNode = .{} };

pub fn main() void {
    var m: Msg = .{};
    const hand_built: p.Any = .{ .ptr = &m, .type_id = p.Typed(Msg).typeId() };
    _ = p.Typed(Msg).fromAny(hand_built);
}

const p = @import("paternitas");
