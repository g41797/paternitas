// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! A dispatch table: `{id, handler}` pairs that a receiver keeps.
//!
//! A TypeId says what a parent **is**, not what a receiver should **do** with
//! it. The same Event is a log line to one Master, and a count to another.
//! So the handler belongs to the pair (receiver, id). This table keeps that
//! pair.
//!
//! It needs nothing new from the toolkit.
//!
//! - `ParentHelper.ID` is a value you can store.
//! - Two ids compare with `==`.
//! - The Slot tells you what the handler did with the parent.
//!
//! It is not part of the toolkit. The handler's first parameter is your own
//! receiver type, which the toolkit cannot name. Write a different table, or
//! none at all.

/// Builds a dispatch table type for receiver type `T`.
pub fn IdTable(comptime T: type) type {
    return struct {
        const Self = @This();

        /// A handler for one id.
        ///
        /// **The transfer rule.** On return, the Slot is empty if the handler
        /// took the parent, and full if it did not.
        ///
        /// - A handler may take the parent, pass it on, or look and leave it.
        /// - Whatever it does, the Slot MUST tell the truth.
        /// - The caller releases whatever is left.
        ///
        /// The toolkit cannot enforce this. It is an agreement between the
        /// handler and the loop that calls it.
        ///
        /// A handler may move the parent and then fail. The Slot tells you
        /// where the parent is. The error tells you whether the work
        /// succeeded. These are two different questions.
        ///
        /// It returns `anyerror`, not an inferred error set. A function
        /// pointer type needs its error set written out, and different
        /// people write the handlers in one table.
        pub const Handler = *const fn (self: *T, slot: *Slot) anyerror!void;

        /// One id mapped to one handler.
        pub const Entry = struct {
            id: TypeId,
            handler: Handler,
        };

        /// Usually a comptime literal. It may also be a slice of a buffer the
        /// receiver keeps. Either way there is no allocator, and no `init` or
        /// `deinit`. A table is a value.
        entries: []const Entry = &.{},

        /// The handler for `id`, or null when no entry matches.
        ///
        /// A miss is not a defect. An id present in one table and absent from
        /// another is the normal result of two receivers doing different jobs.
        pub fn find(self: Self, id: TypeId) ?Handler {
            for (self.entries) |entry| {
                if (entry.id == id) return entry.handler;
            }
            return null;
        }

        /// Calls the handler for the parent in `slot`.
        ///
        /// - `error.EmptySlot`: nothing to dispatch.
        /// - `error.NoHandler`: no entry matched. Nothing was called, and the
        ///   Slot is untouched. You still have the parent, and you release it.
        ///
        /// Any other error comes from the handler. Look at the Slot, not at
        /// the error, to learn where the parent went.
        pub fn dispatch(self: Self, receiver: *T, slot: *Slot) anyerror!void {
            const anchor = slot.* orelse return error.EmptySlot;
            const handler = self.find(anchor.typeId()) orelse return error.NoHandler;
            return handler(receiver, slot);
        }
    };
}

const matryoshka = @import("matryoshka");
const TypeId = matryoshka.inner.TypeId;
const Slot = matryoshka.inner.Slot;
