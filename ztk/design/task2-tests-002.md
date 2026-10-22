# Task 2 — Test Scenarios for Layer 4 and Cross-Layer (001)

Written 2026-09-20, stage SPEC. The first version for the rewritten tree.

Derived from `design/task2-tests-004.md` in the old tree, against the rulings in  
`3tk-to-ztk-007.md`. Numbering and tracing work as in
[task1-tests-003.md](task1-tests-003.md) — old numbers are kept, new scenarios
start at 200.

All of these use a real `Io.Threaded`: several threads, cancellation, real  
waiting.

---

## What the rulings did to this list, and did not

**Almost nothing, and that is the point.** Layer 4 is where `std.Io` shows  
through, and every `std.Io` row in the survey was ruled a std difference and left  
alone: the timeout form of receive (MB7), the result type and the future form  
(MB8, PL10), the error sets that carry cancellation (TK1). So these scenarios  
carry over nearly unchanged.

Three changes reach this layer, and each is a consequence rather than a new  
subject:

- A container is destroyed by a method, and only when it is closed and no call is
  inside it. That is a new shutdown step for a Master to get right, so it gets  
  its own scenarios here.
- The close hook can be called more than once and its calls can overlap. Under
  several threads that is not a detail, so it is tested here as well as in task1.
- The batch put is gone, so a worker gives items back one at a time.

---

## Layer 4 — a worker from spawn to join

1. **One worker, spawned and joined** — the Master spawns a worker, the worker
   receives one outer and exits, the Master awaits. *(old 1)*
2. **A group of workers, spawned and joined** — three workers, all process
   items, the Master awaits the group. *(old 2)*

---

## Layer 4 — shutdown ordering

6. **Close before join** — the Master closes the mailbox, the waiting worker
   wakes with the closed error and exits; the Master joins, then closes the pool  
   and walks what comes back. *(old 6)*
7. **Cancel before close** — the Master cancels the worker's future, the worker
   exits, then the Master closes both containers to reclaim. No race, because the  
   worker has already exited. *(old 7)*
8. **Put on a closed pool** — the pool is closed before the worker runs; the
   worker receives an outer and puts it; the pool refuses and the Slot stays  
   full, so the outer is still the worker's, and the worker releases it.  
   *(old 8)*
9. **Close gives the remainder back** — send ten, close after three are
   consumed, seven come back. *(old 9, changed: walked with `while (popFirst())`,  
   and the list repairs links itself.)*
10. **Close calls the close hook with everything stored** — put five, close, the
   hook receives five. *(old 10, changed: PL4, the list arrives by value.)*
200. **Destroy comes after close and after quiet** — the Master closes, joins
   every worker, and only then destroys. A destroy with a worker still inside a  
   call is refused, in every build. *(MB3, PL8 — a new step in the Master's  
   shutdown, and the one most likely to be got wrong.)*
201. **Destroy is a method and needs no allocator** — the Master does not keep
   the allocator to take a container down. *(MB2)*
202. **A straggling put reaches the close hook** — a worker is inside a put when
   the Master closes the pool; the outer it carried and anything its hook added  
   reach the close hook, and nothing is lost. *(PL3 — task1 scenario 282 under  
   one thread, this one under several.)*
203. **The close hook survives overlapping calls** — close and a straggling put
   both call it, possibly at the same time. The hook takes its own lock and does  
   not release its own state on the first call. *(PL3, PL4)*
204. **A worker gives a batch back one at a time** — the loop is the caller's,
   and it stops or continues on a refusal as the worker decides. *(PL6, and the  
   two 3tk tests that pin the two behaviours of such a loop)*

---

## Layer 4 — cancellation

3. **Cancel stops a waiting worker** — the worker waiting in receive gets the
   cancelled error and exits; the cancel returns after it has exited. *(old 3)*
4. **Cancel stops a whole group** — three waiting workers all exit. *(old 4)*
5. **Cancel arrives while the worker is not waiting** — it takes effect at the
   next waiting point. *(old 5)*
11. **Cancelled is not closed, in receive** — cancel a worker while the mailbox
   is open; it sees cancelled, not closed. *(old 11)*
12. **Cancelled is not closed, in the waiting get** — the same for the pool.
   *(old 12)*
13. **Put survives cancellation** — a worker that has just been cancelled can
   still give its outer back. The item is not lost. *(old 13)*
14. **Close survives cancellation** — a close called from a cancelled task
   completes, gives its list back, and wakes everyone. *(old 14)*
15. **Re-cancelling propagates** — a worker catches the cancelled error, cleans
   up, re-cancels, and the next call is cancelled again. *(old 15)*
16. **A cancel check in a long computation** — a worker between receives checks
   for cancellation and takes effect there. *(old 16)*
205. **Destroy is not cancellable** — a Master that is itself being cancelled can
   still take a closed, quiet container down. *(MB2, MB3 — the same reasoning  
   that makes close and put cancel-safe, applied to the call that MB3 added.)*

---

## Cross-layer

206. **A mailbox travels as an outer** — a mailbox is sent through another
   mailbox, arrives, and is used. *(old task1 18, raised to Layer 4 where it  
   is a real pattern. MB12 keeps the surface that makes this work and drops only  
   the duplicate module-level query.)*
207. **A pool travels as an outer** — the same for a pool. *(MB12)*
208. **Infrastructure items declare no create and no destroy** — a Master
   acquires them into a Slot and detaches, and the helper's create-and-destroy  
   pair is not there to be called by mistake. *(HP1)*

209. **A waiting get packs every outcome** — `getWaitResult` answers `item`, `closed`, `timeout` and `unknown_identity`; the canceled outcome has its own variant. *(PL10)*
210. **The waiting get as a future** — `getWaitFuture` awaited gives the item another context put, and a close ends the wait with `closed`. *(PL10)*

---

## Notes

- Scenarios 3 to 5 are listed under cancellation here but keep the numbers they
  had in the shutdown section of the old list. Numbers are never reused.
- The old list recorded 16 of 16 done and 121 tests passing. That count belongs
  to the old tree and is not carried here.
- The old task2 scenarios 17 to 61 are examples, not tests. They belong to the
  EXAMPLES stage and to `task2-examples`, not to this file.
- Negative scenarios for this layer — a destroy refused while a worker is inside
  a call — are in task1's **Negative scenarios**, with the mechanism question  
  that governs all of them.
