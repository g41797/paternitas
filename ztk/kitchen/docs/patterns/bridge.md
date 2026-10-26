# Crossing to std.Io

!!! note "Draft"  
    Moved as is from the old README. A later stage rewrites it.

The toolkit does not replace the io side. It sits beside it.

- The io side has its own queue and its own types.
- Matryoshka has parents, a pool and a mailbox.
- The bridge is the point where a parent crosses to the io side and back.

A parent crosses as its bare `*Anchor`: one word that says where the parent  
is and what it is.

- `inner.takeFromSlot(&slot)` takes the Anchor out, before a put.
- `inner.fillSlot(&slot, anchor)` puts it back into a Slot, after a get.
- `fromAnchor` tells the receiver whether it is its own type.
- A copied `*Anchor` is a second owner, as a copied Slot would be.

A receiver that dispatches by id through a handler map takes a view  
instead: `inner.anyFromSlot(&slot)` gives an `AnyParent`, the parent's  
address and its id. A view, not an owner.

## The working code

`examples/bridge/104-server_handler_and_workers.zig`, tested by  
`tests/examples_bridge.zig`. Run it alone with `zig build examples-bridge`.

- The queue carries `Msg`: `request` from the io side, `reply` as a bare
  `*Anchor`, and `stop`.

- A handler dispatches on the tag.
- A request becomes a greeting from the pool, sent to a shared mailbox.
- Workers receive from the mailbox and reply through the queue.
- "Hello, Matryoshka!" goes in, "Hello, Io" comes out.
