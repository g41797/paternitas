# Your own container

Most users can skip this page.

It is for you when you write the container itself: a stack, a pool, a queue of mixed types.

---

## When you need it

You may not need it.

- One std list of many struct types? `Typed(P)` covers it.
- A queue or a map? An `Any` in a std container covers it.

You need it when:

- your container keeps structs of many types, and does not know them;
- it needs no extra memory per item;
- or you pass a struct to code that knows nothing of *Paternitas*.

??? question "NAQ: Can I use my own list?"  
    Yes. This page is about that.

    Your list keeps `*Anchor`s, and gets each struct back with a type check.

---

## The Anchor

An `Anchor` is a one-word handle to a struct with a TypedNode.

- Every TypedNode holds one Anchor.
- `setTypeId` writes the struct's type id into it.
- You never make an Anchor. You only pass `*Anchor`.

In and out:

| call | what it does |
|---|---|
| `TypedJob.anchor(&job)` | gives you the `*Anchor` of `job` |
| `TypedJob.parentFromAnchor(a)` | checks the type, and gives you `*Job` or null |
| `TypedJob.mustParentFromAnchor(a)` | the same, but panics for another type |

`*Node` carries any struct with the same Node kind.

`*Anchor` carries any struct.

Both turn back into your struct with a type check.

---

## What `anchor.info()` gives you

`anchor.info()` gives the `TypeInfo` of the struct's type.

It gives null when `setTypeId` was never called.

| call | what you get |
|---|---|
| `info.nextField(a)` | a pointer-sized word to chain through: the Node's `next` field |
| `info.node(a, N)` | the std Node, as type `N` |
| `info.parent(a)` | the struct's address, with no type |
| `info.toAny(a)` | an `Any` |

`info.node` panics, in every build mode, when `N` is the wrong Node kind.

```text
TypeInfo.node: wrong_node_kind.Msg has another Node kind
```

---

## A stack of mixed types

This stack keeps `*Anchor`s. It allocates nothing.

It chains them through each item's `next` field:

```zig
--8<-- "examples/006-anchor_chain.zig:chain"
```

```zig
--8<-- "examples/006-anchor_chain.zig:stack"
```

Push with `anchor`. Pop, and get the struct back with `parentFromAnchor`:

```zig
--8<-- "examples/006-anchor_chain.zig:use"
```

`Message` has a `SinglyTypedNode`. `Job` has a `DoublyTypedNode`.

One stack carries both.

The full program: [Your own stack](../examples/006-anchor_chain.md){target="_blank" rel="noopener"}.

---

## The rules

- Call `setTypeId` on each struct before it enters your container.
- A std list uses the same `next` word. A struct MUST NOT be in your container and in a std list at the same time.
- Your container owns the meaning of that word. *Paternitas* never reads or writes it.
- The struct MUST stay alive while your container keeps its Anchor.
- *Paternitas* locks nothing. Guard a shared container yourself.

The full set of calls is in the [API docs](../apidocs/index.html){target="_blank" rel="noopener"}, under `Anchor` and `container`.
