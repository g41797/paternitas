# Migrate your code

You have a std list. You want the type check.

The change is small and boring.

- You find and replace, five times.
- There is no design to think about.
- The list itself does not change.

---

## Before and after

The std Node moves into a TypedNode.

The TypedNode holds the Node and the type id.

```text
before                       after
Message                      Message
+--------------------+       +---------------------------+
| text               |       | text                      |
| node  <-- the list |       | tnode: DoublyTypedNode    |
+--------------------+       | +-----------------------+ |
                             | | node   <-- the list   | |
                             | | type id               | |
                             | +-----------------------+ |
                             +---------------------------+
```

??? question "NAQ: Why not keep the type id in the std Node?"  
    The std Node belongs to std. *Paternitas* does not change std.

    So the TypedNode holds the std Node, and the type id next to it.

    Your list still links plain std Nodes.

Before, with the plain std list:

```zig
--8<-- "examples/before_paternitas.zig:structs"
```

```zig
--8<-- "examples/before_paternitas.zig:list"
```

```zig
--8<-- "examples/before_paternitas.zig:recover"
```

After, with *Paternitas*:

```zig
--8<-- "examples/001-set_type_id_and_recover.zig:define"
```

```zig
--8<-- "examples/001-set_type_id_and_recover.zig:create"
```

```zig
--8<-- "examples/001-set_type_id_and_recover.zig:list"
```

The full program is [example 001](../examples/001-set_type_id_and_recover.md){target="_blank" rel="noopener"}.

??? question "NAQ: Does my std list change?"  
    No.

    It is the same std type, with the same calls.

    Only the field in your struct changes.

---

## The five steps

Do them for each struct that goes into the list.

| step | find | replace with |
|---|---|---|
| 1 | `std.DoublyLinkedList.Node` | `paternitas.DoublyTypedNode` |
| 1 | `std.SinglyLinkedList.Node` | `paternitas.SinglyTypedNode` |
| 2 | the end of the struct, `};` | `};`, then `const TypedMessage = paternitas.Typed(Message);` |
| 3 | after `var message: Message = .{ ... };` | add `TypedMessage.setTypeId(&message);` |
| 4 | `&message.node` | `TypedMessage.node(&message)` |
| 5 | `@fieldParentPtr("node", n)` | `TypedMessage.parentFromNode(n)`, or `TypedMessage.mustParentFromNode(n)` |

`Job` gets the same five steps, with `TypedJob`.

Step 1 keeps the field name, or changes it. Both are fine.

Step 3 has one more place.

- Your code may write the whole struct somewhere, as a reset.
- Add `setTypeId` right after that write too.
- [The setTypeId rule](set-type-id.md) says when to call it.

---

## What the compiler finds

The compiler stops at each place you missed in steps 4 and 5.

- `&message.node` no longer exists. The field is a TypedNode now.
- `@fieldParentPtr("node", n)` no longer matches the field.

It cannot find a missed step 3.

- `parentFromNode` gives null for that struct.
- `mustParentFromNode` panics, in every build mode.
- The panic says what it found: `<no type>`.

```text
mustParentFromNode: asked for must_parent_from_node.Msg, found <no type>
```

That panic comes from this program:

```zig
--8<-- "negative/panic/must_parent_from_node.zig"
```

When you see `<no type>`, add `setTypeId` right after that struct is created.

---

## The four calls

You use these most of the time.

| call | what it does |
|---|---|
| `paternitas.Typed(Message)` | makes the helper for `Message` |
| `TypedMessage.setTypeId(&message)` | marks the value as a `Message` |
| `TypedMessage.node(&message)` | gives the Node to the std list |
| `TypedMessage.parentFromNode(node)` | checks the Node and gives you `*Message`, or null |

??? question "NAQ: What does a check cost?"  
    One pointer compare.

There is a fifth call for one case.

- `TypedMessage.mustParentFromNode(node)` gives you `*Message`, or panics.
- Use it when another type would be a bug.
- It panics in every build mode.
- The panic names both types.

??? question "NAQ: Does it check in ReleaseFast?"  
    Yes.

    The type check works in every build mode.

    The `must` calls panic in every build mode too.

Several types in one list? Use `parentFromNode`, and ask each type in turn.

[Several types in one list](mixed-list.md) shows how.

---

## Singly or doubly linked?

Use the typed Node that matches your list.

| your list | the field in your struct |
|---|---|
| `std.SinglyLinkedList` | `tnode: paternitas.SinglyTypedNode = .{},` |
| `std.DoublyLinkedList` | `tnode: paternitas.DoublyTypedNode = .{},` |

`STNode` and `DTNode` are short names for the same two types.

The field name does not matter.

- `node`, `tnode`, `link`. All are fine.
- The field can be anywhere in the struct.
- *Paternitas* finds the field by its type.

Do not touch the fields inside the TypedNode. Use the calls.

One struct has one TypedNode.

A second one is a compile error:

```zig
--8<-- "negative/compile/two_typed_nodes.zig"
```

```text
two_typed_nodes.TwoTypedNodes: more than one TypedNode, and at most one is allowed
```

---

## What `Typed(P)` does for you

`P` is your struct. `Typed(P)` is its helper.

You declare it once, right after the struct.

It does the housekeeping:

- It finds the TypedNode field in your struct, by its type.
- It does the `@fieldParentPtr` work.
- It writes your struct's type id, in `setTypeId`.
- It checks the type id when the Node comes back.

You never write `@fieldParentPtr` or the field's name again.
