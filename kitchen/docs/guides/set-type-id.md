# The setTypeId rule

One rule in Paternitas is yours to keep.

The compiler cannot check it.

---

## Call it after you create the struct

```zig
--8<-- "examples/001-set_type_id_and_recover.zig:create"
```

Call it even when every field has its default value.

- A new struct has no type id.
- Paternitas does not mark a new struct by itself.

??? question "NAQ: Why can Paternitas not mark a new struct by itself?"  
    The TypedNode is one type, shared by every struct that uses it.

    Its default value is the same for a `Message` and for a `Job`.

    So the default cannot know which struct it is in. `setTypeId` can.

Memory from `allocator.create` is undefined.

- Set up the struct first.
- Then call `setTypeId`.

---

## Call it again after a whole-struct write

A whole-struct write replaces the type id too.

- an assignment, `message = .{ ... };`
- a reset of the whole struct
- a clear of the whole struct
- a zero-fill of the whole struct

Call `setTypeId` right after each one:

```zig
--8<-- "examples/001-set_type_id_and_recover.zig:reset"
```

Writing one field is fine.

- `message.text = "again";` changes one field.
- The type id stays there.

[Example 001](../examples/001-set_type_id_and_recover.md){target="_blank" rel="noopener"} does the reset, and checks the struct comes back.

---

## Forgot it?

Nothing breaks at once. The checks just never match.

| call | what you get |
|---|---|
| `parentFromNode(node)` | null |
| `mustParentFromNode(node)` | a panic: `found <no type>` |
| `is(node)` | false |
| `parentFromAnchor(a)` | null |
| `anchor.info()` | null |

The panic looks like this:

```text
mustParentFromNode: asked for must_parent_from_node.Msg, found <no type>
```

When you see `<no type>`, look for the place that created the struct, or wrote all of it.

`fromAny` is different.

- When runtime safety is on, a missing call panics.
- In ReleaseFast and ReleaseSmall, nothing catches it.

```text
fromAny: setTypeId was never called on the Parent
```

---

## Your own container

A container you write yourself keeps Anchors.

Call `setTypeId` before the struct enters it.

- Your container asks `anchor.info()` for the struct's `TypeInfo`.
- Without `setTypeId`, it gets null.

[Your own container](containers.md) shows the container side.
