# Questions

Short answers to what you may ask before you use it.

---

**What does a check cost?**

One pointer compare.

---

**Does it check in ReleaseFast?**

Yes. The type check works in every build mode.

The `must` calls panic in every build mode too.

---

**Does it allocate?**

No. Nothing is allocated. Nothing is freed.

---

**Is it thread-safe?**

It locks nothing.

Guard a shared list yourself, as you do today.

---

**Does my std list change?**

No. It is the same type, with the same calls.

Only the field in your struct changes. [Move your code](../guides/lists.md) shows how.

---

**Can I use my own list?**

Yes. [Your own container](../guides/containers.md) shows how.

---

**Why not a tagged union?**

A union changes with every new struct type, and so does the code on it.

[Type-erased lists](../background/type-erased.md) explains it.

---

**Can I save or send a type id?**

No. A type id is for one running program.

---

**Does it work across a shared library?**

No. A shared library has its own type ids, even for the same struct type.

[Limits](limits.md) has the details.

---

**What about a value that is not a struct?**

Wrap it in a struct.

`Typed` takes structs only.

---

**What if I forget `setTypeId`?**

The checks never match that struct.

`mustParentFromNode` panics with `found <no type>`. [The setTypeId rule](../guides/set-type-id.md) has the details.

---

**Which Zig?**

Zig 0.16.0. It uses `std` only.

[Install](install.md) has the lines to copy.
