//! A Link of a Node that is not a std Node does not compile.

const OtherNode = struct { next: ?*OtherNode = null };

comptime {
    _ = p.Link(OtherNode);
}

const p = @import("paternitas");
