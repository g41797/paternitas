//! A Parent must be a struct.

comptime {
    _ = p.Info(u32).typeId();
}

const p = @import("paternitas");
