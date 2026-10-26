# ZTK DOCS — backlog (001)

The ztk docs are fixed in many small steps. The owner's ruling, 2026-10-22:

- One stage does not fix all of it. The work is iterative.
- Nothing important is lost. Every finding, deviation and idea is written
  here first, even if no step takes it yet.
- Each step is small, has its own approval, and passes all gates.

Sources: [ztk-docs-01-findings-001.md](ztk-docs-01-findings-001.md) (the
F numbers), [ztk-docs-01-intent-001.md](ztk-docs-01-intent-001.md).

## How the backlog works

- One line per item. An id, the F number, the size, the state.
- Sizes: S (one file, comments only), M (several files), L (needs a
  ruling or touches code).
- States: open, next, done (with the date), dropped (with the reason).
- A step takes one to three S items. A new finding goes in as a new line.
  An item is never deleted. A dropped item says why.

## Suggested first steps

Each is comments or text only. No ruling needed.

1. Step A — rule 2 in `src/`: B1, B2, B3. Three comment lines.
2. Step B — `anchor.typeId()` and the alias docs: B5, B6.
3. Step C — the README's "Built on Paternitas" in rule 2's form: B10.
4. Step D — the errors page, first version, three messages: B12.

After these, the items that need the owner's ruling (L) come one at a time.

## Items

### Comments in `src/`

| id | F | what | size | state |
|---|---|---|---|---|
| B1 | F2.1 | `inner.zig:19` names Paternitas | S | open |
| B2 | F2.2 | `inner.zig:97` names Paternitas, and says how it is built | S | open |
| B3 | F2.3 | `helper.zig:10` names `paternitas.Typed` | S | open |
| B4 | F1.5 | six `//!` headers link to example pages that do not exist | S | open, ruling: keep or remove |
| B5 | F1.1 | `anchor.typeId()` has no ztk doc | S | open |
| B6 | F1.2, F1.3 | `Anchor` and `AnyParent` members: ztk words in the alias `///` and `inner.zig` `//!` | M | open, ruling Q1 |
| B7 | F1.4 | `condition_waitTimeout` is `pub`, internal | S | open, low |
| B8 | — | `NodeKind`, `TypeInfo`, `node_next_offset` reachable, not ztk names | S | open, low |

### Tests, build, negatives

| id | F | what | size | state |
|---|---|---|---|---|
| B9 | F2.4, F2.5 | test comment `layer1_any.zig:202`, build comment `build.zig:57` | S | open, ruling Q3 |
| B15 | F3.3 | two examples numbered 104 | L | open, code, ruling Q4 |
| B16 | F3.6 | `306_no_inner`, `307_two_inners`, `NoInner`, `TwoInners` | L | open, code, ruling Q5 |
| B17 | F1.7 | no negative for `not a struct` or the `fromAny` panic | L | open, code |

### README and site

| id | F | what | size | state |
|---|---|---|---|---|
| B10 | F3.2 | "Built on Paternitas" in rule 2's form | S | open |
| B11 | F3.1, F3.4 | the README is a context note; a real README, from `readme-creation-002` | L | open, many steps |
| B12 | F1.6 | the errors page: three paternitas messages, ztk meaning and fix | M | open |
| B13 | — | the optional pointer page: own container over Anchors | M | open |
| B14 | F3.5 | `ztk/kitchen/docs/index.md` and the nav | M | open, after B12, B13 |

### Rules and checks

| id | F | what | size | state |
|---|---|---|---|---|
| B18 | F4.1–F4.8 | eight paternitas rules into ztk rules-002 | M | open |
| B19 | F4.15, F4.16 | the two conflicts: example layout, superseded docs | L | open, ruling Q6 |
| B20 | F4.9–F4.14 | ztk rules paternitas dropped: confirm they apply to ztk | M | open |
| B21 | — | z4 in `ztk_gates.sh`, the rule-2 check | M | open, after B1–B3, B9 |
| B22 | — | ztk has no design gate and no context index; applies at ZTK HOME | L | open, ZTK HOME |

### Plans and sources

| id | F | what | size | state |
|---|---|---|---|---|
| B23 | F3.7, F5.1 | NEXT's 002 plans use old names; read through plan 003's table | — | note |
| B24 | — | the intent's "Found before" list was out of date; check claims live | — | note |
| B25 | — | plan 003, "Rules for the Matryoshka docs": one item one chain, stale `next`, `next` holds `*Anchor` | M | open |
| B26 | — | carried from ZTK 01: question 4, NEXT's newer README-stage docs | — | open |
