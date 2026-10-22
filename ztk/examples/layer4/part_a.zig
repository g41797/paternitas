//! Layer 4, part a: Masters, mailbox as multiplexer, Select and cancel.
pub const minimal_master = @import("017-minimal_master.zig");
pub const master_with_pool = @import("018-master_with_pool.zig");
pub const multi_worker_master = @import("019-multi_worker_master.zig");
pub const pipeline_masters = @import("020-pipeline_masters.zig");
pub const request_response = @import("021-request_response.zig");
pub const timer_via_mailbox = @import("022-timer_via_mailbox.zig");
pub const oob_signal = @import("023-oob_signal.zig");
pub const multi_source_mailbox = @import("024-multi_source_mailbox.zig");
pub const select_two_mailboxes = @import("025-select_two_mailboxes.zig");
pub const select_cancel_close = @import("026-select_cancel_close.zig");
pub const select_cancel_master_decides = @import("027-select_cancel_master_decides.zig");
pub const mailbox_timeout = @import("030-mailbox_timeout.zig");
pub const cross_layer_pool_mailbox_roundtrip = @import("032-cross_layer_pool_mailbox_roundtrip.zig");
pub const cross_layer_mixed_types_mailbox = @import("033-cross_layer_mixed_types_mailbox.zig");
pub const select_mixed_sources = @import("028-select_mixed_sources.zig");
pub const select_graceful_shutdown = @import("031-select_graceful_shutdown.zig");
