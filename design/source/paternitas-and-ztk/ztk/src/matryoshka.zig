// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! A toolkit for Zig 0.16: items move between holders, and are created and
//! released.
//!
//! Three layers, each optional above the first:
//!
//! - the core — a parent, its Link, the id, the helper, the queue
//! - the mailbox — items move from one context to another
//! - the pool — items are kept and handed out again
//!
//! Five namespaces, one per file, each with a page of its own:
//!
//! - `inner` — the Link, the Anchor, the Slot, the id, what a parent is
//! - `queue` — a first in, first out chain of parents
//! - `helper` — one helper per parent type, and the borders out of the toolkit
//! - `mbox` — a queue between contexts
//! - `pool` — parents kept so they can be used again
//!
//! `Mbox` and `Pool` are also here, flat, because application code keeps one
//! for the life of the program.
//!
//! Examples:
//! https://g41797.github.io/matryoshka-ztk/examples/flow/

pub const inner = @import("inner.zig");
pub const queue = @import("queue.zig");
pub const helper = @import("helper.zig");
pub const mbox = @import("mbox.zig");
pub const pool = @import("pool.zig");

/// The toolkit's version. Matches `build.zig.zon`.
pub const VERSION = "0.1.0";

/// A queue between contexts. Application code keeps `*Mbox`.
pub const Mbox = mbox.Mbox;

/// Keeps used parents so they can be used again. Application code keeps `*Pool`.
pub const Pool = pool.Pool;
