# Task 1 — Test Scenarios for Layers 1–3 (003)

Written 2026-09-20, stage SPEC. This is 003, written at SURFACE. Scenarios 202  
and 204 are retired and 201 and 203 are reworded, because the owner ruled the  
identity internals off the generated site and then ruled the id itself opaque —  
`?*const anyopaque`, with null for unstamped. What a test can reach is what a  
caller can reach. Nothing else changed. 002 is in `next/backup/`.

The header of 001 and 002 both read 001. That is corrected here.

Derived from `design/task1-tests-008.md` in the old tree, against the rulings in  
`3tk-to-ztk-007.md`. Tests check the implementation: correctness, edge cases,  
error paths, state transitions, contracts refused.

Master, cancel, futures, `Io.Group` and subsystem coordination are out of scope  
here. Layers 1 to 3 are testable without them. They are task2.

---

## How to read this

**Numbers are traceable.** A scenario that survives from the old list keeps its  
old number, even where its meaning changed — so 9 is still the Slot scenario.  
Scenarios new to this model are numbered from 200, grouped by area. Nothing is  
renumbered, and no number is reused.

Each scenario names its origin where that is not obvious:

- **(old N)** — carried from the old list, unchanged in meaning.
- **(old N, changed)** — carried, but the model changed under it. The change is
  stated.
- **(IT4)**, **(PL3)**, … — new, and required by that ruling.
- **(3tk `name`)** — new, and 3tk has a test of that name. Its evidence.

**Names of calls are indicative.** The vocabulary is ruled — Outer, Inner,  
`OuterId`, `OuterInfo` — and functions are camelCase. Exact spellings are decided  
by the stage that writes the code, and this list is not the authority on them.

**What retired is listed, not deleted.** The **Retired** section at the end names  
every scenario of the old list that has no successor, and the ruling that removed  
it. A scenario that vanishes without a reason is how a behaviour is lost.

---

## Layer 1 — the core

### The id and the stamp

1. **An id is per type** — two outer types have different `OuterId`; the same
   type answers the same `OuterId` every time. *(old 1, changed: an id is a  
   pointer to an `OuterInfo`, not to an empty marker.)*
   - Load-bearing, not a formality. Ids are compared by pointer, and that two
     distinct types get two distinct addresses is measured, not guaranteed by the  
     language. This scenario is what would notice.
2. **The stamp writes the id once** — after the helper stamps an outer, its
   inner reads back that outer's id. *(old 2, changed: no by-hand assignment. The  
   helper is the only way to stamp, so the scenario calls the helper.)*
3. **An id answers what, never which** — two instances of one type share an id;
   an id comparison says the type matches and says nothing about the instance.  
   *(old 3, changed: extended to state the class-against-instance rule the api  
   reference already carries.)*
4. **The crossing back, with the type known** — from an `*Inner` with the right
   id, the helper recovers the `*Outer` and its field values survive.  
   *(old 4, changed.)*
5. **The crossing back is refused on the wrong id** — the helper answers null
   rather than casting. *(old 5, changed: the toolkit refuses it. In the old  
   model this was the caller's job.)*
200. **The inner is found by type, not by name** — two outer types whose inner
   fields have different names, neither called `inner`, both work. *(IT3)*
201. **The inner may sit anywhere in the outer** — one type with fields before
   its inner and one with none, and the crossing back lands on the outer for  
   both. *(IT3, 3tk `inner_at_any_offset`. Reworded at SURFACE: the offsets  
   themselves are the toolkit's to know, and an opaque id does not show them.)*
203. **An unstamped inner reads as unstamped** — a declared outer's id is null,
   a zeroed one's is too, and the typed read answers null for both. *(IT4, IT5.  
   Reworded at SURFACE: null is the unstamped id, so the zero value of an inner  
   is unstamped and zeroed memory is a valid unstamped outer.)*
205. **A mixed walk claims correctly** — a chain holding three outer types is
   walked, each item is claimed by its own type and refused by the other two.  
   *(3tk `heterogeneous_walk_claims_correctly`, old 10 in spirit)*

### The Slot

9. **A Slot holds one outer, or nothing** — empty means the caller has nothing;
   full means the caller has that outer; emptying it lets the outer go. *(old 9)*
206. **A Slot starts empty** — every acquiring call asserts it, and the rule is
   stated once. *(3tk `rule2_a_slot_starts_empty`)*
207. **A transfer clears the Slot** — after any call that takes the outer, the
   Slot is empty, with no line left for the caller to write. *(3tk  
   `rule5_a_transfer_clears_the_slot`, old 43 and 44 generalized)*
208. **A failed move leaves the Slot untouched** — a move that answers null
   because the type did not match leaves the outer where it was. *(3tk  
   `rule4_a_failed_move_leaves_the_slot_untouched`, old 100 in part)*
209. **A look is not a take** — reading through the Slot leaves it full; taking
   empties it. *(3tk `a_look_is_not_a_take`, `peek_and_take_differ`)*

### The helper

210. **An outer declares `init` and `finish`** — both are required at compile
   time where the helper creates or releases the type, and an empty body is the  
   way a type says it has nothing to do. *(HP1)*
211. **`create` runs the outer's `init`** — a type that allocates in `init` is
   created through the helper and its allocation is there. *(HP1, 3tk  
   `create_and_release_take_the_allocator`)*
212. **A failing `init` frees the outer and passes the failure on** — the
   allocation does not leak and the Slot stays empty. *(HP1, 3tk  
   `a_failing_init_hook_propagates_and_frees`)*
213. **`destroy` runs the outer's `finish` before freeing** — a type that
   allocated in `init` releases it in `finish`, and nothing leaks. *(HP1, 3tk  
   `the_finish_hook_runs_on_release`)*
214. **`destroy` on an empty Slot does nothing** — so one `defer` covers every
   path out, including the path where the outer was never created. *(HP1, 3tk  
   `release_is_a_no_op_on_an_empty_slot`, old 105 in spirit)*
215. **Create and destroy, repeatedly** — the same Slot is filled and emptied
   many times with no residue. *(3tk `repeated_create_and_release`)*
216. **A created outer is an ordinary outer** — it sends, it is kept in a list,
   it comes back, with no mark of having been made by the helper. *(3tk  
   `a_created_outer_is_an_ordinary_outer`)*
217. **The panicking take** — the must-form of the move answers the outer on a
   match, and panics on a wrong type or an empty Slot. *(HP3)*
218. **The border pair, out and back** — taking a bare `*Inner` out of a Slot and
   putting one back each check: the outer is stamped, it is unlinked as it  
   crosses, the destination is empty, the source is cleared. *(HP6)*
219. **The border pair round trip** — an outer crosses into a plain Zig container
   as an `*Inner`, comes back into a Slot, and is still itself. *(HP6 — no old  
   scenario covers this, and no old example either.)*

### The chain

The list keeps the operations a real behaviour needs: append, append from a  
Slot, pop the first, is-empty, length, and concat. The walk is  
`while (list.popFirst())`.

240. **The chain is first in, first out** — append three, pop three, in order.
   *(old 100 in part, 3tk `the_queue_is_first_in_first_out`)*
241. **An empty chain answers** — is-empty is true, length is zero, popping
   answers null. *(old 100 in part)*
242. **The last item points at itself** — the tail's link is the tail, which is
   what makes the link test exact. *(IT1, 3tk `the_last_item_points_at_itself`)*
243. **The link test is exact, including a chain of one** — an outer alone on a
   chain reads as linked. The old test could not see this, and the walk that  
   covered for it is gone. *(IT1, 3tk `the_link_test_is_exact`)*
244. **The link test sees another container** — an outer on one chain is refused
   by a second. *(IT1, 3tk `the_link_test_sees_another_container`)*
245. **Every removal repairs the chain** — a popped outer is unlinked and drops
   straight into a Slot with no repair step for the caller. *(old 101, 3tk  
   `every_removal_repairs`)*
246. **Length is a stored count** — it is O(1) and it agrees with the number of
   items after every operation, including concat. *(LS2)*
247. **Pop feeds append-from-Slot directly** — a popped outer is a legal Slot
   value, and the round trip needs no repair call. *(old 105)*
248. **Append-from-Slot takes the outer** — the Slot is empty afterwards.
   *(old 104, halved: the prepend form is retired.)*
249. **Concat moves every item and empties the source** — including the empty
   cases at either end. *(old 103 in part, 3tk `append_queue_empties_the_other`,  
   `append_queue_at_the_edges`)*
250. **Concat keeps the chain walkable** — the joined chain walks end to end and
   its last item still points at itself. *(IT1, 3tk  
   `append_queue_keeps_the_chain_walkable`)*
251. **A chain onto itself does not destroy it** — the check refuses it where
   safety is on, and the early return saves it where safety is off. *(old 103 in  
   part, 3tk `self_move_does_not_destroy_the_queue`)*
252. **One chain, three types** — a chain holds outers of several types at once
   and each comes back as itself. *(old 10, 3tk `one_queue_three_types`)*

### Item states

11. **FREE → IN_FLIGHT** — an outer is created; the Slot is full; the outer is
   not linked. *(old 11, changed: created through the helper, so it is stamped by  
   construction.)*
12. **IN_FLIGHT → HELD** — append to a chain, Slot empty, outer linked.
   *(old 12)*
13. **HELD → IN_FLIGHT** — pop, Slot full, outer unlinked. *(old 13)*
14. **IN_FLIGHT → FREE** — destroy through the helper, Slot empty. *(old 14,
   changed: `finish` runs first.)*

### Infrastructure as items

18. **A mailbox is an outer** — `Mbox` embeds an inner, and its id answers for
   it. *(old 18, changed)*
19. **A pool is an outer** — the same for `Pool`. *(old 19, changed)*
20. **Each container releases itself** — `destroy` is a method and uses the
   allocator the container already holds. *(old 20, changed: MB2. The old form  
   took the allocator again, and the stored one was never read.)*
253. **A container declares no create and no destroy** — the helper's
   create-and-destroy pair is absent for `Mbox` and `Pool`, because a container  
   allocates itself. *(HP1 — the boundary between the two classes of item.)*

---

## Layer 2 — the mailbox

27. **Send and receive one outer** — id and data intact. *(old 27)*
28. **Ordinary items are first in, first out** — send three, receive three.
   *(old 28)*
29. **Send to a closed mailbox is refused.** *(old 29)*
30. **Receive from a closed mailbox is refused.** *(old 30)*
31. **Receive with a timeout** — an empty open mailbox times out. *(old 31)*
32. **Receive waiting forever** — a null timeout waits, and another context
   sends. *(old 32)*
33. **Close gives the remainder back** — send three, close without receiving,
   all three come back. *(old 33)*
34. **Close is repeatable** — the second close gives an empty list back.
   *(old 34, reworded: the banned word is gone.)*
35. **Out of band goes to the front** — three ordinary, then one out of band;
   the out-of-band one arrives first. *(old 35)*
36. **Out of band wakes a waiting receiver.** *(old 36)*
37. **Out-of-band items keep their own order** — A then B arrive A then B.
   *(old 37, changed: two queues do this now, not an insert-after. The promise is  
   the same and the mechanism is gone.)*
38. **Out of band to a closed mailbox is refused.** *(old 38)*
39. **Data before the close** — an item sent before a close is receivable, or
   comes back from the close. *(old 39)*
40. **Batch receive takes everything** — send five, take five, the mailbox is
   empty. *(old 40)*
41. **Batch receive on empty gives an empty list**, not a refusal. *(old 41)*
42. **A batch is walked with pop** — the walk is `while (popFirst())` and every
   item comes back unlinked. *(old 42, changed: the old scenario existed because  
   a plain std list did not repair its links. The list repairs them now, so what  
   is tested is that the walk needs no repair step.)*
43. **Send transfers the outer** — the Slot is empty afterwards. *(old 43)*
44. **Receive transfers the outer** — the Slot is full, the mailbox no longer
   has it. *(old 44)*
45. **A non-blocking receive on empty answers false**, Slot untouched. *(old 45)*
46. **A non-blocking receive takes the item** and answers true. *(old 46)*
47. **IN_FLIGHT → HELD, by send.** *(old 47)*
48. **HELD → IN_FLIGHT, by receive.** *(old 48)*
49. **Sending a linked outer is refused** — the link test is exact now, so a
   chain of one is caught too. *(old 49, changed by IT1)*
26. **New and destroy** — created into a Slot, detached, closed, then destroyed.
   *(old 26)*
260. **A call in flight blocks destroy** — a receiver is inside the mailbox;
   destroy refuses, in every build, not only where safety is on. *(MB3, 3tk  
   `release_while_receiving`)*
261. **Closed, then quiet, then freed** — destroy is allowed once the mailbox is
   closed and no call is inside it. *(MB3, 3tk `closed_then_idle_then_freed`)*
262. **The queries answer** — is-closed, is-idle and length, before and after a
   close. *(MB4)*
263. **A closed mailbox is empty** — length is zero after close, because close
   gave everything back. *(MB4, 3tk `a_closed_mailbox_is_empty`)*
264. **A send with a limit is refused at the limit** — the count is of the
   sender's own outer type, and other types do not count toward it. *(MB5, 3tk  
   `send_limit_is_per_typeid`)*
265. **A send with a limit of zero is an ordinary send.** *(MB5)*
266. **Waking every waiter** — a wake with no message releases all of them.
   *(old task2 territory, but testable here; 3tk `wake_all_releases_every_waiter`)*

### Several threads

50. **Fan-in** — three senders, mixed types, main receives all three. *(old 50)*
51. **Fan-out** — two receivers loop until closed; sent equals received plus
   what close gave back. *(old 51)*
52. **Combined** — three senders, two receivers, main closes; nothing is lost and
   nothing is doubled. *(old 52)*

---

## Layer 3 — the pool

63. **New and destroy** — created with its identities and hooks into a Slot,
   detached, closed, destroyed. *(old 63, changed: PL1. The identities are their  
   own argument now, not a field of the hooks.)*
64. **Get creates when nothing is stored** — the get hook is called with an empty
   Slot and makes one. *(old 64)*
65. **Get reuses a stored outer** — put one back, get it again, same pointer.
   *(old 65, changed: PL2. The get hook is **not** called on this path.)*
67. **Put calls the put hook** with the right stored count. *(old 67)*
68. **The put hook may release the outer** — it empties the Slot, and nothing is
   stored. *(old 68)*
69. **The put hook may keep the outer** — it leaves the Slot full, and the pool
   stores it. *(old 69)*
70. **New-only always creates** — even with items stored, the hook is called with
   an empty Slot. *(old 70)*
71. **Available-only on an empty pool is refused.** *(old 71)*
72. **Available-only takes a stored outer.** *(old 72)*
73. **One free list per identity** — a get for one type never answers with
   another. *(old 73)*
74. **Close gives every stored item to the close hook.** *(old 74, changed: PL4,
   the list arrives by value.)*
75. **Close is repeatable.** *(old 75, reworded.)*
76. **Get on a closed pool is refused.** *(old 76)*
77. **Put on a closed pool leaves the outer with the caller** — the Slot stays
   full. *(old 77)*
78. **A capped pool** — the put hook releases items above a threshold. *(old 78,
   changed by PL2: the hook now reads the stored count in the put hook, because  
   the get hook no longer runs when an item was reused.)*
79. **Seeding** — create N with new-only and put them, then N are available.
   *(old 79)*
80. **The stored count is right** — across get and put cycles, both hooks see the
   true count. *(old 80, 3tk `the_count_is_read_from_the_right_side`)*
81. **Hooks run outside the lock** — a hook that calls back into the pool does
   not deadlock. *(old 81, 3tk `hooks_run_outside_the_mutex`)*
83. **The waiting get times out** on an empty pool. *(old 83)*
84. **The waiting get waits forever** until another context puts. *(old 84)*
85. **HELD → IN_FLIGHT, by get.** *(old 85)*
86. **IN_FLIGHT → HELD, by put that keeps.** *(old 86)*
87. **IN_FLIGHT → FREE, by put that releases.** *(old 87)*
88. **Putting the same outer twice is refused.** *(old 88)*
280. **The get hook's Slot is always empty** — on every path that reaches it, in
   all three modes. This is the scenario PL2 exists for, and the old behaviour  
   was the opposite. *(PL2)*
281. **The waiting get never creates** — it waits for a stored item and does not
   reach the get hook. *(PL2, 3tk `the_waiting_get_never_creates`)*
282. **A close while the put hook runs loses nothing** — the pool closes with a
   put in flight; the outer in the Slot and everything the hook added go to the  
   close hook. *(PL3, 3tk `a_close_during_the_put_hook_loses_nothing`. The old  
   tree lost them, and had no test.)*
283. **The close hook is called more than once** — once by close, once more per
   straggling put, and the two may run at the same time. A hook must survive it  
   and must not release its own state on the first call. *(PL3, PL4)*
284. **The close hook cannot reach the items afterwards** — it takes the list by
   value. *(PL4)*
285. **An unknown identity is refused** — by get, by the waiting get, and by put,
   as an error return, in every build. The old code asserted, so a fast build  
   called the hook with an identity the pool never knew, and the waiting get  
   waited out the whole timeout. *(PL7, Z2, 3tk `pool_unknown_identity`)*
286. **A duplicate identity at creation is refused**, and so is an empty set.
   *(PL1, Z5, 3tk `duplicate_pool_tags`)*
287. **The pool's queries answer** — is-closed, is-idle, and the count for one
   identity. *(PL8)*
288. **A call in flight blocks destroy** — the same guard as the mailbox.
   *(PL8, MB3, 3tk `release_not_quiet_pool`)*
289. **Reuse is last in, first out** — and the reason is written down: a stale
   writer meets the next owner at once. *(LS4, 3tk `reuse_is_last_in_first_out`)*
290. **The waiting get takes a stored item** when one arrives. *(3tk
   `the_waiting_get_takes_a_stored_item`)*
291. **The put hook's extra list is taken** — a composite outer gives its parts
   back and each part is stored the same way the outer in the Slot is. *(PL5, 3tk  
   `the_extra_list_on_put`)*

---

## Negative scenarios

These check what the toolkit **refuses**. 3tk keeps 29 of them as separate  
programs, each expected to abort or to fail to compile. The old ztk list had  
three, scenarios 15 to 17.

**The mechanism is not decided, and this list does not decide it.** Zig has no  
standard way to assert a panic inside a test, and the old tree carries this as  
Open Item 11, unresolved. A compile-error case needs a build step of its own.  
**The stage that writes these picks the mechanism and asks the owner first.**  
Until then they are scenarios, not tests.

Also note what they cost: `check` is compiled out where runtime safety is off, so  
every panicking scenario here is a Debug and ReleaseSafe scenario only. A  
scenario that must hold in all four modes says so.

300. **An unstamped outer is refused at every crossing** — entering a Slot, being
   sent, being put, being appended. *(IT4, 3tk `unstamped_crossing`,  
   `unstamped_inner`, `unstamped_insert`)*
301. **A wrong-type must-call panics, and names both types** — the id carries the
   name, so the message says what was asked for and what was there. *(IT5, HP3,  
   3tk `wrong_type_must`)*
   - **In all four modes.** This one is not a `check`. The old tree's
     `orelse unreachable` was undefined behaviour in the two fast modes, where the  
     optimizer could drop the compare and answer a pointer of the wrong type.
302. **Creating into a full Slot is refused.** *(3tk `create_into_full_slot`)*
303. **Overwriting a full Slot is refused.** *(old 16 in spirit, 3tk
   `overwrite_slot`)*
304. **Appending an outer that is already on a chain is refused** — including the
   chain of one. *(old 15, IT1, 3tk `insert_linked_outer`)*
305. **Appending the same outer twice to one chain is refused.** *(old 16, 3tk
   `insert_twice_same_queue`)*
306. **An outer with no inner field does not compile.** *(IT3, 3tk
   `nocompile_no_inner`)*
307. **An outer with two inner fields does not compile.** *(IT3, 3tk
   `nocompile_two_inners`)*
308. **An outer with no `init` does not compile** where the helper creates it.
   *(HP1, 3tk `nocompile_no_init`)*
309. **An outer with no `finish` does not compile** where the helper releases it.
   *(HP1, 3tk `nocompile_no_finish`)*
310. **Destroying an open mailbox is refused.** *(MB3, 3tk
   `release_open_mailbox`)*
311. **Destroying an open pool is refused.** *(PL8, 3tk `release_open_pool`)*
312. **Destroying a mailbox with a call inside it is refused.** *(MB3, 3tk
   `release_while_receiving`, `release_with_straggler_put`)*
313. **Destroying a pool during either hook is refused.** *(PL8, 3tk
   `release_during_on_put`, `release_during_on_close`)*
17. **Using a Slot after it was emptied** — the Slot is empty and reading through
   it answers nothing. Documented as an invariant. *(old 17)*

---

## The check helper

314. **A broken contract panics where runtime safety is on**, with its message.
   *(TK2)*
315. **A broken contract is compiled out where runtime safety is off** — no call,
   no branch, no message in the binary. *(TK2)*
316. **The check is broken deliberately, both ways, before it is trusted** — a
   check that has never been seen to fail has not been tested. This is a rule of  
   the stage, recorded here so it is not skipped. *(3tk rule 11)*

---

## The version

317. **The toolkit states its version** — a constant on the module root.
   *(TK3. `CHECKED` is `std.debug.runtime_safety` in Zig and is not added, and  
   `LOC` is 3tk's own.)*

---

## Retired

Each of these was in the old list and has no successor. The ruling that removed  
it is named. Nothing here is an oversight.

| old | what it tested | removed by |
|---|---|---|
| 6 | the two-level cast chain, list node to node to user type | IT1 — one link, and the field is found by type |
| 7 | the repair call clears both links | LS1 — the call is gone; removal repairs the chain itself |
| 8 | the blind link test | IT1 — the test is exact now. Scenario 243 replaces it |
| 82 | the batch put | PL6 — the caller writes the loop |
| 102 | crossing to and from a plain std list | IT1, LS3 — there is nothing left to cross to |
| 103 | the iterator walk | LS1 — the walk is `while (popFirst())`. The concat half survives as 249 and 251 |
| 104 | the prepend-from-Slot half | LS1 |
| 106 | remove from head, middle, tail | LS1 |
| 107 | pop the last | LS1 |
| 108 | first and last leave the item in place | LS1 |
| 109 | insert before an existing item | LS1 |
| 110 | the std list header check | LS3 |
| 204 | the unstamped id's zero offset, and the near miss it produced | SURFACE, 2026-09-20 — the unstamped id is null, so there is no descriptor to carry an offset and no near miss to observe. A missed check now faults instead of computing a plausible address, which is the stronger behaviour. The refusal it guarded is negative program 321 |
| 202 | the crossing back from a bare `*Inner`, without the type | SURFACE, 2026-09-20 — `outerAddr` is internal, so a test cannot reach it and a caller has no use for it. What it asserted is still exercised: `AnyOuter.moveFromSlot` computes the same address, and scenario 321 checks the result |
| 66 | the get hook reinitializes a recycled outer | PL2 — the get hook is not reached on that path. The work moves to the put hook, which scenario 78 covers |

**Two old scenarios changed owner rather than retiring.** Old 37's out-of-band  
ordering is now kept by two queues instead of an insert-after, and old 42's  
link repair is now the list's job. Both keep their numbers, because the promise  
to the caller did not change.

---

## Cross-layer notes

- Layer 2 and 3 tests that block use the single-threaded `Io` and no
  cancellation. Cancel, futures and `Io.Group` are task2.
- Thread-based tests use `std.Thread.spawn`.
- The timeout is `?u64`: null waits forever, a value is nanoseconds. Ruled
  unchanged — `std.Io` shapes it.
- Batch returns are a list, walked with `while (popFirst())`. The list repairs
  links itself, so no caller repairs them.
- Calls are methods on the receiver. What stays a module function is decided by
  the stage that writes it.
- Builder and test item types are shared test infrastructure, not part of any
  layer's public surface.
- The item-state scenarios check the architecture's invariants, not the
  implementation.

---

## The type-erased carrier — scenarios 320 to 325

Added by ANY. Tests are in `tests/layer1_any.zig`; the refusals are programs  
under `negative/panic/`.

| # | what it holds |
|---|---|
| 320 | a fresh `AnyOuter` is empty, `set` fills it, `reset` empties it again |
| 321 | `moveFromSlot` stores the outer's address, not the inner's; the Slot is empty |
| 322 | `moveToSlot` returns the same outer; the `AnyOuter` is empty |
| 323 | `fromAny` answers null for an empty `AnyOuter` and for another type, and leaves it full |
| 324 | an inner at offset zero and at a nonzero offset both round-trip |
| 325 | an `AnyOuter` goes through `Io.Queue(union(enum) { outer: AnyOuter, quit })` |

Negative, in all four modes' safe builds:

| # | what dies |
|---|---|
| 320 | `moveFromSlot` into a full `AnyOuter` |
| 321 | `moveFromSlot` of an unstamped outer |
| 322 | `moveFromSlot` of an outer still on a chain |
