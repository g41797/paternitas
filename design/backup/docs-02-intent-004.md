# DOCS 02 — intent (004)

The site's opening pages, in a new order. The owner named it, 2026-10-07.

- The plan: [implementation-plan-019.md](implementation-plan-019.md), "DOCS 02".
- The rules: [rules-014.md](rules-014.md). Part 0, "The README and the site":
  text cut from a page stays on the site.
- The DOCS 01 plan: [docs-01-intent-009.md](docs-01-intent-009.md).
- The README is not touched. Owner's ruling.
- The drafts before: `design/backup/docs-02-intent-001.md`, `design/backup/docs-02-intent-002.md`,
  `design/backup/docs-02-intent-003.md`.

---

## Change from 003

- The group name: "How to prevent the linked list footgun". The owner's
  words, with "the" added. "The footgun, fixed by Paternitas" sounded too
  official. 2026-10-07.
- The owner approved this intent: "go".
- Done: steps 1 to 8 of "Order of work". Step 9, the owner's look, is open.
- NAQ titles keep plain "Paternitas": a details title is plain text, and
  asterisks would show.

## Change from 002, kept

The owner's answers to 002, 2026-10-07:

- The first page: "In short". Yes.
- The joke title: "Are you my Parent?". Yes.
- "Typical examples": the homes found are enough.
- The italic scope: prose and headings, everywhere on the site. OK.
- The group name: the footgun, and *Paternitas* as the fix. Wording still
  open, see "The nav".
- The problem and the fix cannot be told before intrusive and type-erased
  are explained.
  - So the footgun is told in one place: "Are you my Parent?", after the
    two word pages.
  - "In short" says what *Paternitas* gives, at a high level. Nothing that
    needs the problem first.
  - The bullets "a wrong type gives null, or a panic" and "it checks in
    every build mode" leave "In short". They are already on "Are you my
    Parent?", in "The same with *Paternitas*" and its table.

## Change from 001, kept

The owner's second answer, 2026-10-07:

- No Background group. No Introduction as it was.
- One nav group, named for the footgun: its problem and its solution.
  - A short page: what *Paternitas* gives.
  - Intrusive lists.
  - Type-erased lists.
  - A joke page: "Are you my Parent?", the problem and the solution.
- Then Guides, Examples, Reference, API docs, as they are.
- The three words come first, before any page uses them:
  intrusive, type-erased, Parent, in that order.
- MUST, wider: every fact in the current README and in README-004, the
  770-line one, stays on the site in some form. The same holds for every
  fact on the current site pages. "Every fact kept" below checks it.

---

## Why

The owner's look at the site, 2026-10-07:

- The reader meets "intrusive" and "type-erased" before they know why they
  should care.
- The footgun, the reason for the library, comes third, in Background.
- *Paternitas* shows up before the reader knows what it does: "before
  Paternitas", "NAQ: Does Paternitas allocate?" on the intrusive page.
- "NAQ: Why the word Parent?" mixes Zig's word and the library's name.

---

## The owner's answers

1. The footgun first.
2. The Introduction title: "How to prevent the linked list footgun". The nav
   label is shorter.
3. The Parent problem gets a joke title, with the solution in it.
4. The Introduction: two lines, and the NAQ.
5. The NAQ split: OK.
6. Italic *Paternitas* when possible.
7. A new stage: DOCS 02.
8. The README: not touched.
9. Background may be removed, as a nav group. Its pages come next, after the
   Introduction.

---

## The nav

Before:

```text
Home
Introduction
Background
  Intrusive lists
  Type-erased lists
  The Parent problem
Guides ...
```

After:

```text
Home
How to prevent the linked list footgun   group
  In short                       introduction.md
  Intrusive lists                background/intrusive.md
  Type-erased lists              background/type-erased.md
  Are you my Parent?             background/parent-problem.md
Guides ...                       unchanged
Examples ...                     unchanged
Reference ...                    unchanged
API docs                         unchanged
```

- The files keep their paths. No URL changes, no broken links.
- The hero logo still opens `introduction/`, "In short".

Wording of the group: "How to prevent the linked list footgun". The
owner's words.

Wording of the first page, proposed:

- "In short". Recommended.
- Other options:
  - "What you get";
  - "At a glance".

The joke title, proposed:

- "Are you my Parent?". The Node asks it, as the baby bird asks in the
  children's book "Are You My Mother?".
- Nav label and page title are the same.

---

## `introduction` — "In short"

What it says:

- *Paternitas* makes Zig's intrusive, type-erased lists safer.
- It gives any struct a runtime type id. No list, no Node.
- The short achievements, the ones that need no problem first:
  - no new container, no allocation, no lock;
  - your std list stays your std list.
- One line: the next pages explain "intrusive" and "type-erased", then the
  footgun and its fix.
- No problem, no fix, no code on this page.
- "What's NAQ?", the NAQ block, at the end.

What leaves, and where it goes (MUST):

| text | goes to |
|---|---|
| "Intrusive and type-erased sound scary? Do not leave." | becomes the one line: the next pages explain both words |
| the hook: "You probably do not need it…", the mailbox, "What struct is this Node inside?" | "Are you my Parent?", as its opening |
| "Do you need it?" | "Are you my Parent?", at the end |
| "a wrong type gives null, or a panic…", "it checks in every build mode" | "Are you my Parent?", "The same with *Paternitas*" and its table |
| "Where next", the table | dropped. Navigation only. Its targets are in the nav, in `guides/choose` and in Material's footer |

---

## `background/intrusive` — "Intrusive lists"

- The first of the three words. The text stays.
- "In Zig, before Paternitas:" becomes "In Zig, with a plain std list:".
- "NAQ: Does Paternitas allocate?" stays. The reader met *Paternitas* on
  "In short".

## `background/type-erased` — "Type-erased lists"

- The second word. The text stays.

## `background/parent-problem` — "Are you my Parent?"

The third word, then the problem and the solution.

The order on the page:

1. The hook, from `introduction`. Plain words: a std list, a Node, your
   struct.
2. "Parent is Zig's word". The NAQ "Why the word Parent?" answers only that:
   Zig's word, from `@fieldParentPtr`.
3. "The footgun": the wrong guess. Unchanged.
   - The langref text ("unchecked Illegal Behavior…") goes into a NAQ on
     the same page: "NAQ: Why no working code shows it?".
4. "The same with *Paternitas*".
   - A new NAQ right after: "NAQ: Why a Latin name?".
   - The answer: *Paternitas* is Latin for "fatherhood". It finds the
     Parent of a Node. *Agnitio paternitatis*, the motto on the logo.
     `reference/about`, "Name and origin", has the rest.
5. "Side by side": the table. Unchanged.
6. "Do you need it?", from `introduction`.
7. "Where this came from". Unchanged.

---

## Every fact kept

The check, before the stage closes. Two sources:

- README-004, `design/backup/README-004.md`: each section.
- The site pages as they are now: each section of the four pages above.

For each section, the page that holds its facts after DOCS 02. A section
with no home gets one, in this stage.

Already known, from README 02 iteration 1 (STATUS-LOG, 2026-10-07):

- every README-004 section has a site page;
- nothing had to be added.

Still to check: "Typical examples" in README-004's "Do I need it?". It is
not on the site word for word.

- The mailbox, the scheduler, the dispatcher: the hook.
- A generic intrusive container: `guides/containers`, "When you need it".
- Infrastructure that passes structs it does not know:
  `background/type-erased`, "The infrastructure stays fixed".
- If the owner wants the list itself, it goes into "Do you need it?" on
  "Are you my Parent?".

The full table goes into STATUS-LOG when the stage closes.

---

## Italic *Paternitas*

- In prose and in headings, on every site page.
- Not in code, file names, paths, link targets, the nav, the API docs, the
  logo.
- Not in the README. Owner's ruling.

---

## Links to fix

- `reference/terms`: the "Parent" row links to the page by path. The path
  does not change. The link text "The Parent problem" becomes "Are you my
  Parent?".
- `index`: the hero links to `introduction/`. No change.
- Every other link uses paths, which do not change.

---

## Order of work

1. The nav in `kitchen/mkdocs.yml`.
2. `introduction`.
3. `background/intrusive`.
4. `background/parent-problem`.
5. Italic *Paternitas*, page by page.
6. Links: `reference/terms`.
7. "Every fact kept": the check, and any page text it needs.
8. `mkdocs build --strict`, the six gates, headless Chrome on the changed
   pages.
9. The owner looks at the preview.

---

## Open

1. The owner looks at the preview.
