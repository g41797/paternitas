//! A Parent type whose name is `msg.Msg`. Its twin in `two/msg.zig` has the
//! same name. The test of the same name checks they get two TypeIds.

pub const Msg: type = struct { tnode: paternitas.SinglyTypedNode = .{} };

const paternitas = @import("paternitas");
