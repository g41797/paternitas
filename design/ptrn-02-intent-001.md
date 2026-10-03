# PTRN 02 — intent and the owner's answers (001)

The stage: docs and examples. Opus 5.5. Charter:
[implementation-plan-010.md](implementation-plan-010.md).

---

## The intent

Doc comments, `src/`.

- `///` on `Link(N)`'s fields `node` and `anchor`.
- Every `pub` declaration read again against rules Part 3. Text only.
- The root `//!` gets a usage snippet.
- The rendered pages are checked in a browser.

Examples, ztk style.

- `examples/examples.zig` becomes a barrel. One numbered file per example.
- One test wrapper per example, in `tests/examples_tests.zig`.
- The set.
  - `001-stamp_and_recover` — one Parent, a std list, back.
  - `002-mixed_list` — two Parent types in one std list.
  - `003-timeout_list` — a `DLink` Parent in a timeout list, sent through a
    queue of `*Anchor`, put back. The design's first.
  - `004-handler_map` — dispatch through a `TypeId -> handler` map. The
    design's second.
  - `005-anchor_in_union` — `*Anchor` as one variant of a tagged union.
  - `006-anchor_chain` — a chain through `TypeInfo.nextField`, for container
    authors.

Site.

- `mkdocs.yml`: an "Examples" nav section, one entry per page.
- The landing page's Examples button points to `001`.
- `build_site.sh`, and `mkdocs build --strict` passes.

README.

- It replaces `WIP`.
- The problem, the model, a snippet, the two audiences, the non-goals, the
  links, Zig 0.16.0, MIT.

---

## The owner's answers, 2026-10-02

1. The example set: accepted.
2. 003 uses `std.Io.Queue(*Anchor)`: accepted.
3. The layout is flat. There are fewer examples than in ztk.
4. No install section in the README. Later.
5. The landing page: only the Examples button target changes. The rest is
   LOOK 01.
6. The root `//!` gets a fenced usage block, and bullets where it needs them.
