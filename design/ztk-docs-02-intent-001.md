# ZTK DOCS 02 — the frame (intent 001)

The owner named the stage, 2026-10-22. Items B27, B14, B32.
The plan: [implementation-plan-034.md](implementation-plan-034.md), "ZTK".

## Owner's answers, 2026-10-22

1. The nav groups: yes, as proposed.
2. B32, paternitas's site tools: take them now.
3. "Get Started" opens a placeholder page, `get-started`.
4. The site name stays "Be Master of your systems", for now.
   - Open: decide whether ztk keeps the Master concept. The site name
     follows that ruling. Backlog B42.

## What changes, all in `ztk/kitchen/`

1. The home page, `index`: the hero in the paternitas style.
   - The ztk logo, `assets/matryoshka-ztk-logo.png`. It opens
     `get-started/`.
   - Two buttons: "Get Started", same tab; "{{ src_loc() }} lines of
     code" to `apidocs/`, new tab.
   - The hidden title uses `h1:first-of-type`.
2. `mkdocs.yml`: the nav, one "to come" page per group.
   - Home, Get Started, Tools (Item, Mailbox, Pool, Master), API
     Reference, Patterns, Examples, Background, Errors.
   - Only a frame. ZTK DOCS 03, the inventory, fills the groups.
   - A `validation` block, as paternitas. The logo and favicon paths
     point at files that exist. Hook `new_tab_links.py`.
3. B32: `hooks/new_tab_links.py`, `tools/fix_md_hardbreaks.sh`,
   `tools/fix_md_lists.sh` from paternitas. The fix scripts touch only
   `kitchen/docs/`.
4. `tools/build_site.sh`: `mkdocs build --strict`.

## Checks

- `mkdocs build --strict` for ztk passes.
- Three ztk gates. Six paternitas gates.

## Not in this stage

- No page text beyond "to come". No change to ztk's code.
