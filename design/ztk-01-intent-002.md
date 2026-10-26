# ZTK 01 — intent (002)

The stage: ztk green on today's paternitas. Charter:
[implementation-plan-034.md](implementation-plan-034.md), "ZTK".
The file plan: [ztk-plan-002.md](backup/ztk-plan-002.md).
Design: [paternitas-design-018.md](paternitas-design-018.md), "ztk on paternitas".

The owner named it, 2026-10-22.

Change from 001: the owner's new requirement, 2026-10-22: a ztk user needs
no knowledge of paternitas beyond the absolute minimum. Its advice and
questions are below. An audit of the former ztk API follows; its outcome
may add wrappers.

Status: closed, 2026-10-22. Steps A to D done. Questions 4, 6, 7 carry to ZTK 02 and ZTK DOCS.

---

## What is known

- `bash kitchen/ztk_gates.sh`: z1 fails at `ztk/src/inner.zig:59`,
  `paternitas.AnyParent`. The name is `Any` now.
- With that line fixed, in a scratch copy before ZTK 00: 198/199 tests, Debug
  only.
- Since TYID 01, `Typed` takes a struct with no TypedNode. `ParentHelper` has
  no refusal of its own. Negative 306 expects the old text.
- Negatives 306, 307, 314 expect old paternitas texts in `ztk/build.zig`.
- Checked in scratch: with `const P = paternitas.Typed(Parent);` first, a
  `u32` gets only the paternitas error; a struct with no TypedNode gets the
  ztk error. No struct guard needed.

---

## The owner's rulings, 2026-10-22

1. `ParentHelper` keeps `paternitas.Typed(Parent)` and refuses zero
   TypedNodes itself: `<P>: no TypedNode, so it cannot be a ztk parent`.
2. paternitas makes `findTypedNode` public, so ztk does not copy the field
   scan. Its own approval, step B below.
3. Its "not a struct" message is neutral: `<P>: not a struct`.
4. Its doc comment:

```zig
/// Finds the TypedNode field of `P`.
///
/// Returns the field's name, or null when `P` has no TypedNode.
///
/// Use it when you write your own container and need to reach
/// the TypedNode by name, with `@field`.
///
/// - `P` MUST be a struct.
/// - `P` has at most one `SinglyTypedNode` or `DoublyTypedNode` field.
/// - Breaking either rule is a compile error that names the type.
```

---

## New requirement: minimum paternitas knowledge

The owner, 2026-10-22: a ztk user needs no knowledge of paternitas beyond
the absolute minimum.

- The minimum: embed one `m.inner.SinglyTypedNode` or
  `m.inner.DoublyTypedNode` field. Learned from ztk's own docs.
- What a ztk user sees of paternitas today, measured in `ztk/`:
  1. Five re-exports in `inner`: `TypeId`, `Anchor`, the two TypedNodes,
     `AnyParent`. In the autodoc they lead to paternitas pages.
  2. `anchor.typeId()`, a paternitas method, in seven example lines.
  3. Compile errors: zero TypedNodes gets a ztk text (ruling 1). Two, and
     not a struct, get paternitas texts, neutral (ruling 3).
  4. Panics: ztk has its own `wrongType`. One paternitas panic can reach a
     user: `fromAny: setTypeId was never called on the Parent`.
  5. `helper.zig:10` doc: "wraps `paternitas.Typed(Parent)`". An
     implementation detail.
  6. The build: `.path = ".."` works only here. ZTK HOME needs a URL and
     hash.
- Advice, not approved:
  - A design rule: a ztk user needs to know only how to embed a TypedNode.
    Everything else is a ztk name with a ztk doc.
  - A z4 check: `paternitas` in ztk examples, tests and doc comments fails,
    outside an allowed list.
  - ZTK 01: the `helper.zig:10` line, the `AnyParent` doc for ztk users.
    ZTK 02: `anchor.typeId()`, z4. ZTK DOCS: re-export docs, the README.
    ZTK HOME: the URL dependency.
- The audit: the former ztk API (NEXT and its docs) against `ztk/`. What was
  removed or renamed, and whether a ztk wrapper should keep it. Result in
  the log and the questions below.

---

## The intent

In rounds: ztk, paternitas fix, ztk. Each round ends with its gates.

A. ztk, first round. Only in `ztk/`.

- `src/inner.zig:59`: `pub const AnyParent = paternitas.Any;`. Its doc adds:
  ztk's narrower view; a ztk parent always has a TypedNode.
- `anyFromSlot` doc: null when the Slot is empty, or when `setTypeId` was
  never called on the parent.
- New test in `tests/layer1_any.zig`: `anyFromSlot` answers null when
  `setTypeId` was never called.
- New test: `fromAny` on an `Any` of a struct with no TypedNode answers null.
  The `Any` comes from `paternitas.Typed(S).toAny`, since `ParentHelper`
  refuses such a struct.
- Run `kitchen/ztk_gates.sh`. Expected: z1 green; z2 fails on 306, 307, 314.

B. paternitas fix. Its own approval. Both gate scripts pass after it.

- `src/paternitas.zig`: `pub fn findTypedNode`, with the doc above. Its
  message: `<P>: not a struct`. The two-TypedNode message unchanged.
- `build.zig:127`: the expected text of `not_struct.zig`.
- The site: `kitchen/docs/guides/type-ids.md:117`,
  `kitchen/docs/reference/limits.md:88`.
- Design 015 to 016: the two lines with the old message; `findTypedNode` in
  the public surface. 015 to `design/backup/`, references repointed.
- The README: no change expected. Its size claim is checked by g4.
- `bash kitchen/gates.sh`, then `bash kitchen/ztk_gates.sh`.

C. ztk, second round.

- `src/helper.zig`, right after `const P = paternitas.Typed(Parent);`:

```zig
comptime {
    if (paternitas.findTypedNode(Parent) == null) @compileError(@typeName(Parent) ++
        ": no TypedNode, so it cannot be a ztk parent");
}
```

- `ztk/build.zig`: 306 and 314 expect the ztk text; 307 expects
  `more than one TypedNode, and at most one is allowed`.
- All three ztk gates green, four modes. Six paternitas gates green.

D. Close.

- Design 016 (or 017): `AnyParent` is ztk's narrower view of `Any`.
- [ztk-plan-002.md](backup/ztk-plan-002.md): items done in ZTK 01 marked. A new
  version, 002.
- `STATUS.md`, `STATUS-LOG.md`.

---

## The owner's answers to the audit advice, 2026-10-22

- G1, the published Matryoshka (`PolyNode`, `PolyHelper`, `ItemHandle`):
  not a concern. No migration page from G1.
- paternitas names in ztk are fine: `TypeId`, `Anchor`, `SinglyTypedNode`,
  `DoublyTypedNode`, `setTypeId`, `toAnchor`, `fromAnchor`. No ztk renames.
  No G2 aliases, no wrapper structs.
- The requirement stands for knowledge, not names: a ztk user learns what
  they need from ztk's docs, never from paternitas's.
- Step A approved, 2026-10-22.
- Question 8: no separate stage. The docs audit goes into ZTK DOCS.
- ztk docs mention paternitas only in three places, the owner, 2026-10-22:
  the README "Built on Paternitas" (what it is, ztk docs cover all, one
  link); the errors page, for the messages that come from paternitas; one
  optional pointer for writing your own container. Each says it need not be
  read. Nowhere else. For ZTK DOCS. The rules live in a new
  `ztk/design/rules-003.md`, with a pointer in `STATUS.md`.

---

## Questions

1. Approve A?
2. Approve B now, or ask again when A is green?
3. The plan says "design 005" in three places. It means design 015, the one
   with "ztk on paternitas". Fix the plan text to "design 015"?
4. The NEXT "other" items from ZTK 00: NEXT's newer README-stage docs
   (readme-creation 002, comments-creation 002, the draft README 001).
   Bring them into `ztk/design/`, leave them for ZTK DOCS, or drop?
5. Take the minimum-knowledge rule into the design as worded?
6. Add the z4 check?
7. `anchor.typeId()`: a ztk wrapper (which name?), or `Helper.isIt` taking
   an Anchor? With paternitas names fine, `anchor.typeId()` may stay, with
   a ztk doc that says it.
8. A ZTK AUDT stage between ZTK 01 and ZTK 02: every public ztk name and
   every paternitas name, method or message a ztk user can reach; does its
   ztk doc stand alone?
