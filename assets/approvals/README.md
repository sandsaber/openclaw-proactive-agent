# approvals/ — Tier 2 approval artifacts

This directory holds the canonical record of every approved Tier 2 proposal.

## Write access

**Agent: none.** Approvals are created only by `scripts/approve-proposal.sh`,
which refuses to run without a controlling TTY. Runtime hooks should deny any
agent-initiated write into this directory.

## File format

Each approval is `<proposal-sha256>.approved`, a YAML-like record:

```yaml
proposal_id: <sha256 of the proposal body at approval time>
proposal_sha256: <same>
proposal_title: <human-readable title of the proposal>
approved_at: <UTC ISO8601>
approved_by: <user@host>
single_use: true
consumed_at: null
```

## Lifecycle

1. Agent writes a `Type: …` entry into `assets/PROPOSALS.md` with
   `Status: pending-review`.
2. Human runs `./scripts/approve-proposal.sh`, picks the proposal, confirms
   with "yes". Script writes `<sha>.approved` here and logs a TIER-2
   approval-granted entry to `AUDIT-LOG.md`.
3. A separate executor step (runtime hook, human-invoked script, or manual)
   verifies:
   - A matching `<sha>.approved` file exists here.
   - `consumed_at` is `null`.
   - Recomputed sha256 of the proposal body in `PROPOSALS.md` still equals
     `proposal_sha256` (TOCTOU guard).
   Then it runs the action, sets `consumed_at`, and logs a TIER-2 executed
   entry to `AUDIT-LOG.md`.
4. `HEARTBEAT.md §8` moves approvals older than 14 days with
   `consumed_at: null` into `expired/`.

## Why per-file instead of a flag in PROPOSALS.md

The agent can write freely to `PROPOSALS.md` (Tier 0). If approval were a
`Status: approved` string inside that file, the agent could approve its own
proposals. Moving approval to a separate directory that the agent cannot
write closes that bypass. See `SECURITY-AUDIT.md` finding F-02.
