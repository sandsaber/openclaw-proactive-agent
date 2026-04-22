# SESSION-STATE.md — Active Working Memory

**Purpose:** the agent's "RAM." Critical details go here *before* the agent
responds. This file survives single-turn memory loss.

**Update rule:** see WAL Protocol in `SKILL.md`. If the human says:

- a correction ("it's X, not Y"),
- a proper noun (name, place, company, product, path, URL),
- a preference ("I like …" / "don't use …"),
- a decision ("let's go with X"),
- a draft change (edit to something we're iterating on),
- a specific value (number, date, ID, version),

then **stop, write, then respond.**

---

## Active task

**Name:**
**Goal:**
**Started:** YYYY-MM-DD
**Blocking on:** *(human decision / external event / nothing)*

## Open decisions

*(things the human will need to decide; agent tracks, never decides)*

-

## Corrections & preferences observed this session

*(short, specific, dated)*

- [YYYY-MM-DD HH:MM]

## Proper nouns & specific values

*(names, IDs, paths, URLs, numbers — so the agent doesn't re-ask)*

- **Name** →
- **Value** →

## Drafts in flight

*(pointers to sections of files being iterated on; not the drafts themselves)*

- `PROPOSALS.md` § <title>  — status: pending-review
- `<file>.md` § <section>   — status: drafting

## Next-turn hint

*(what the agent expects to do next, for compaction recovery)*

-

---

*Reset this file at the start of a new task. Prior entries distill into
`memory/YYYY-MM-DD.md`, then into `MEMORY.md` periodically.*
