#!/usr/bin/env bash
# injection-scan.sh — flag files that contain prompt-injection markers.
#
# Purpose: the daily heartbeat in HEARTBEAT.md §6 is a fallback. The
# preferred mode is a pre-read hook that invokes this script on every
# file the agent is about to read from memory/, SESSION-STATE.md, USER.md.
# If this script exits non-zero, the hook should replace the file content
# with a stub like:
#
#     [QUARANTINED: injection markers detected — see
#     memory/quarantine/<YYYY-MM-DDTHHMMSSZ>-<basename>.md]
#
# and move the real content into memory/quarantine/.
#
# Usage:
#   ./scripts/injection-scan.sh <file>        # scan one file
#   ./scripts/injection-scan.sh --sweep       # scan the default set
#   ./scripts/injection-scan.sh --quarantine <file>
#                                             # scan + auto-quarantine on hit
#
# Exit codes:
#   0 — clean
#   1 — one or more markers found
#   3 — script error / bad args

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# High-confidence markers from references/prompt-injection.md §2.
# Medium-confidence markers are scanned too; only high-confidence
# triggers an auto-quarantine recommendation.
HIGH_CONF=(
  '[Ii]gnore (all )?previous instructions'
  '[Dd]isregard the above'
  '[Yy]ou are now [A-Za-z]'
  '[Ff]rom now on,? (you are|respond as)'
  '[Nn]ew (system )?prompt'
  '[Yy]our (new )?instructions are'
  '^system:[[:space:]]'
  '<(system|developer|assistant)>'
  '[Dd]eveloper [Mm]ode'
  '[Jj]ailbreak'
  '\bDAN\b'
)
MED_CONF=(
  'please execute'
  '[Rr]un this command'
  '(open|fetch|visit) this URL'
  'For (testing|debugging) purposes'
  '[Oo]verride [A-Za-z]*policy'
  '[Bb]ypass [A-Za-z]*approval'
)

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit 3
}

scan_one() {
  local file="$1"
  local hits=0
  local hc_hits=0
  [ -f "$file" ] || { echo "injection-scan: not a file: $file" >&2; return 3; }

  for p in "${HIGH_CONF[@]}"; do
    if grep -nE "$p" "$file" >/dev/null 2>&1; then
      grep -nE "$p" "$file" 2>/dev/null | head -3 \
        | sed "s|^|  [HIGH] $file:|"
      hits=$((hits + 1))
      hc_hits=$((hc_hits + 1))
    fi
  done
  for p in "${MED_CONF[@]}"; do
    if grep -nE "$p" "$file" >/dev/null 2>&1; then
      grep -nE "$p" "$file" 2>/dev/null | head -3 \
        | sed "s|^|  [MED]  $file:|"
      hits=$((hits + 1))
    fi
  done

  if [ "$hits" -gt 0 ]; then
    printf '%s: %d hit(s) (%d high-confidence)\n' "$file" "$hits" "$hc_hits"
    return 1
  fi
  return 0
}

quarantine_one() {
  local file="$1"
  local stamp
  stamp=$(date -u +%Y-%m-%dT%H%M%SZ)
  local qdir="assets/memory/quarantine"
  mkdir -p "$qdir"
  local qfile="$qdir/${stamp}-$(basename "$file").md"

  {
    echo "# Quarantined content — original path: $file"
    echo "# Reason: injection-scan.sh detected markers at $(date -u +%FT%TZ)"
    echo "# Review this file and decide: (a) delete, (b) restore to $file, (c) ignore."
    echo "---"
    cat "$file"
  } > "$qfile"

  {
    echo "[QUARANTINED: injection markers detected on $(date -u +%FT%TZ)"
    echo " see $qfile for the original content.]"
  } > "$file"

  echo "Quarantined: $file -> $qfile"

  # Log to AUDIT-LOG.md via helper if available
  if [ -x "scripts/audit-log-append.sh" ]; then
    entry=$(cat <<ENTRY
[$(date -u +%Y-%m-%dT%H:%M:%SZ)] TIER-1 injection-quarantine
Reason: injection-scan.sh detected markers
Reversible-by: copy $qfile back to $file
Pre-action self-check: trigger = scheduled / pre-read hook; source file was external-derived content.
Outcome: content moved to $qfile; $file replaced with stub.
ENTRY
)
    printf '%s\n' "$entry" | scripts/audit-log-append.sh
  fi
}

case "${1:-}" in
  ""|-h|--help) usage ;;
  --sweep)
    shift
    total_hits=0
    for f in assets/memory/*.md assets/SESSION-STATE.md assets/USER.md \
             assets/MEMORY.md assets/PROPOSALS.md assets/PATTERNS.md; do
      [ -f "$f" ] || continue
      if ! scan_one "$f"; then
        total_hits=$((total_hits + 1))
      fi
    done
    [ "$total_hits" -eq 0 ] && { echo "clean sweep"; exit 0; }
    exit 1
    ;;
  --quarantine)
    shift
    [ $# -ge 1 ] || usage
    f="$1"
    if scan_one "$f"; then
      echo "clean: $f"
      exit 0
    else
      quarantine_one "$f"
      exit 1
    fi
    ;;
  *)
    f="$1"
    scan_one "$f"
    ;;
esac
