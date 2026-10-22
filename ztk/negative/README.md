# negative — what the toolkit refuses

Each file here is a program that must not work. They are not tests in the  
`zig build test` sense: a Zig test cannot assert that a panic happened, and a  
compile error cannot be reached from inside a test at all.

Two mechanisms, one per folder:

- `compile/` — each file must fail to compile, and the build checks the
  message. Scenarios 306 to 309.
- `panic/` — each file is a program that must die. The build runs it and
  checks it aborted. Scenarios 286, 300 to 305, 310, 311, 312 and 313.

Run them with `zig build negative`.

`check` is compiled out where runtime safety is off, so a `check`-based case is  
built and run in Debug and ReleaseSafe only. The build leaves it out of the  
other two modes rather than expecting it to pass there.

Scenario 286 is two programs, `286_duplicate_identity` and  
`286_empty_identities`. One scenario, two ways to break it, and a program can  
only die once.

Five cases are not `check`s and run in all four modes:

- **301**, the wrong-type must-call. The old tree's `orelse unreachable` was
  undefined behaviour in the two fast modes.
- **310** and **312**, `Mbox.destroy` against an open mailbox and against one
  with a call still inside it. Freeing a container another context is still  
  inside is not a contract a fast build may assume away, so `destroy` aborts  
  in every mode. MB3.
- **311** and **313**, `Pool.destroy` against an open pool and against one
  with a hook still running inside it. The same contract as 310 and 312, and  
  the same reason. PL8.

313 does not rest on an ordering: its put hook spins on a flag the program  
never sets, so the putting context cannot leave the pool at all while the  
main one closes and frees it.

312 rests on an ordering rather than on a lock the program holds — its own  
header says which, and says that it was measured at 200 aborts in 200 runs  
rather than assumed. It cannot pass by accident: if the abort does not happen  
the program exits normally and the build reports the contract as not refused.
