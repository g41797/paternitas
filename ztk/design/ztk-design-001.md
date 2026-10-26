# ztk — design notes (001)

ztk's own design notes. They travel with `ztk/` at ZTK HOME, so the move is
a plain copy. Written 2026-10-26, in ZTK PREP 02 (B38, H22).

- The source, until the move: paternitas `design/paternitas-design-018.md`,
  "ztk on paternitas", and paternitas `design/ztk-plan-003.md`, "Names:
  outside plan → today". Both are copied here as they are.
- After the move this file is ztk's. Its next version is written in
  matryoshka-ztk.
- Paths below that name `design/...` are paternitas paths.

## ztk on paternitas

The ztk stage moves ztk onto paternitas. The full plan, file by file, is the
outside design's section "Matryoshka-ztk changes", in
`design/source/paternitas-design.md`. The open questions are in the intake,
"Open for the ztk stage".

paternitas gives the mechanism, and ztk keeps the policy.

```text
paternitas                               ztk
----------                               ---
TypeId, TypeInfo, Anchor                 Slot: one place per item
SinglyTypedNode, DoublyTypedNode         chain convention: the tail points
Typed: setTypeId, anchor, node, is,        to itself; isLinked, unlink
  parentFromAnchor, parentFromNode       Queue, stack, Mbox, Pool
TypeInfo.nextField: where next is        what goes in next
contract-check policy                    create / destroy, init / finish,
                                           allocator, Io, border checks
```

These are the main changes.

- The ztk currency moves from `*Inner` to `*Anchor`.
- `Inner`, `OuterId` and `OuterInfo` leave the API.
- `AnyOuter` is removed. `Any` replaces it at the dispatch edge.
- A ztk parent may carry a `DoublyTypedNode`. It can sit in the
  application's own `std.DoublyLinkedList`, and move through mailboxes and
  pools, one place at a time.

AUDT 01 changed two things.

- ztk code reads the id as `anchor.typeId()`, not `anchor.type_id`. A11.
- `ParentHelper(Parent)` stays. It wraps `Typed(P)` and adds ztk policy.
  - It has the Slot calls: `fromSlot`, `moveFromSlot`, `mustMoveFromSlot`.
  - It has `create` and `destroy`, with their hooks.
  - It has `isLinked`, and ztk's `setTypeId`.

The ztk vocabulary changes too.

- The ztk API says Parent, TypedNode, Node, Anchor, TypeId, Any.
- "outer" and "inner" stay only where the Matryoshka model is explained: the
  parent is the outer doll.
- The rename is not mechanical. Each `Outer` and `Inner` is read in context.
  - Some get new names: `OuterId` -> `TypeId`, `fromInner` -> `fromAnchor`.
  - Some change meaning: `Inner` -> `Anchor` or TypedNode, `inner.next` ->
    `TypeInfo.nextField`.

ZTK 01 decided three things. Owner's rulings, 2026-10-22.

- `AnyParent` stays a ztk name: `pub const AnyParent = paternitas.Any;`.
  The same struct, a narrower promise: a ztk parent always has a TypedNode.
  `fromAny` on a view of any other struct answers null.
- `ParentHelper` refuses a struct with no TypedNode, after
  `Typed(Parent)`, through the public `findTypedNode`:
  `<P>: no TypedNode, so it cannot be a ztk parent`. `Typed` itself keeps
  taking such a struct.
- A ztk user needs to know only how to embed one TypedNode. paternitas names
  are fine in ztk; its docs are not required reading. The rules:
  `ztk/design/rules-003.md`.

---

## Names: outside plan → today

| outside plan | today |
|---|---|
| `SLink`, `DLink`, Link | `SinglyTypedNode`, `DoublyTypedNode` (`STNode`, `DTNode`), TypedNode |
| `Info(P)` | `Typed(P)` |
| `stamp` | `setTypeId` |
| `paternitas.AnyParent` | `paternitas.Any`. ztk keeps `AnyParent` as its own name. |
| `TypeInfo.toAny()` | `Anchor.toAny()`, answers `?Any` |
| "no Link, so it cannot be a Paternitas Parent" | ztk's own: "no TypedNode, so it cannot be a ztk parent", from `ParentHelper`. `Typed` allows zero TypedNodes since TYID 01. |
| "more than one Link, and exactly one is allowed" | "more than one TypedNode, and at most one is allowed" |
