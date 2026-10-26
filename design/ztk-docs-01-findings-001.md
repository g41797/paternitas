# ZTK DOCS 01 — findings (001)

The audit of ztk's docs, 2026-10-22. The intent is
[ztk-docs-01-intent-001.md](ztk-docs-01-intent-001.md). The rules are
[ztk/design/rules-003.md](../ztk/design/rules-003.md).

Nothing is fixed here. Each finding has a number. ZTK DOCS 02 fixes them,
item by item, with the owner's approval.

## 1. Names a ztk user can reach

ztk re-exports five paternitas names from `inner.zig`: `TypeId`, `Anchor`,
`SinglyTypedNode`, `DoublyTypedNode`, `AnyParent` (= `paternitas.Any`).
The alias has a ztk `///`. Its members do not: autodoc shows paternitas's
own docs for them.

### Reachable through an alias, with a paternitas doc

| name | paternitas doc says | the problem |
|---|---|---|
| `Anchor.typeId()` | "when `setTypeId` was never called on the Parent" | no ztk doc. Intent item 1. |
| `Anchor.typeName()` | "in logs and panic messages" | no ztk doc. Fine as text, but capital "Parent". |
| `Anchor.toAny()` | "Returns an `Any`" | ztk calls it `AnyParent`. The reader never meets `Any`. |
| `Anchor.info()` | "For container authors. Returns the `TypeInfo`" | `TypeInfo` is not a ztk name. Used by `inner.next` and tests only. |
| `Anchor._type_id` | "`Typed(P).setTypeId` writes it. Paternitas trusts this value." | names `Typed(P)` and Paternitas. |
| `AnyParent.ptr`, `.type_id` | the `Any` doc: "`Typed(P).fromAny`", "Paternitas trusts its fields" | names `Typed(P)` and Paternitas. ztk's way back is `ParentHelper(P).fromAny`. |
| `TypeId` | "through `Typed(P).typeId()`"; shared-library note | names `Typed(P)`. ztk's alias `///` covers the rest. |
| `SinglyTypedNode`, `DoublyTypedNode` | "A struct has at most one. With one, it is a Parent." | fine. |
| TypedNode fields `node`, `anchor` | "`setTypeId` writes …" "See `Anchor`." | fine. |
| TypedNode `Node`, `kind`, `node_next_offset` | `kind` is `NodeKind`; `node_next_offset` "for container authors" | `NodeKind` is not a ztk name. Low weight. |

- F1.1 `anchor.typeId()` needs a ztk doc. It is used in ztk's examples.
- F1.2 `Any` vs `AnyParent`: `Anchor.toAny` and the `Any` doc speak of
  `Any` and `Typed(P)`. A ztk user sees `AnyParent` and `ParentHelper`.
- F1.3 Option for ZTK DOCS 02: ztk docs that name these members in its own
  words (in `inner.zig`'s `//!` and the alias `///`). paternitas's own text
  is not ztk's to change (rule 1: no wrappers).

### ztk's own public names

Every `pub` in `src/` has a `///` or is a namespace const. Checked:
`inner`, `helper`, `queue`, `mbox`, `pool`, `matryoshka`.

- F1.4 `internal/cond_timeout.zig`: `condition_waitTimeout` is `pub` with a
  doc that points at `wait`, `waitUncancelable`, std names. Internal, not
  re-exported. Low weight.
- F1.5 Six `//!` headers link to `g41797.github.io/matryoshka-ztk/examples/…`
  pages: `flow`, `inner`, `helper`, `queue`, `mailbox`, `pool`. The ztk site
  has only `ztk/kitchen/docs/index.md`. The links are dead today. They wait for ZTK HOME, or
  come out.

### Messages a ztk user can see

| message | from | reachable by |
|---|---|---|
| `<P>: no TypedNode, so it cannot be a ztk parent` | ztk `ParentHelper` | 306, 314 |
| `<P>: more than one TypedNode, and at most one is allowed` | paternitas `findTypedNode` | 307 |
| `<P>: not a struct` | paternitas `findTypedNode` | `ParentHelper(u32)` |
| `fromAny: setTypeId was never called on the Parent` | paternitas `Typed.fromAny` | `ParentHelper.fromAny`, safety on |
| `mustFromAnchor: asked for X, found Y` | ztk `wrongType` | 301 |
| `TypedNode(N): not a std Node, so it cannot be a Paternitas TypedNode` | paternitas | not reachable: ztk exports only the two TypedNodes |
| `<P>: no TypedNode, so it has only typeId, …` | paternitas | not reachable: `ParentHelper` refuses first |

- F1.6 The errors page (rule 2, place 2) lists the three paternitas
  messages above that a ztk user can see. Capital "Parent" in the `fromAny`
  message is paternitas's word.
- F1.7 No negative covers `not a struct` or the `fromAny` panic. Candidates
  for the page's examples; no test change in DOCS (code does not change).

## 2. paternitas named in text, against rule 2

Rule 2 allows three places. Hits outside them, live grep 2026-10-22:

- F2.1 `src/inner.zig:19` — "The types come from Paternitas."
- F2.2 `src/inner.zig:97` — "Paternitas only says where the word is
  (`nextField`, …)". Also a "how it is built" comment: rules-015 Part 3.
- F2.3 `src/helper.zig:10` — "The helper wraps `paternitas.Typed(Parent)`."
- F2.4 `tests/layer1_any.zig:202` — a test comment. Rule 2 says "not in
  tests". `:227` uses `paternitas.Typed` in code: a test of a struct with no
  TypedNode, needs the import. Code is allowed.
- F2.5 `build.zig:57` — a build comment. Not named by rule 2. Owner's call.
- Clean: `examples/`, `negative/`, `kitchen/docs/`.

The README section "Built on Paternitas" exists but is not rule 2's form:
F3.2.

## 3. Old words in the README and the site

The intent said `Inner` and `item.id` are there. A live grep finds neither.

- F3.1 The README is not a README. Line 3: "This file stores the context for
  the README that DOCS writes. It is not the README yet."
- F3.2 "Built on Paternitas" says "the type description", a path link
  `../paternitas`, and the model text. Rule 2 wants three things: what it
  is, that ztk's docs cover all, one link. And that it need not be read.
- F3.3 The README names `examples/bridge/104-server_handler_and_workers.zig`
  and `tests/examples_bridge.zig`. The file exists. ZTK 02 also made
  `examples/layer4/104-dlink_timeout_list.zig`: two examples numbered 104.
- F3.4 "Steps for a reader" says "from 3tk's 'How to start'". A planning
  note, not reader text.
- F3.5 `ztk/kitchen/docs/index.md`: a hero only, no text, no old words. The nav
  has `Home` alone.
- F3.6 Old words in file names: `negative/compile/306_no_inner.zig`,
  `307_two_inners.zig`, their structs `NoInner`, `TwoInners`. File renames
  touch `build.zig`: code, so out of scope unless the owner says.
- F3.7 The copied NEXT plans use old names throughout: `Inner`,
  `OuterHelper`, `AnyOuter` (readme-creation-002 inventory, lines 268+).
  They are guides, read with plan 003's name table.

## 4. The rules, side by side

paternitas `rules-015` (632 lines) is a trimmed copy of matryoshka-ztk
`rules-050` (1179 lines).

### What paternitas added that ztk should take

- F4.1 Part 0, "The README and the site. MUST": cut text stays on the site.
- F4.2 Part 2, "Order in a source file": user order, not build order.
- F4.3 Part 2, "Layout of an example file": types first, then entry point.
  rules-050 puts the entry point at the top. The two conflict. Owner's call.
- F4.4 Part 2, `setTypeId` on the line after creation. ztk's `create` does
  it; examples that build parents by hand need it. Adapted: "the helper
  const on the line after the struct".
- F4.5 Part 3, "What a comment says": use, not how; a comment stands alone;
  say what the caller sees. Rule 1 of ztk depends on it.
- F4.6 Part 5, "Three kinds of documentation" and "Human voice", with the
  before/after tables.
- F4.7 Part 0, the gate script with per-gate logs and exit-code pass/fail.
  ztk has `ztk_gates.sh` already.
- F4.8 Part 2, a leading `_` marks a `pub` not for use. ztk uses `_` for
  fields already.

### What ztk has that paternitas dropped

rules-015 left them out, since paternitas has no use for them. They still apply to ztk.

- F4.9 Observable by human, in full: the four extraction signals, step
  parameters.
- F4.10 Examples: `helpers.expect` with an own error name; completeness of a
  flow; the Examples-catalog nav sync.
- F4.11 Documented asserts must exist; exclusive access in comments; the
  neighbour check wording.
- F4.12 Where a doc lives, the design gate (`check_design.sh`), superseded
  versions listed in the context index. ztk in this repo has no the context index and
  no design gate. Applies at ZTK HOME.
- F4.13 Dispatch rules (Part 7), invariants (Part 8), patterns, Master,
  stories (frozen).
- F4.14 "Tests before examples", Stage N.a / N.b.

### Conflicts to rule on

- F4.15 Example file layout: entry point first (050) vs types first (014).
- F4.16 Superseded docs: listed in the context index (050) vs moved to
  `design/backup/` (014). This stage used `ztk/design/backup/`.
- F4.17 Banned words: same list. 014 adds nothing new; 050's entries carry
  longer reasons.

## 5. NEXT's plans, copied

- `ztk/design/readme-creation-002.md` and `ztk/design/comments-creation-002.md`
  copied from matryoshka-ztk
  `design/secondary/lang/port/3tk-to-ztk/next/ztk/design/`. Read only there.
- The 001 copies moved to `ztk/design/backup/`, a new folder.
- No live reference to the 001 names outside `design/source/`, which is
  kept as is.
- F5.1 Both plans predate paternitas: old names (F3.7), and they assume a
  ztk without paternitas. ZTK DOCS 02 reads them through plan 003's table.

## Questions for the owner

1. F1.3: ztk text for the paternitas members — in `inner.zig`'s `//!` and
   the alias `///`s. Agree?
2. F1.5: the dead example links in six `//!` headers — keep for ZTK HOME,
   or remove now?
3. F2.4, F2.5: test and build comments that name paternitas — fix both?
4. F3.3: two examples numbered 104 — renumber one (code, out of DOCS)?
5. F3.6: rename `306_no_inner`, `307_two_inners` (touches `build.zig`)?
6. F4.3/F4.15 and F4.16: which rule wins in the new ztk rules, rules-002?
