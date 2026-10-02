//! A Parent must be a struct.

comptime {
    _ = p.Typed(u32).typeId();
}

const p = @import("paternitas");
