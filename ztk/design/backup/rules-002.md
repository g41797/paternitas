# ztk — Rules (002)

Change from 001: the gates are named, and the rule 2 check is z5.
The owner, 2026-10-26.

The rules for ztk only.

- While ztk lives in the paternitas repo, they add to paternitas
  `design/rules-015.md`, or its newest version. That file still governs the
  session.
- At ZTK HOME they merge into the matryoshka-ztk rules.

Owner's rulings, 2026-10-22.

---

## 1. Minimum knowledge

A ztk user needs to know only how to embed one TypedNode:
`m.inner.SinglyTypedNode` or `m.inner.DoublyTypedNode`.

- Every name a ztk user can reach has a ztk doc.
- That doc stands alone. It does not send the reader to paternitas.
- paternitas names are fine in ztk: `TypeId`, `Anchor`, the TypedNodes,
  `setTypeId`, `toAnchor`, `fromAnchor`. No renames, no wrappers.

## 2. Where paternitas is mentioned

Three places. Nowhere else.

1. The README, "Built on Paternitas":
   - what it is: the TypedNode and type-id layer under ztk
   - ztk's docs cover all a ztk user needs
   - one link
2. The errors page: each message that comes from paternitas, with its ztk
   meaning and fix.
3. One optional pointer, for writing your own container over Anchors
   (`takeFromSlot`, `fillSlot`).

Each of the three says it need not be read.

Not in doc comments, examples, tests or tutorials.

## 3. The check

The ztk gates, in `kitchen/ztk_gates.sh`:

1. z1, the tests in four modes.
2. z2, the negatives in four modes.
3. z3, `zig fmt --check`.
4. z4, the README's "about N lines of Zig" claim.

z5 is reserved for a check that enforces rule 2. It is not approved yet.
