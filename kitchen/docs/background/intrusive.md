# Intrusive lists

Zig's std lists are intrusive.

Do not be afraid. Go ahead.

---

## Non-intrusive and intrusive

A non-intrusive list wraps your item in its own node.

- The container makes the node.
- It stores a copy of your item in it.

```text
non-intrusive
the container's node
+-------------------+
| next              |
| id                |
+-------------------+
```

An intrusive list keeps its link inside your struct.

- The link is a field of your struct: a Node.
- The list keeps a pointer to that Node.
- It never copies your struct.

```text
intrusive
your struct
+--------------------+
| id                 |
| node  <-- the list |
+--------------------+
```

In Zig, with a plain std list:

```zig
--8<-- "examples/before_paternitas.zig:structs"
```

---

## What you get

| | typed container of values | intrusive list |
|---|---|---|
| add an item | allocates. Can fail: `try` | allocates nothing. Cannot fail |
| your struct | copied into the container | stays where it is |
| a pointer into your struct | breaks when the container grows | stays valid |
| a struct with a mutex, or too large to copy | does not fit | fits |
| remove an item from the middle | search for it, then shift the rest | one call, no search |
| move an item to another list | copy it, and maybe allocate | remove, append. No allocation |

Some structs must not be copied.

- It has a mutex.
- Other code points into it.
- It is too large to copy.

Such a struct can still be in an intrusive list.

---

## What it costs

The list does not know your struct.

- You get your struct back with `@fieldParentPtr`.
- `@fieldParentPtr` trusts you. A wrong guess is not caught.

The memory is yours.

- The list does not free it.
- The list does not know when the struct is gone.

If you come from C, this is Linux's `list_head` with `container_of`.

*Paternitas* does not change any of this.

It adds one thing: before you get your struct back, it checks the type.
