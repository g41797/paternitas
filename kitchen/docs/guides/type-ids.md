# Type ids on their own

No list here.

No Node.

Just your struct.

---

## Why a type id

Zig's `type` lives only at compile time.

At run time, a value of unknown type is just an address.

Callbacks, queues and handler maps pass such addresses around. Each one needs to know what is behind the address.

Paternitas gives any struct a runtime type id.

- `Typed(P)` takes any struct.
- The struct needs no TypedNode.

---

## The four calls

| call | what it does |
|---|---|
| `TypedPoint.typeId()` | gives the type id of `Point` |
| `TypedPoint.isId(id)` | tells if `id` is the type id of `Point` |
| `TypedPoint.toAny(&point)` | packs the address and the type id |
| `TypedPoint.fromAny(any)` | checks the type id, and gives you `*Point` or null |

No allocation.

No registry.

No init call.

---

## A handler map, no list

Two structs, with no TypedNode:

```zig
--8<-- "examples/007-type_id_without_node.zig:types"
```

Register a handler per type. Send the structs as `Any`s:

```zig
--8<-- "examples/007-type_id_without_node.zig:send"
```

`Empty` has no fields. It still gets its own type id.

It has no handler, so the dispatch counts it as unhandled.

Ask about the type, without turning it back:

```zig
--8<-- "examples/007-type_id_without_node.zig:isid"
```

The full program is [example 007](../examples/007-type_id_without_node.md){target="_blank" rel="noopener"}.

---

## The rules

- Structs only. Wrap any other value in a struct.
- The struct has no room for the type id. It travels next to the pointer, in `Any`.
- A bare pointer carries no type id.
- The type id is for one running program. Do not save it or send it.

??? question "NAQ: Can I save or send a type id?"  
    No.

    It is valid only inside one running program.

    Another run, or another program, may give other values.

??? question "NAQ: What about a value that is not a struct?"  
    Wrap it in a struct.

    `const Count = struct { value: u64 };` is enough.

    `Typed(Count)` then gives it a type id.

---

## What the compiler stops

A list call needs a TypedNode.

A plain std Node is not one:

```zig
--8<-- "negative/compile/bare_node.zig"
```

```text
bare_node.BareNode: no TypedNode, so it has only typeId, isId, toAny and fromAny
```

`Typed` takes structs only:

```zig
--8<-- "negative/compile/not_struct.zig"
```

```text
u32: not a struct, and Typed takes structs only
```

Each message names the type.
