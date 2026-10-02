# Define a parent type

## Description

Define a parent type.

- Message struct embeds an Anchor field. Its name is free.
- ParentHelper(Message) gives the id, stamp, and toAnchor.
- stamp sets the id on a stack value, no heap.
- isIt checks the id.
- toAnchor reaches the embedded Anchor — the way in.
- The inner carries the id and starts unlinked, ready to be placed.

Coming back the other way is fromAnchor. It needs an inner whose type is
not known statically, so it is shown in 023-tag_dispatch.

## Diagram

```
 stack: var msg: Message
      │
 MessageHelper.stamp ──► msg.hdr.anchor.type_id set (no alloc)
      │
 MessageHelper.toAnchor ──► *Anchor (the way in)
      │
 inner carries the id, not linked yet
 (stack-allocated — no release needed)
```

## Source

```zig
pub fn define_a_parent_type(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = .{ allocator, io };

    // A Message on the stack. No allocator involved.
    var msg: Message = .{ .text = "hello", .priority = 1 };
    MessageHelper.stamp(&msg);

    // The id identifies the type at runtime.
    try helpers.expect(error.DefineTypeFailed, MessageHelper.isIt(msg.hdr.anchor.type_id), "expected Message id");
    try helpers.expect(error.DefineTypeFailed, !parents.Event.EventHelper.isIt(msg.hdr.anchor.type_id), "unexpected Event id");

    // toAnchor reaches the embedded Anchor. Nothing else needs to know
    // the field is called hdr.
    const inner: *Anchor = MessageHelper.toAnchor(&msg);

    // The inner travels with its id, so a holder can identify it later.
    try helpers.expect(error.DefineTypeFailed, MessageHelper.isIt(inner.type_id), "inner must carry the Message id");

    // A fresh parent sits on no chain yet.
    try helpers.expect(error.DefineTypeFailed, !matryoshka.inner.isLinked(inner), "new parent must be unlinked");
}

pub const Message = struct {
    hdr: SLink = .{},
    text: []const u8 = "",
    priority: u8 = 0,
};

pub const MessageHelper = matryoshka.helper.ParentHelper(Message);

const parents = @import("../parents/parents.zig");
const helpers = @import("../helpers/helpers.zig");
const matryoshka = @import("matryoshka");
const Anchor = matryoshka.inner.Anchor;
const SLink = matryoshka.inner.SLink;
const std = @import("std");
```
