//! A TypedNode of a Node that is not a std Node does not compile.

const OtherNode = struct { next: ?*OtherNode = null };

comptime {
    _ = p.TypedNode(OtherNode);
}

const p = @import("paternitas");
