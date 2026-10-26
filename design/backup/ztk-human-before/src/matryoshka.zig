// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! A toolkit for Zig 0.16. Your threads and tasks pass structs to each
//! other, and reuse them.
//!
//! A parent is your struct. It embeds one TypedNode: the field the toolkit
//! links your struct by, and reads its type from.
//!
//! Three layers. You need the first. The other two are optional.
//!
//! - The core: your parent, its helper, the queue.
//! - The mailbox: your threads and tasks send parents to each other.
//! - The pool: used parents wait there until you need one again.
//!
//! Five namespaces, one file each. Each has a page of its own.
//!
//! - `inner`: the TypedNode, the Anchor, the Slot, the type id.
//! - `queue`: a first in, first out chain of parents.
//! - `helper`: one helper per parent type.
//! - `mbox`: the mailbox.
//! - `pool`: the pool.
//!
//! `Mbox` and `Pool` are here at the top too. You usually keep one of each
//! for the whole program.
//!
//! Examples:
//! https://g41797.github.io/matryoshka-ztk/examples/flow/

pub const inner = @import("inner.zig");
pub const queue = @import("queue.zig");
pub const helper = @import("helper.zig");
pub const mbox = @import("mbox.zig");
pub const pool = @import("pool.zig");

/// The mailbox. You keep a `*Mbox`.
pub const Mbox = mbox.Mbox;

/// The pool. You keep a `*Pool`.
pub const Pool = pool.Pool;
