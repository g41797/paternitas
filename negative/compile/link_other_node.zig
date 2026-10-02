//! A Link of a Node that is not a std Node does not compile.

const MyNode = struct { next: ?*MyNode = null };

comptime {
    _ = p.Link(MyNode);
}

const p = @import("paternitas");
