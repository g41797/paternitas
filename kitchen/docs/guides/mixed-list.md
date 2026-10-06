# Several types in one list

This is where Paternitas helps most.

One std list carries a `Message` and a `Job`.

Each comes back as itself.

---

## The types

Each struct has a TypedNode, and its helper right after it.

```zig
--8<-- "examples/002-mixed_list.zig:types"
```

---

## The program

Mark each struct. Put both in one list. Pop them.

```zig
--8<-- "examples/002-mixed_list.zig:setup"
```

It logs one line per struct:

```text
message: hello
job: 42
```

The full program is [example 002](../examples/002-mixed_list.md){target="_blank" rel="noopener"}.

---

## Ask each type in turn

One function handles one Node.

```zig
--8<-- "examples/002-mixed_list.zig:recover"
```

- The wrong type gets null, not a wrong pointer.
- So you can ask `Message` first, then `Job`.
- A Node that no type claims is an error you can see: `error.UnknownParent`.

---

## When you only need to know

`is(node)` answers yes or no.

It does not give you the struct.

```zig
--8<-- "examples/002-mixed_list.zig:is"
```

`is` gives false when `setTypeId` was never called on that struct.

---

## Who knows the types

The loop knows the types it handles.

The list does not.

- The list is still the plain std list.
- Its calls do not change.
- Add a third struct type: the list code stays the same.

In a large system, that matters.

[Example 003](../examples/003-timeout_list.md){target="_blank" rel="noopener"} does the same for a server:

- A server keeps its connections in a timeout list.
- One connection leaves the list, goes through a queue, and comes back.
