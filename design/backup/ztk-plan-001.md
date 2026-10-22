# ztk on paternitas — the file-by-file plan (001)

A current copy of the outside plan: `design/source/paternitas-design.md`,
"Matryoshka-ztk changes", line 1084. Written in ZTK 00, 2026-10-22.

The outside plan predates NAME 01, AUDT 01 and TYID. Its names are old. This
copy uses today's names and marks what the copy in `ztk/` already did.

The stages that use it: [implementation-plan-024.md](implementation-plan-024.md),
"ZTK".

## Names: outside plan → today

| outside plan | today |
|---|---|
| `SLink`, `DLink`, Link | `SinglyTypedNode`, `DoublyTypedNode` (`STNode`, `DTNode`), TypedNode |
| `Info(P)` | `Typed(P)` |
| `stamp` | `setTypeId` |
| `paternitas.AnyParent` | `paternitas.Any`. ztk keeps `AnyParent` as its own name. |
| `TypeInfo.toAny()` | `Anchor.toAny()`, answers `?Any` |
| "no Link, so it cannot be a Paternitas Parent" | none. Zero TypedNodes is allowed in `Typed` since TYID 01. |
| "more than one Link, and exactly one is allowed" | "more than one TypedNode, and at most one is allowed" |

## File by file

Marks: **done** — the copy has it. **open** — work left.

- `internal/info.zig` removed. **done**
- `internal/check.zig` unchanged. **done**
- `inner.zig`
  - `Inner`, `OuterId`, `AnyOuter`, `ofNode` gone. `TypeId`, `Anchor`,
    `SinglyTypedNode`, `DoublyTypedNode` re-exported. `Slot = ?*Anchor`.
    `next`, `isLinked`, `unlink`, `takeFromSlot`, `fillSlot`, `anyFromSlot`.
    **done**
  - `AnyParent = paternitas.AnyParent`: no such name now. Becomes
    `paternitas.Any`, with its doc. **open, ZTK 01**
  - `anyFromSlot`: null also when `setTypeId` was never called. Doc and a
    test. **open, ZTK 01**
- `helper.zig`
  - `ParentHelper(Parent)` over `paternitas.Typed(Parent)`: `ID`, `isIt`,
    `setTypeId`, `toAnchor`, `fromAnchor`, `mustFromAnchor`, the Slot calls,
    `toAny`, `fromAny`, `Node`, `node`, `fromNode`, `isLinked`, `create`,
    `destroy`. **done**
  - Zero TypedNodes: `Typed` takes such a struct now. `ParentHelper` must
    refuse it itself, with its own compile error. **open, ZTK 01**
  - `fromAny` on an `Any` of a struct with no TypedNode answers null. A test.
    **open, ZTK 01**
- `queue.zig`: a queue of `*Anchor` through `inner.next`. **done**
- `internal/stack.zig`: `AnchorStack`. **done**
- `mbox.zig`: `Queue` of Anchors, `Result.anchor`, the Mbox embeds a
  TypedNode. **done**
  - A receive form that hands out `AnyParent`. Optional in the outside plan.
    **open, owner decides**
- `pool.zig`: `AnchorStack`, the Pool embeds a TypedNode. **done**
- `matryoshka.zig`: does not re-export paternitas. **done**
- Build: `build.zig` adds the module. **done**. `build.zig.zon`:
  `.path = ".."` in `ztk/`. **done, ZTK 00**

## Tests, examples, negatives

- Renames, `examples/parents/`, `tests/parents.zig`. **done**
- `tests/layer1_any.zig`: scenarios 320 to 329. **done**
- `examples/bridge/104`, `examples/layer1/098`. **done**
- Negatives 321 `take_no_type`, 322 `take_linked`, compile 314
  `bare_node`. **done**
- 306, 307, 314: expected texts are the old ones. 306 and 314 depend on the
  `ParentHelper` refusal above. 307 takes the new paternitas text.
  **open, ZTK 01**
- New examples from the outside plan: a `DoublyTypedNode` parent in a user's
  timeout list through a mailbox; a handler-map consumer of `AnyParent`s.
  **open, ZTK 02 or later**

## Rules for the Matryoshka docs

"One item, one chain" covers std lists; the stale `next` refused at the
border; the `next` word holds an `*Anchor` on a chain. **open, ZTK DOCS**
