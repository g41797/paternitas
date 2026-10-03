# matryoshka-ztk

The rewritten toolkit. This file stores the context for the README that DOCS  
writes. It is not the README yet.

## The bridge

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

## Steps for a reader

The order the README follows, from 3tk's "How to start".

1. One thread, one struct. A `SinglyTypedNode` in your struct, a helper, a `Queue`.
2. Add a thread. Send parents over `Io.Queue(*Anchor)`.
3. Add a pool, when repeated allocation becomes a problem.
4. Replace the channel with a mailbox, when the channel stops being enough.

What the mailbox adds to a channel:

- no allocation on transfer
- `close` gives back what was queued
- timeouts, `wakeUpAll`, sending to the front, a per-type limit

If the channel already does what you need, keep it.

## Built on Paternitas

A parent is the struct that embeds the TypedNode, as in `@fieldParentPtr`.
The Matryoshka model calls it the outer doll: parent, then TypedNode, then
Anchor.

An item is a parent while it is in a mailbox, a queue or a pool. In code,
what a container holds is an `*Anchor`.

The TypedNode, the Anchor and the type description come from Paternitas
(`../paternitas`). Matryoshka adds the policy: the chain convention, the
Slot, the mailbox and the pool.

A parent embeds `SinglyTypedNode` or `DoublyTypedNode`. A DoublyTypedNode parent can also live in the
application's own `std.DoublyLinkedList` — one place at a time.
