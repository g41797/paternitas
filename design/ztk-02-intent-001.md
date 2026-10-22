# ZTK 02 — intent (001)

The owner named ZTK 02, 2026-10-22. The plan: [ztk-plan-003.md](ztk-plan-003.md).

Status: closed, 2026-10-22. The owner read A and B: ok.

## The owner's answers, 2026-10-22

1. Examples A and B: yes. `ztk/examples/layer4/`, 104 and 105.
2. The Mbox receive form that hands out `AnyParent`: no. Slot usage is
   MUST. No acquisition leaves the toolkit without a Slot.
3. `anchor.typeId()` in examples stays. ZTK DOCS gives it a ztk doc.
   (ZTK 01, question 7.)
4. NEXT's newer README-stage docs: left for ZTK DOCS. (ZTK 01, question 4.)
5. The z4 check: reserved until ZTK DOCS. (ZTK 01, question 6.)
6. ZTK AUDT: no stage of its own. Folded into ZTK DOCS. (ZTK 01,
   question 8.)

## The intent

A. `104-dlink_timeout_list.zig`. A parent with a `DoublyTypedNode` sits in
   the user's `std.DoublyLinkedList`, a timeout list. It is unlinked, put in
   a Slot, sent through an Mbox, received into a Slot, moved out with its
   Helper and put back into the list. The parent type goes in
   `examples/parents/`.

B. `105-handler_map_dispatch.zig`. A map from `TypeId` to
   `*const fn (slot: *Slot) void`. The consumer receives into a Slot,
   reads `slot.?.typeId()`, finds the handler and passes it the Slot. The
   handler moves the parent out with `Helper.mustMoveFromSlot`, a typed and
   checked move. After the call the consumer checks that the Slot is empty.
   No `AnyParent`, no unchecked cast.

Both are added to `part_c.zig` and run as tests. paternitas is unchanged.

## Check

All three ztk gates, all six paternitas gates.

## Done, 2026-10-22

- `ztk/examples/parents/Deadline.zig`: a demo parent with a
  DoublyTypedNode. `parents.zig` knows it in `destroyById`.
- `ztk/examples/layer4/104-dlink_timeout_list.zig`,
  `105-handler_map_dispatch.zig`. In `part_c.zig`. Tests in
  `ztk/tests/examples_layer4c.zig`.
- One change from B as written: the handler reads with `mustFromSlot` and
  consumes with `Helper.destroy`, which empties the Slot. The parent never
  leaves a Slot. `mustMoveFromSlot` would hand out a bare pointer with no
  way to free it but a second Slot.
- The map is a fixed array of `{ id, handler }`, searched in order. No
  allocation.
- Gates: three ztk gates pass, 202/203 tests, 1 skipped. Six paternitas
  gates pass. paternitas unchanged.
