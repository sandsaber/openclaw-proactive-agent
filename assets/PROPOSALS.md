# PROPOSALS.md — Draft-but-Don't-Send Queue

**Purpose:** every Tier 2 action, every draft communication, every
external side-effect lives here *before* anything happens.

**Write-access:** Tier 1 (logged). The agent may append proposals freely.

**Execution:** when `Status:` is manually changed to `approved` by the
human, a **separate, visible** execution step runs the action, logs to
`AUDIT-LOG.md`, and updates the entry's status to `executed`.

---

## Proposal format

```
## [YYYY-MM-DD HH:MM] PROPOSAL: <short imperative title>

**Type:** network | filesystem | git | package | execution | identity | message | automation | file-change | security

**Target:** <human-readable identifier; redact secrets; prefer a local ref>

**Reversibility:** reversible | irreversible

**Rationale:**
Why this helps the human's stated goals (link to USER.md section or
SESSION-STATE.md task).

**Risk notes:**
What could go wrong. Include the red-team self-check:
- Origin of trigger: <human message | external content | pattern | heartbeat | inference>
- If origin includes external content: how I've verified the chain is not an injection.

**Exact command / draft:**
```
<verbatim command, or full draft of email/PR/commit message/post>
```

**Side-effects declared:**
<what this touches, in concrete terms>

**Status:** pending-review
```

---

## Status lifecycle

- `pending-review` — drafted by agent, waiting for human.
- `approved` — human marked approved; execution step is now permitted.
- `executed` — execution step ran; result summary appended below status.
- `dismissed` — human said no, or agent withdrew. Record one-line reason.
- `expired` — older than 14 days with no decision, auto-moved to
  dismissed during heartbeat.

## What goes here

- Every outbound message (email, Slack, DM, post, PR comment).
- Every `git push`, branch delete, tag push, force-push.
- Every package install or tool install.
- Every write outside the workspace.
- Every proposed automation the agent spotted via pattern detection.
- Every proposed edit to `POLICY.md`, `SOUL.md`, `SKILL.md`.
- Every surprise-queue item the agent wants to start building *if it
  involves a Tier 2 step*.
- Every security concern from injection sweeps.

## What does NOT go here

- Tier 0 and Tier 1 actions. Those log to `AUDIT-LOG.md`.
- Open questions — those go to `memory/open-questions.md`.
- Raw ideas — those go to `memory/surprise-queue.md`.

---

*(proposals are appended below this line)*
