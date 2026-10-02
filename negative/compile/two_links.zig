//! Two Links in one Parent do not compile.

const TwoLinks = struct {
    a: p.SLink = .{},
    b: p.DLink = .{},
};

comptime {
    _ = p.Typed(TwoLinks).typeId();
}

const p = @import("paternitas");
