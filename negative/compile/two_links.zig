//! Two Links in one Parent do not compile.

const Two = struct {
    a: p.SLink = .{},
    b: p.DLink = .{},
};

comptime {
    _ = p.Info(Two).typeId();
}

const p = @import("paternitas");
