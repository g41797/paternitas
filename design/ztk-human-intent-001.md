# ZTK HUMAN — the ztk comments made human (intent 001)

The owner named the stage, 2026-10-26. B43. Model: Opus, effort high.

- ztk only: `//!`, `///`, example headers, test comments.
- Comments only. The meaning is kept. Text moved out goes to a site page or
  the backlog.
- The rules: [rules-016.md](rules-016.md) Parts 3, 4, 5;
  [ztk/design/rules-003.md](../ztk/design/rules-003.md); matryoshka-ztk
  rules-050 Part 4 and Staccato.

## The owner's answers, 2026-10-26

1. The order: `matryoshka.zig`, `queue.zig`, `internal/*`, `helper.zig`,
   `inner.zig`, `mbox.zig`, `pool.zig`. Then the example headers, then the
   tests.
2. Where paternitas rules and rules-050 disagree, paternitas wins. The
   example header opens with `//! Title: ...`. This answers B19.
3. No other rules are read first.
4. One step per section in the big files, one per file in the small ones.
   Before and after go to the owner, then the edit.

## State

- Step 1, `matryoshka.zig`: shown to the owner, waiting.
- Step 1, `matryoshka.zig`: done.
- Step 2, `queue.zig`: done.
- Step 3, `internal/check.zig`: done.
- Step 4, `internal/cond_timeout.zig`: a `//!` header only; std's comments kept, no SPDX (the owner).
- Step 5, `internal/stack.zig`: done.
- Step 6, `helper.zig`: done.
- Step 7, `inner.zig`: done. `fillSlot` has new advice: call `unlink` first on a parent from a std list.
- Step 8, `mbox.zig`: done (section A approved, the rest unattended).
- Step 9, `pool.zig`: done, unattended.
- Step 10, the example headers, helpers and tests: done, unattended.
- Closed, 2026-10-26. Plan 033, backlog 013.

## Moved out of comments

Kept here until a site page takes them. They go to the backlog at close.

- `queue.zig`: the last parent points at itself, which makes the link test
  exact, even for a chain of one.
- `queue.zig`: `countOfId` exists for `sendLimited`: are there already this
  many of the sender's type?
- `queue.zig`: the operation set is what a real behaviour needs, no more.
- `helper.zig`: one description per type, `const`, so its address is the
  identity (`ID`).
- `helper.zig`: ztk passes the allocator and the `Io` where 3tk passes an
  allocator alone (`create`).
- `inner.zig`: this file sets the chain convention, the Slot, and the
  borders out of the toolkit (`//!`).
- `inner.zig`, `next`: the one type pun in the toolkit. std declares the word
  as `?*SinglyLinkedList.Node` or `?*DoublyLinkedList.Node`; on a toolkit
  chain it has an `*Anchor`. Same size, same alignment. Zig does no
  type-based alias analysis today, and this relies on it.

## Unattended mode, the owner's ruling, 2026-10-26

- Claude goes on without asking, through ZTK HUMAN and the ZTK HOME
  preparation (B37 to B40). It stops before ZTK HOME.
- Waits for the owner: code changes beyond comments, deletions, writes to
  matryoshka-ztk, the paternitas tag, rulings. Each goes to the questions
  list in [ztk-human-review-001.md](ztk-human-review-001.md).
- The files before ZTK HUMAN's unattended part: `design/backup/ztk-human-before/`
  (`src/`, `examples/`, `tests/`). Diff against them to review.
- `mbox.zig` section A was approved before the switch. "answers the hard
  questions" stays (the owner).
- `mbox.zig`, `sendOob`: two queues keep the order, so nothing is inserted
  into the middle of a chain.
- `mbox.zig`, `isClosed`: one atomic read.
- `mbox.zig`, `isIdle`: without it there is no way to ask whether freeing is
  allowed other than to try it.
- `mbox.zig`, `destroy`: not a `check`, because freeing a mailbox another
  context is still inside is not a contract a fast build may assume away.
  A mailbox still on a chain is a caller who freed something another
  container keeps; the chain notices.
- `pool.zig`, `get`: `error.UnknownIdentity` is a caller's mistake about the
  pool's own shape; a fast build that carried on would call your hook with
  an identity the pool never knew.
- `pool.zig`, `getWait`: a hook that could make a parent would make the wait
  pointless.
- `pool.zig`, `countOf`: the whole surface answers a wrong identity one way.
- `pool.zig`, `destroy`: as `mbox.zig`, not a `check`.
