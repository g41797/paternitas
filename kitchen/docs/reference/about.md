# Name and origin

---

## Why the name

*Paternitas* is Latin for "fatherhood".

*Paternitas* is about finding the Parent of an unknown Node.

Latin law has two terms for it:

- *Affirmatio paternitatis*: the affirmation of paternity.
- *Investigatio paternitatis*: the investigation of paternity.

*Paternitas* does both.

*Affirmatio paternitatis*: a Parent gets its type.

```zig
--8<-- "examples/001-set_type_id_and_recover.zig:create"
```

*Investigatio paternitatis*: an erased Node is checked, to find its Parent.

```zig
--8<-- "examples/001-set_type_id_and_recover.zig:list"
```

The name is a small joke. The idea is literal.

> The Node may be unknown.
>
> *Paternitas* establishes its parentage.

**A note.** Both Latin terms were made up while the README was written.

- We believe they are real Latin.
- We did not check them in a law book.
- A joke is a joke.

---

## Where it came from

The trigger was the Ziggit post [New LinkedList API footgun](https://ziggit.dev/t/new-linkedlist-api-footgun/10853).

*Paternitas* grew out of *Matryoshka*, a toolkit for background processes.

The same problem appeared in each version:

- [C3](https://github.com/g41797/matryoshka-3tk): C3's own `typeid`.
- [Zig](https://github.com/g41797/matryoshka-ztk): comptime helpers. Work in progress.

The useful part turned out to be small enough to use by itself.

So *Paternitas* was extracted from the Zig version.

Matryoshka can use it as a package.

Your project can too.

---

## Credits

- [Karl Seguin](https://github.com/karlseguin), for the article that introduced [Zig's new LinkedList API](https://www.openmymind.net/Zigs-New-LinkedList-API/).
