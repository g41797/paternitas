//! The examples module. Each example is one file, one public function, and a
//! test wrapper in `tests/examples_tests.zig` that runs it.
pub const before_paternitas = @import("before_paternitas.zig");
pub const set_type_id_and_recover = @import("001-set_type_id_and_recover.zig");
pub const mixed_list = @import("002-mixed_list.zig");
pub const timeout_list = @import("003-timeout_list.zig");
pub const handler_map = @import("004-handler_map.zig");
pub const large_struct_in_union = @import("005-large_struct_in_union.zig");
pub const anchor_chain = @import("006-anchor_chain.zig");
pub const type_id_without_node = @import("007-type_id_without_node.zig");
