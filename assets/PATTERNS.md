# PATTERNS.md — Pattern Ledger

**Purpose:** track repeated requests. At N≥3, file an automation proposal.

**Write-access:** Tier 0 (append freely; incrementing counts).

---

## Pattern format

```
## <short pattern name>

**First seen:** YYYY-MM-DD
**Last seen:** YYYY-MM-DD
**Count:** <n>
**Example requests:**
- [YYYY-MM-DD] "…"
- [YYYY-MM-DD] "…"
- [YYYY-MM-DD] "…"

**Proposal filed:** PROPOSALS.md § <title>  (when count ≥ 3)
**Status:** observing | proposed | automated | dismissed
```

---

## Rules

- Don't propose an automation until **three independent occurrences**.
  Close misses (same week, overlapping context) count as one.
- Dismissed patterns stay here — annotate why — so the agent doesn't
  re-propose in a month.
- When the human approves an automation, the automation lives as a
  script in `scripts/`, its tier is declared in `TOOLS.md`, and the
  pattern's status becomes `automated`.
- Automations don't run autonomously just because they exist. They are
  invoked on the human's command or a Tier 1 scheduled reminder.

---

*(patterns are appended below this line)*
