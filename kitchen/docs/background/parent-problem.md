# The Parent problem

An intrusive, type-erased list gives you a Node.

You need the struct around it.

---

## Parent is Zig's word

Paternitas did not invent it.

- Zig calls the struct that contains a field the field's parent.
- `@fieldParentPtr` goes from the field to its parent.
- `Job` is the Parent of its `node` field.

The list gives you a Node. You need its Parent.

??? question "NAQ: Why the word Parent?"  
    Zig already uses it, in `@fieldParentPtr`.

    Paternitas is Latin for "fatherhood". It finds the Parent of a Node.

    [Name and origin](../reference/about.md) explains the name.

---

## The footgun

You keep a `Message` and a `Job` in one `std.DoublyLinkedList`:

```zig
--8<-- "examples/before_paternitas.zig:structs"
```

```zig
--8<-- "examples/before_paternitas.zig:list"
```

You pop a Node.

- Is it in a Message, or in a Job?
- The list does not know.
- `@fieldParentPtr` gives you whatever type you ask for.

The right guess works:

```zig
--8<-- "examples/before_paternitas.zig:recover"
```

Now guess wrong. The first Node is in a `Message`. You ask for a `Job`.

This line is written text, not working code:

```text
const job: *Job = @fieldParentPtr("node", first); // first is in a Message
```

- It compiles.
- It runs.
- `job` points into a Message.
- A read gets another struct's bytes.
- A write breaks another struct: its mutex, its pointers, its length.
- The crash comes later, somewhere else. Or never: just wrong data.

One wrong guess in a large system costs days of debugging.

Why no working code shows it:

- The Zig 0.16.0 langref says so, under `@fieldParentPtr`.
- When the pointer is not that field of the result type, and the result type has ill-defined layout, it is unchecked Illegal Behavior.
- A plain struct, as `Job`, has ill-defined layout.
- Unchecked means no build mode catches it.
- Illegal Behavior means the optimizer may assume it never happens. So no test can say what it does.
- In practice it subtracts an offset. The program runs on with wrong data, or fails later.

---

## The same with Paternitas

A wrong type gives null:

```zig
--8<-- "examples/002-mixed_list.zig:recover"
```

Or, when another type is a bug, a panic that names both types:

```text
mustParentFromAnchor: asked for must_parent_from_anchor.Msg, found must_parent_from_anchor.Job
```

`mustParentFromNode` prints the same kind of message.

Both panic in every build mode.

---

## Side by side

| | plain std list | with Paternitas |
|---|---|---|
| a wrong type | compiles, runs, reads garbage | null, or a panic |
| the panic says | nothing | "asked for Job, found Message" |
| where the bug shows | later, somewhere else | at the call that got it wrong |
| release builds | no check | the same check, in every build mode |
| several types in one list | you track the type yourself | you ask: "is this a Message?" |
| the field name | in every `@fieldParentPtr("node", n)` | once, in the struct |
| the cost | none | one pointer compare per check |
| allocation for the link | none | none |
| copy of your struct | no | no |
| your list | std | still std, with the same calls |
| your memory | yours | still yours. Nothing is allocated |
| lifetime checking | no | no |
| locking | no | no |

The important row is the first one: a wrong type.

That is what Paternitas is here to fix.

---

## Where this came from

The Ziggit post [New LinkedList API footgun](https://ziggit.dev/t/new-linkedlist-api-footgun/10853) started it.
