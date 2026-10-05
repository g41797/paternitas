//! Typed takes structs only.

comptime {
    _ = p.Typed(u32).typeId();
}

const p = @import("paternitas");
