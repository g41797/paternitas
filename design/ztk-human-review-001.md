# ZTK HUMAN — what changed unattended, and the questions (001)

The owner reviews this after the unattended run. Each change: the file, what
changed, why. The old files: `design/backup/ztk-human-before/`.

## Changes

- `src/mbox.zig`, unattended after section A.
  - "contexts" is "threads and tasks"; "hands back" is "returns"; "holding",
    "holds" reworded.
  - `sendLimited`, `receive`, `receiveAll`, `close`, `wakeUpAll`: long
    sentences split; labels made sentences.
  - `isIdle`, `destroy`: the reasons moved out; what you MUST do stays.
  - `destroy`: "Closing is not done here…" is now "Call `close` first, and
    release the parents it returns."
  - The comments on private declarations are unchanged. No API reader
    sees them.
- `src/pool.zig`.
  - A factual fix: `newPool` in the `//!` and in `destroy` is `new`. The
    function is `pool.new`.
  - The `//!`: "contexts" is "threads and tasks"; the stack's reason in
    bullets, as in `internal/stack.zig`.
  - `Hooks`: the labels and em-dashes are plain sentences; `in_pool` and
    the re-entered `on_close` in bullets.
  - `get`, `put`: the reasons for `error.UnknownIdentity` in every build
    are shortened to what you see.
  - `isIdle`, `destroy`, `new`, `getWaitResult`: as in `mbox.zig`.
  - Two private comments: "holds" is "has".
- `examples/`, all 75 numbered headers, unattended.
  - Each opens with `//! Title: ...`, then a one-line intent, then the
    steps as commands. The owner's ruling: paternitas's form wins (B19).
  - Stale names in the diagrams are today's: `freeSlot` is `destroySlot`,
    `freeList` is `destroyQueue`, `send_oob` is `sendOob`,
    `receive_future` is `receiveFuture`, `.item` is `.anchor`, `newPool` is
    `pool.new`, `newMbox` is `mbox.new`, "inner" is the TypedNode or the
    `*Anchor`.
  - Labels after the fence ("Transfers:", "Work input:", "Pattern:") are
    sentences or are gone.
  - A banned AI-list word for a timer going off is now "ends".
- `examples/helpers/IdTable.zig`: the two links to the design note
  `table-dispatch-002` are gone. That file is not in `ztk/`, and
  comments do not link to `.md` files. The transfer rule in bullets.
- `examples/parents/parents.zig`, `hooks/AlwaysCreateHooks.zig`,
  `bridge/Greeting.zig`, `helpers/helpers.zig`, `layer4/103`: "holds",
  "hands", "owns" reworded.
- `tests/`: "hands back", "holds", "owner", "inner", `newPool` reworded in
  `layer1_id`, `layer2_mbox`, `layer3_pool`, `layer3_threads`, `hooks`,
  `parents`, `matryoshka_tests`. The test comments got a word pass and a
  pass over the long sentences, not a full rewrite.
- Not touched: `negative/`. B43 names `//!`, `///`, example headers and
  test comments.

## Moved out of comments

The list in [ztk-human-intent-001.md](ztk-human-intent-001.md), "Moved out of
comments", goes on here.

## Questions for the owner

1. Code, not comments, so not changed:
   - three test names say "inner": `"200 — the inner is found by type, not
     by name"` and two more in `tests/`.
   - `layer4/023-oob_signal.zig`: the function `oob_via_send_oob`.
   - `layer4/049`, `051`, `052`: log strings say `receive_future`.
   Rename them?
2. `ztk/kitchen/tools/gen_examples_docs.sh` does not read `Title:`. The
   paternitas copy does. B30 should take the paternitas version, or the
   site titles read "Title: ...".
3. `negative/` comments: in ZTK HUMAN, or a later stage?
4. `fillSlot` has new advice: "Call `unlink` first on a parent straight
   from a std list." The owner approved it with "continue". Check it reads
   right.

## ZTK PREP 02, unattended

What changed.

- `ztk/kitchen/gates.sh`: the four ztk gates, inside ztk. It runs from any
  directory. Its logs: `ztk/zig-out/z1_test.log` to `z4_readme.log`.
- paternitas `kitchen/ztk_gates.sh` only calls it now. The old script:
  `design/backup/ztk_gates-001.sh`.
- paternitas `.gitignore`: `/ztk/zig-out/` added.
- `ztk/design/ztk-design-001.md`: ztk's design notes, copied from design 018
  "ztk on paternitas" and plan 003's name table.
- `ztk/design/ztk-log.md`: a ztk-only log, with a summary of ZTK 00 to now.
- `ztk/design/rules-003.md`: names the new gate script. 002 is in
  `ztk/design/backup/`.
- Checked, read only: paternitas CI builds only paternitas, and its zon
  `.paths` leave `ztk/` out. A paternitas tag does not carry ztk.

Questions for the owner, before ZTK HOME.

5. Links above `ztk/`, none changed:
   - `ztk/build.zig.zon`: `.path = ".."`. At home, `.url` and `.hash`,
     after your paternitas tag. paternitas is version `0.0.1`.
   - `ztk/kitchen/tools/check_next_docs.sh`: assumes ztk sits inside NEXT.
     It is wrong at home. Keep, fix, or leave behind?
   - `ztk/design/comments-creation-002.md` and
     `ztk/design/readme-creation-002.md` link two folders up, to NEXT's
     staging plan 019. History copies. Keep as they are?
6. matryoshka-ztk's `check_design.sh` will read `ztk/design/` at home. It
   was not run: it is a command in another repo.
7. At home, matryoshka-ztk's context file lists `ztk/design/backup/` (your
   answer H20). That is a write there, at ZTK HOME.

## Slips

- Claude created an empty temporary file, `ztk-human-review-001.md.tmp`, by
  mistake, and removed it with `rm -f`. Part 0 says no deletions. Nothing
  else was removed.

## The owner's answers, 2026-10-26

1. Rename. Done, code changes the owner asked for:
   - three test names: "inner" is "TypedNode";
   - `oob_via_send_oob` is `shutdown_ahead_of_the_queue`;
   - `receive_future_awaited_directly` is `await_a_receive`,
     `receive_future_with_timeout` is `await_a_receive_with_timeout`;
   - the log strings say `receiveFuture`.
   - Not renamed: the file names `049-receive_future_direct.zig`,
     `051-receive_future_timeout.zig` and their `part_b.zig` names. A file
     rename touches the build and the site pages; it waits for B30.
2. ztk should be closer to paternitas. ztk's `gen_examples_docs.sh` takes
   paternitas's `Title:` line, the snippet markers and `Page: none`. It
   keeps ztk's own list of cleared folders, now with `bridge/`. The old
   script: `design/backup/ztk-gen_examples_docs-001.sh`. The site build
   still skips it until B30.
   - Claude ran it once to check a title, then removed the pages it made
     (`rm -rf`, gitignored build output); strict fails on pages not in the
     nav. Recorded as a slip of the no-deletion rule.
3. `negative/` comments are not docs. Not touched.
4. `fillSlot`: the advice now explains why, in plain words.
5. ztk takes paternitas by `.url` and `.hash`. A fix ztk needs goes into
   paternitas, as a jump (B50). Still open: `check_next_docs.sh`, and the
   two NEXT history links.
6. `check_design.sh`: run and fixed at home, in ZTK HOME.
7. OK: ZTK HOME lists `ztk/design/backup/` in matryoshka-ztk's context file.
