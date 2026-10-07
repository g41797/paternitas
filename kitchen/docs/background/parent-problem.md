# Are you my Parent?

An intrusive, type-erased list gives you a Node.

You need the struct around it.

---

## When the trouble starts

One list, one struct type: no trouble. You know what is inside.

It changes when the list becomes part of a real system:

- A mailbox grows.
- A scheduler gets more job types.
- A dispatcher starts passing different structs through the same list.

Then you pop a Node.

**What struct is this Node inside?**

The std list does not know.

---

## Parent is Zig's word

*Paternitas* did not invent it.

- Zig calls the struct that contains a field the field's parent.
- `@fieldParentPtr` goes from the field to its parent.
- `Job` is the Parent of its `node` field.

The list gives you a Node. You need its Parent.

??? question "NAQ: Why the word Parent?"  
    Zig already uses it, in `@fieldParentPtr`.

    *Paternitas* only borrows it.

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

??? question "NAQ: Why no working code shows it?"  
    The Zig 0.16.0 langref says so, under `@fieldParentPtr`.

    - When the pointer is not that field of the result type, and the result type has ill-defined layout, it is unchecked Illegal Behavior.
    - A plain struct, as `Job`, has ill-defined layout.
    - Unchecked means no build mode catches it.
    - Illegal Behavior means the optimizer may assume it never happens. So no test can say what it does.
    - In practice it subtracts an offset. The program runs on with wrong data, or fails later.

---

## The same with *Paternitas*

*Paternitas* gives you an answer.

A wrong type gives null:

```zig
--8<-- "examples/002-mixed_list.zig:recover"
```

Or, when another type is a bug, a panic that names both types:

```text
mustParentFromAnchor: asked for must_parent_from_anchor.Msg, found must_parent_from_anchor.Job
```

`mustParentFromNode` prints the same kind of message.

- Both panic in every build mode.
- No new container. No allocation. No lock.
- Your std list stays your std list.

??? question "NAQ: Why a Latin name?"  
    *Paternitas* is Latin for "fatherhood".

    It finds the Parent of a Node.

    The motto on the logo, *Agnitio paternitatis*, is "the recognition of fatherhood".

    [Name and origin](../reference/about.md) has the rest.

---

## Side by side

| | plain std list | with *Paternitas* |
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

That is what *Paternitas* is here to fix.

---

## Do you need it?

**No**, when each list carries one struct type, and you know which one.

- Plain `@fieldParentPtr` is enough.

**Yes**, when:

- one list deliberately mixes struct types;
- the code handling the list should not know every struct type;
- the Node comes from somewhere else;
- you do not want to trust every `@fieldParentPtr` call by hand;
- a bad cast would turn into a long debugging session.

The last one is a perfectly respectable reason.

*Paternitas* is for the moment when "I know what this is" becomes "I hope I know what this is".

Intrusive is not the problem.

The unknown type is the problem.

---

## Where this came from

The Ziggit post [New LinkedList API footgun](https://ziggit.dev/t/new-linkedlist-api-footgun/10853) started it.
