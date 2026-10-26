# Cross-repo jumps — ztk and paternitas (001), a copy

**This is a copy.** The source is in matryoshka-ztk:
`/home/g41797/dev/root/github.com/g41797/matryoshka-ztk/design/cross-repo-001.md`.
If the two differ, the source is right.

The owner's rulings, 2026-10-26. Written in ZTK HOME, the first jump.

## When to jump

- A ztk stage needs a change in paternitas: a fix, a new call, a message.
- Or a paternitas stage needs ztk to follow a paternitas change.
- The owner names the jump, as any stage. A document never starts one.
- A named jump stage is permission to write and run commands in the other
  repo.
- One session, one repo. A jump is a new stage, with its own continue
  prompt.

## The handoff note

The stopping side writes it in its STATUS, "Cross-repo".

- What is needed, and why.
- The failing test, or the code that shows the need.
- The state of the gates when it stopped.

Each repo's STATUS has a short "Cross-repo" section: the open handoffs.

## The paternitas side

- The stage works by paternitas's own rules and gates.
- It ends with a new version and a tag. Both are the owner's steps.
  - The `build.zig.zon` version matches the tag.

## The return

- ztk's `build.zig.zon` gets the new `.url` and `.hash`.
- All ztk gates pass.
- The returning stage closes the handoff note.

## Local work without a tag

- First, check Zig 0.16's override of a dependency by a local folder.
- If it does not fit: a temporary `.path`, marked, and a gate that fails
  if it is left at close.
