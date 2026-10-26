//! Layer 2 examples: movement through a mailbox.
pub const simple_send_receive = @import("053-simple_send_receive.zig");
pub const worker_loop = @import("054-worker_loop.zig");
pub const oob_signal = @import("055-oob_signal.zig");
pub const pipeline = @import("056-pipeline.zig");
pub const request_response = @import("057-request_response.zig");
pub const fan_in = @import("058-fan_in.zig");
pub const shutdown_cleanup = @import("059-shutdown_cleanup.zig");
pub const batch_processing = @import("060-batch_processing.zig");
pub const fan_out = @import("061-fan_out.zig");
pub const shutdown_exit = @import("062-shutdown_exit.zig");
pub const wake_up_all = @import("097-wake_up_all.zig");
pub const refused_send = @import("099-refused_send.zig");
pub const send_limit = @import("100-send_limit.zig");
