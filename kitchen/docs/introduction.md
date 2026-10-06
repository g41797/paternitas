# Introduction

Paternitas makes Zig's intrusive, type-erased lists safer.

And it gives any struct a runtime type id. No list, no Node.

"Intrusive" and "type-erased" sound scary? Do not leave. [Background](background/intrusive.md) explains both words in a few minutes.

---

## You probably do not need it for your first linked list

You may want it when the list becomes part of a real system:

- A mailbox grows.
- A scheduler gets more job types.
- A dispatcher starts passing different structs through the same list.

Then you pop a Node.

And you have a small problem:

**What struct is this Node inside?**

The std list does not know.

Paternitas gives you an answer.

- A wrong type gives null, or a panic that names both types.
- It checks in every build mode.
- No new container. No allocation. No lock.
- Your std list stays your std list.

---

## Do you need it?

**No**, when each list carries one struct type, and you know which one.

- Plain `@fieldParentPtr` is enough.

**Yes**, when:

- one list deliberately mixes struct types;
- the code handling the list should not know every struct type;
- the Node comes from somewhere else;
- you do not want to trust every `@fieldParentPtr` call by hand;
- a bad cast would turn into a very long debugging session.

The last one is a perfectly respectable reason.

Paternitas is for the moment when "I know what this is" becomes "I hope I know what this is".

---

## Where next

| you are | read |
|---|---|
| new to intrusive and type-erased lists | [Background](background/intrusive.md), three short pages |
| at home with them | [Which page you need](guides/choose.md) |
| here for type ids only | [Type ids on their own](guides/type-ids.md) |
| ready to try it | [Install](reference/install.md), then [Move your code](guides/lists.md) |

---

## One more thing

??? question "What's NAQ?"  
    A FAQ needs questions, asked often.  
    Nobody asked these. Not even once.  
    So this site uses a more honest name:  
    **_NAQ_**: **N**ever **A**sked **Q**uestions.  
    I ask myself. I answer myself. You did not ask. **_Not even about NAQ_**.

You will see NAQ blocks on many pages.

Each one sits right after the text it is about.
