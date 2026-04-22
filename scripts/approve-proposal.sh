#!/usr/bin/env bash
# approve-proposal.sh — human-gated approval of PROPOSALS.md entries.
#
# Why: the agent has Tier 0 write to PROPOSALS.md. If approval were stored as
# a flag the agent can flip, the whole Tier 2 gate collapses. This script is
# the only sanctioned way to move a proposal from draft to executable. It
# REFUSES to run without a controlling TTY, so an agent-initiated invocation
# fails immediately.
#
# What it does:
#   1. Lists proposals in PROPOSALS.md whose Status is "pending-review".
#   2. Prompts the human to pick one (by number).
#   3. Displays the full body and requires the human to type 'yes' exactly.
#   4. Writes assets/approvals/<sha256-of-proposal-body>.approved with
#      single_use: true and consumed_at: null.
#   5. Appends a TIER-2 approval-granted entry to assets/AUDIT-LOG.md via
#      scripts/audit-log-append.sh (so the approval itself is chained).
#
# What it does NOT do:
#   - Execute the approved action. Execution is a separate Tier-2 step that
#     must verify the .approved file, match sha256 against the current
#     proposal body (TOCTOU guard), flip consumed_at, and log again.
#
# Exit codes: 0 ok / nothing to do, 3 script error / bad input.

set -euo pipefail

if [ ! -t 0 ] || [ ! -t 1 ]; then
  echo "approve-proposal: refuses to run without a controlling TTY." >&2
  echo "Approvals must come from a human, not an automated pipeline." >&2
  exit 3
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROPOSALS="assets/PROPOSALS.md"
APPROVALS_DIR="assets/approvals"

[ -f "$PROPOSALS" ] || { echo "PROPOSALS.md not found at $PROPOSALS" >&2; exit 3; }
mkdir -p "$APPROVALS_DIR"

sha256_of_stream() {
  { shasum -a 256 2>/dev/null | awk '{print $1}'; } \
    || { sha256sum 2>/dev/null | awk '{print $1}'; } \
    || echo ""
}

# Locate every real proposal (timestamped PROPOSAL header — not the template).
mapfile -t starts < <(grep -nE '^## \[[0-9]{4}-[0-9]{2}-[0-9]{2}.*PROPOSAL:' "$PROPOSALS" | cut -d: -f1)

if [ "${#starts[@]}" -eq 0 ]; then
  echo "No proposals in $PROPOSALS."
  exit 0
fi

total_lines=$(wc -l < "$PROPOSALS")
titles=()
bodies=()
for i in "${!starts[@]}"; do
  start="${starts[$i]}"
  next_idx=$((i+1))
  if [ "$next_idx" -lt "${#starts[@]}" ]; then
    end=$(( starts[$next_idx] - 1 ))
  else
    end="$total_lines"
  fi
  body=$(sed -n "${start},${end}p" "$PROPOSALS")
  if printf '%s\n' "$body" | grep -qE 'Status:[[:space:]]*pending-review'; then
    title=$(printf '%s\n' "$body" | head -1 | sed 's/^## //')
    titles+=("$title")
    bodies+=("$body")
  fi
done

if [ "${#titles[@]}" -eq 0 ]; then
  echo "No pending-review proposals in $PROPOSALS."
  exit 0
fi

echo "Pending-review proposals:"
for i in "${!titles[@]}"; do
  printf "  [%d] %s\n" "$((i+1))" "${titles[$i]}"
done

echo
read -r -p "Approve which? [1-${#titles[@]} / q to cancel]: " choice
case "$choice" in
  q|Q|"") echo "Cancelled."; exit 0;;
  ''|*[!0-9]*) echo "Not a number: $choice" >&2; exit 3;;
esac
if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#titles[@]}" ]; then
  echo "Out of range: $choice" >&2; exit 3
fi
idx=$((choice-1))

echo
echo "===== Proposal #$choice ====="
printf '%s\n' "${bodies[$idx]}"
echo "============================"
echo
read -r -p "Approve this? (type 'yes' exactly to confirm): " confirm
[ "$confirm" = "yes" ] || { echo "Not approved."; exit 0; }

proposal_sha=$(printf '%s' "${bodies[$idx]}" | sha256_of_stream)
[ -n "$proposal_sha" ] || { echo "sha256 failed." >&2; exit 3; }

approval_file="$APPROVALS_DIR/$proposal_sha.approved"
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
approver="$(whoami 2>/dev/null || echo unknown)@$(hostname -s 2>/dev/null || echo unknown)"

cat > "$approval_file" <<EOF
proposal_id: $proposal_sha
proposal_sha256: $proposal_sha
proposal_title: ${titles[$idx]}
approved_at: $timestamp
approved_by: $approver
single_use: true
consumed_at: null
EOF

echo "Approval recorded: $approval_file"

entry=$(cat <<EOF
[$timestamp] TIER-2 approval-granted
Proposal: ${titles[$idx]}
Approved-by: $approver
Approval file: $approval_file
Proposal sha256: $proposal_sha
Single-use: true
Outcome: approval-recorded (execution is a separate step; executor must set consumed_at)
EOF
)

if [ -x "scripts/audit-log-append.sh" ]; then
  printf '%s\n' "$entry" | scripts/audit-log-append.sh
else
  {
    printf '\n'
    printf '%s\n' "$entry"
  } >> assets/AUDIT-LOG.md
fi

echo "Logged to assets/AUDIT-LOG.md."
echo
echo "Next step: the approved proposal can now be executed. The executor MUST:"
echo "  1. Recompute sha256 of the current proposal body in PROPOSALS.md."
echo "  2. Verify it matches $proposal_sha (TOCTOU guard)."
echo "  3. Run the proposed action."
echo "  4. Flip consumed_at in $approval_file to the current timestamp."
echo "  5. Log a TIER-2 'executed' entry to AUDIT-LOG.md."
