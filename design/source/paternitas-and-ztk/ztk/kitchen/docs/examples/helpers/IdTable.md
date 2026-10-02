# A dispatch table: `{id, handler}` pairs owned by a receiver

## Description

A dispatch table: `{id, handler}` pairs owned by a receiver.

An TypeId says what a parent **is**, not what a receiver should **do** with
it. The same Event means a log line to one Master and a counter bump to
another, so the handler cannot belong to the id. It belongs to the pair
(receiver, id) — which is what this table holds.

Nothing in `src/` is needed. `ParentHelper.ID` is a value that can be
stored, comparing two ids is `==`, and `Slot` reports what the handler did
with the item. The table is composed from blocks that already exist.

Not part of matryoshka: the handler's first parameter is the application's
own receiver type, which the toolkit cannot name. Applications are free to
write a different table, or none at all.

See `design/table-dispatch-002.md`.

## Source

```zig
/// Builds a dispatch table type for receiver type `T`.
pub fn IdTable(comptime T: type) type {
    return struct {
        const Self = @This();

        /// A handler for one id.
        ///
        /// **The transfer rule.** On return, the Slot is null if the handler
        /// took the item, full if it did not. A handler may take the item,
        /// forward it elsewhere, or look and leave it — but it must leave the
        /// Slot telling the truth about which. The caller frees whatever is
        /// left.
        ///
        /// This is a convention between the handler author and the loop that
        /// calls it. Matryoshka cannot enforce it and does not care.
        ///
        /// A handler may both move the item and then fail. The Slot reports
        /// where the item is; the error reports whether the work succeeded.
        /// They are two different questions.
        ///
        /// `anyerror` and not an inferred error set: a function pointer type
        /// needs its error set written out, and the table holds handlers
        /// written by different authors.
        pub const Handler = *const fn (self: *T, slot: *Slot) anyerror!void;

        /// One id mapped to one handler.
        pub const Entry = struct {
            id: TypeId,
            handler: Handler,
        };

        /// Usually a comptime literal. May also be a slice of a buffer the
        /// receiver owns — see `design/table-dispatch-002.md`. No allocator
        /// either way, and no `init` or `deinit`: a table is a value.
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

        /// Calls the handler for the item in `slot`.
        ///
        /// - `error.EmptySlot` — nothing to dispatch.
        /// - `error.NoHandler` — no entry matched. Nothing was called and the
        ///   Slot is untouched, so the caller still holds the item and frees
        ///   it. Unlike the last branch of an `isIt` chain, which cannot.
        ///
        /// Anything else comes from the handler itself. Look at the Slot, not
        /// at the error, to learn where the item went.
        pub fn dispatch(self: Self, receiver: *T, slot: *Slot) anyerror!void {
            const anchor = slot.* orelse return error.EmptySlot;
            const handler = self.find(anchor.type_id) orelse return error.NoHandler;
            return handler(receiver, slot);
        }
    };
}

const matryoshka = @import("matryoshka");
const TypeId = matryoshka.inner.TypeId;
const Slot = matryoshka.inner.Slot;
```
