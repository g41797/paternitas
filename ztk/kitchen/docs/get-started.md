# Get Started

!!! note "Draft"  
    Moved as is from the old README. A later stage rewrites it.

## Steps

1. One thread, one struct. A `SinglyTypedNode` in your struct, a helper, a `Queue`.
2. Add a thread. Send parents over `Io.Queue(*Anchor)`.
3. Add a pool, when repeated allocation becomes a problem.
4. Replace the channel with a mailbox, when the channel stops being enough.

What the mailbox adds to a channel:

- no allocation on transfer
- `close` gives back what was queued
- timeouts, `wakeUpAll`, sending to the front, a per-type limit

If the channel already does what you need, keep it.
