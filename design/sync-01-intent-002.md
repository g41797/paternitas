# SYNC 01 — intent (002)

The comments in `src/`, `examples/` and `negative/` follow the README and
the site. The owner named it, 2026-10-07.

- The plan: [implementation-plan-022.md](implementation-plan-022.md),
  "SYNC 01".
- The rules: [rules-014.md](rules-014.md). Part 0, "The README and the site":
  text cut from a comment stays on the site.

---

## The owner's rulings, 2026-10-07

1. The README and the site are the truth. The comments follow them.
2. The module comment of `src/paternitas.zig` shrinks.
3. The first line of each example header is its site title.
4. g4 checks `src/`, `examples/` and `negative/` too.

---

## Why

- The comments become the API pages, `apidocs/`. The hero pill opens them.
- The module comment of `src/paternitas.zig` was 194 lines: a third manual,
  next to the README and the site.
- It drifted. "marks", a link to the README for the migration, an example
  named by its number.

---

## The inventory

Read only, before any edit.

| file | line | drift | fix |
|---|---|---|---|
| `src/paternitas.zig` | 4-197 | the module comment repeats the site | shrink, see below |
| `src/paternitas.zig` | 56 | "The full program and the migration are in the README" | the site has them now |
| `src/paternitas.zig` | 61 | "`setTypeId(&p)` marks the struct as that type" | "sets the struct's type id" |
| `src/paternitas.zig` | 195 | "A struct marked by `setTypeId` in the library" | "whose type id was set in the library" |
| `src/paternitas.zig` | 280 | "Marks `p` as a value of type `P`." | "Sets the type id of `p`." |
| `src/paternitas.zig` | 615 | "A struct marked by `setTypeId` in the library" | "whose type id was set in the library" |
| `src/container.zig` | 51 | "The full program is example 006, "Your own stack"." | the title only |

Clean, no change:

- The example headers. Each opens with `Title:` and the site title.
  Ruling 3 holds already.
- The inline comments in the examples.
- The `negative/` headers.
- The `///` comments on each `pub` declaration, apart from the two above.
- The module comment of `src/container.zig`, apart from line 51. It is
  for container authors, and stays at its length.

---

## The new module comment

It keeps:

- the first lines: the problem and the check;
- what a wrong type gives, every build mode, the std list stays;
- the four calls and `mustParentFromNode`;
- the "after" code;
- the setTypeId rule, in three lines;
- one line each for `Any`, `typeId` and `container`;
- a link to the site, with the page names.

It cuts, and the site holds each:

| cut | the site page |
|---|---|
| "Do you need it?", the typical places | "Are you my Parent?": "When the trouble starts", "Do you need it?"; "Queues, maps, union fields"; "Your own container" |
| "Three words first" | "Intrusive lists", "Type-erased lists", "Stuck on a word?" |
| the Messages and Jobs story | "Are you my Parent?": "The footgun" |
| "Typical use": the diagram, before, the five steps, the compiler | "Migrate your code" |
| "A small but important rule", in full | "The setTypeId rule" |
| "Passing a struct through type-erased code", the handler code | "Queues, maps, union fields"; "Handler map" |
| "Writing a container" | "Your own container" |
| "Limits" | "Limits" |

The site link: `https://g41797.github.io/paternitas/`, the GitHub Pages
address of the repo. Not checked live: CI and Pages are an open item.

---

## g4

- Check 2 reads `negative/` too.
- A new check 4: the old wording. `mark`, `marks`, `marked`, `marking` in
  `src/`, `examples/`, `negative/`, `tests/`, the README and the site
  pages. Not in `design/`: the log and the old docs record it.

---

## Order of work

1. `src/paternitas.zig`: the module comment, then lines 280 and 615.
2. `src/container.zig`: line 51.
3. g4: `negative/`, check 4.
4. The six gates. The strict site build. The API pages, one look.
5. STATUS.md, STATUS-LOG.md.

---

## The owner's read, 2026-10-07

The owner read the new module comment on the preview site. Three notes.

1. Lines 8-10 sound like AI. Write them as a person would:
   "Plain `@fieldParentPtr` trusts that you guessed the type correctly."
   "Paternitas adds a type id to the Node. Now the guess is checked."
2. Line 466, "An id for a struct type.": it is a runtime id. Say so.
3. Line 122, "It also gets the list calls.": not clear at all.

The proposed text. It takes the README's words: "a wrong answer is still a
pointer", "Paternitas puts a type id next to the Node", and the site's "a
runtime id for a struct type".

Note 1, lines 8-10:

```zig
//! `@fieldParentPtr` gives you back whatever type you ask for.
//! Ask for the wrong one, and you still get a pointer.
//!
//! Paternitas puts a type id next to the Node, and checks it.
```

Note 2, line 466:

```zig
/// A runtime id for a struct type.
```

Note 3, lines 120-122:

```zig
/// Every struct gets the id calls: `typeId`, `isId`, `toAny`, `fromAny`.
///
/// A struct with a TypedNode field is a Parent. It can go in a list.
///
/// Only a Parent gets the list calls: `setTypeId`, `node`, `anchor`, `is`,
/// and the `parentFrom...` calls.
```

Comments only. Nothing is cut, so no site page changes.

Order of work: the three edits, the six gates, the strict site build, a
look at the API pages, STATUS.md, STATUS-LOG.md.

Superseded by the second round, below.

---

## The owner's second read, 2026-10-07

1. "Paternitas puts a type id next to the Node, and checks it" is how it
   works, not what it does for you. Say what it does.
2. "id calls" and "list calls" mean nothing to the reader. Use more words
   if needed. Plain English, with snippets from the examples.
3. Note 2, "A runtime id for a struct type.": no comment. It stands.

The proposed text.

Note 1, the module comment, lines 6-15:

```zig
//! An intrusive list gives you a Node, not your struct.
//!
//! To get your struct back, you use `@fieldParentPtr` and name the type.
//! If you name the wrong type, nothing stops you. You get a pointer to the
//! wrong thing, and the bug may show up much later.
//!
//! Paternitas tells you whether the Node really is in the struct you ask for.
//!
//! - If it is not, you get null.
//! - The `must` calls panic instead. The panic names both types.
//! - This works in every build mode.
//! - Your list is still the std list. No allocator. No lock.
```

Note 3, the doc comment of `Typed`, lines 112-128. The rules after it stay.
The snippets are from example 001 (`define`, `create`, `list`) and example
007 (`types`, `send`), shortened.

```zig
/// Makes the helper for one struct type. Declare it once per type.
///
/// What the helper can do depends on your struct.
///
/// If your struct has a TypedNode field, it can live in a std list. The
/// helper puts it in the list, and gets it back from a Node:
///
/// ```zig
/// const Message = struct {
///     text: []const u8,
///     tnode: paternitas.DoublyTypedNode = .{},
/// };
/// const TypedMessage = paternitas.Typed(Message);
///
/// var message: Message = .{ .text = "hello" };
/// TypedMessage.setTypeId(&message);
/// list.append(TypedMessage.node(&message));
///
/// const m: ?*Message = TypedMessage.parentFromNode(list.popFirst().?);
/// ```
///
/// `parentFromNode` gives you your struct only if the Node really is in a
/// `Message`. Otherwise it gives null. You never write `@fieldParentPtr` or
/// the field's name. Such a struct is called a Parent.
///
/// If your struct has no TypedNode field, it cannot go in a list. The
/// helper still gives it a type id. So you can pass it through code that
/// does not know its type, and get it back safely:
///
/// ```zig
/// const Point = struct { x: i32, y: i32 };
/// const TypedPoint = paternitas.Typed(Point);
///
/// var point: Point = .{ .x = 3, .y = 4 };
/// const any: paternitas.Any = TypedPoint.toAny(&point);
///
/// const p: ?*Point = TypedPoint.fromAny(any); // your Point, or null
/// ```
///
/// A struct with a TypedNode can do this too.
```

Cut from the old text: "Every struct gets the id calls ...", "It also gets
the list calls", and the five bullets under it. Their facts are in the new
text. The site has them too: "Migrate your code" and "Type ids, listless
and nodeless".

Done, 2026-10-07, with the owner's go. STATUS-LOG.md has the account.
