**Intrusive containers** (especially linked lists) embed the linking fields (`next`/`prev` or a `Node` struct) *inside* the user’s data structure instead of wrapping the data in a separate node. This eliminates an extra allocation and pointer chase per element, improves cache behavior, and allows one object to belong to multiple lists simultaneously. The classic C idiom is Linux’s `list_head` + `container_of` / `list_entry`.

**Type-erased / interface programming** often uses the same technique: embed a vtable or interface struct inside the concrete type, then recover the parent with the equivalent of `container_of`.

### Zig

Zig’s standard library deliberately moved to *intrusive* lists (post-0.14 / 2025).

- `std.SinglyLinkedList` and `std.DoublyLinkedList` are no longer generic over the payload.  
  They only know about a plain `Node` that contains the link(s):

```zig
pub const Node = struct {
    next: ?*Node = null,
    // (DoublyLinkedList also has prev)
};
```

- You embed the node in your type:

```zig
const Item = struct {
    data: u32,
    node: std.SinglyLinkedList.Node = .{},
};
```

- From a `*Node` you recover the parent with the builtin `@fieldParentPtr`:

```zig
const item: *Item = @fieldParentPtr("node", node_ptr);
```

(The modern form relies on result-type inference; older forms took the parent type explicitly.)

**Why the change?**  
Fewer allocations, less binary bloat, and the same object can sit in several lists. Andrew Kelley’s PR explicitly pushed the “always intrusive” design so people stop hand-rolling next/prev pointers.

**Community reaction & alternatives**  
- Some dislike exposing `@fieldParentPtr` for everyday use.  
- Type-safety concerns (you can accidentally link unrelated nodes).  
- Libraries such as **Zelda** (github.com/mnemnion/zelda) provide a comptime-mixin that keeps the list typed to a concrete struct while still being intrusive.  
- Other projects (libxev, TigerBeetle, various GitHub gists) continue to use either the std intrusive lists or their own `@fieldParentPtr`-based versions. Intrusive heaps, freelists, etc. also appear.

Zig also uses the same pattern heavily for its *intrusive interfaces* (Reader/Writer in 0.15+, older Allocator-style vtables, etc.).

Useful links:  
- [Zig std SinglyLinkedList source](https://github.com/ziglang/zig/blob/master/lib/std/SinglyLinkedList.zig)  
- [“Zig’s new LinkedList API” explanation](https://openmymind.net/Zigs-New-LinkedList-API)  
- [FieldParentPtr deep-dive](https://khitiara.gay/blog/fieldparentptr/)  
- [Zelda – type-safe intrusive lists](https://github.com/mnemnion/zelda)  
- [de-genericify PR](https://github.com/ziglang/zig/pull/23459)

### Odin

Odin has first-class support and a dedicated package.

- `core:container/intrusive/list` provides an intrusive doubly-linked list.  
- You embed `list.Node` (or `using list.Node`):

```odin
My_String :: struct {
    node:  list.Node,
    value: string,
}
```

- Iteration uses an `Iterator` that takes the parent type and field name, or the built-in `container_of`:

```odin
iter := list.iterator_head(l, My_String, "node")
for s in list.iterate_next(&iter) {
    // s is ^My_String
}
```

`container_of` is a language builtin (in `base:runtime`):

```odin
container_of(ptr, T, "field_name") -> ^T
```

It is exactly the safe, offset-based parent recovery.

The same pattern appears in Odin’s pool allocator and other containers that need an intrusive free-list link. Community code (e.g. “Large Array of Things” examples) uses the std intrusive list for hierarchical data.

Useful links:  
- [pkg docs](https://pkg.odin-lang.org/core/container/intrusive/list)  
- [Source](https://github.com/odin-lang/Odin/tree/master/core/container/intrusive/list)  
- [container_of builtin](https://github.com/odin-lang/Odin/blob/master/base/runtime/core_builtin.odin)

### C3

C3’s standard library currently focuses on *non-intrusive* generic containers (`std::collections::list{T}`, maps, etc.) that allocate their own nodes. There is no official intrusive-list package in the core library at the time of writing, and searches turn up almost nothing about a language-level `container_of` / `@fieldParentPtr` equivalent being used in the wild.

Because C3 stays very close to C, you can of course implement the classic Linux-style intrusive list yourself with `offsetof` / a `container_of` macro; the language does not prevent it. The ecosystem simply has not standardized on the pattern the way Zig and Odin have.

### GitHub / real-world usage summary

| Language | Std-lib support | Common pattern | Notable projects / libs |
|----------|-----------------|----------------|-------------------------|
| **Zig**  | Yes (intrusive since ~0.14) | `@fieldParentPtr` | std, Zelda, libxev, TigerBeetle, many gists |
| **Odin** | Yes (`core:container/intrusive/list`) | `container_of` + iterators | std itself, hierarchical entity systems |
| **C3**   | No dedicated intrusive list | Classic C `container_of` if desired | Almost none visible |

### Verdict for a new project (relevant to paternitas)

- **Zig** and **Odin** treat intrusive containers + parent-pointer recovery as a *first-class, idiomatic* technique. Both languages give you a safe, layout-aware way to go from link → containing object.  
- The approach shines when:
  - objects live in multiple collections,
  - allocation must be minimized or made infallible,
  - you want the same “type-erased interface embedded inside the concrete type” style that Zig now uses for IO, allocators, etc.
- C3 is still closer to “write it yourself in C style.”

If your project (https://github.com/g41797/paternitas) is exploring patterns, type erasure, or low-overhead containers in a “best-C” language, both Zig’s `@fieldParentPtr` + intrusive Node and Odin’s `container_of` + intrusive list are mature, battle-tested solutions you can copy or wrap. The Zig std change and the Odin package are the clearest modern references.

### Additional links

- [Type Erasure](https://en.wikipedia.org/wiki/Type_erasure)
- [Intrusive and non-intrusive containers](https://www.boost.org/doc/libs/latest/doc/html/intrusive/intrusive_vs_nontrusive.html)
- [Zelda: Type Safe Intrusive Linked Lists](https://github.com/mnemnion/zelda)

