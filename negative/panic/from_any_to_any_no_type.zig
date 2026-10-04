//! fromAny of an AnyParent from toAny, when setTypeId was never called on the
//! Parent. toAny does not check it.
//!
//! - Debug, ReleaseSafe: aborts, and says why.
//! - ReleaseFast, ReleaseSmall: the contract check compiles to nothing. Exits 0.

const Msg = struct { tnode: p.SinglyTypedNode = .{} };

pub fn main() void {
    var m: Msg = .{};
    const any: p.AnyParent = p.Typed(Msg).toAny(&m);
    _ = p.Typed(Msg).fromAny(any);
}

const p = @import("paternitas");
