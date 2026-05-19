#!/usr/bin/env bash
# audit-orphans.sh — Surface rules/ and references/ files with zero inbound links.
#
# Replaces audit-references.sh + audit-route-paths.sh. An orphan is a file in
# rules/ or references/ whose relative path does not appear (outside fenced
# code blocks) in any workflow / rule / reference / top-level shell. Either
# the activation pointer was never added, or the routing that used to mention
# it was removed and the file lingered.
#
# Heuristic only: prose mentions of the concept without the path do not count.
# Use judgment before removing anything. The dropped "route-path strict" check
# (was: file must lie on a routing.yaml path) is now manual — `grep -rn <file>`
# from the skill root tells you the same thing.
#
# Usage (run from the skill root, the dir containing rules/+references/):
#   bash audit-orphans.sh
#
# Exit code: 0 = no orphans, 1 = one or more orphans found.

set -euo pipefail

ROOT="$PWD"

SCAN_DIRS=("$ROOT/workflows" "$ROOT/rules" "$ROOT/references")
SCAN_FILES=()
for f in "$ROOT"/*.md; do
  [[ -f "$f" ]] && SCAN_FILES+=("$f")
done
# Nested under skills/<name>/? Also scan the parent harness shells.
if [[ -f "$ROOT/../../AGENTS.md" || -f "$ROOT/../../CLAUDE.md" ]]; then
  for s in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
    [[ -f "$ROOT/../../$s" ]] && SCAN_FILES+=("$ROOT/../../$s")
  done
fi

strip_fences() { awk 'BEGIN{f=0} /^```/ {f=1-f; next} !f' "$1"; }

mentions() {
  [[ -f "$2" ]] || return 1
  strip_fences "$2" | grep -qF "$1"
}

count_inbound() {
  local rel="$1" abs="$ROOT/$1" count=0 dir f
  for dir in "${SCAN_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue
    for f in "$dir"/*.md; do
      [[ -f "$f" && "$f" != "$abs" ]] || continue
      mentions "$rel" "$f" 2>/dev/null && count=$((count+1))
    done
  done
  for f in "${SCAN_FILES[@]:-}"; do
    [[ -n "$f" && -f "$f" && "$f" != "$abs" ]] || continue
    mentions "$rel" "$f" 2>/dev/null && count=$((count+1))
  done
  echo "$count"
}

ORPHANS=0
TOTAL=0
echo "Orphan scan — rules/ and references/ files with zero inbound links"
echo "==================================================================="
for dir_name in rules references; do
  dir_abs="$ROOT/$dir_name"
  [[ -d "$dir_abs" ]] || continue
  for f in "$dir_abs"/*.md; do
    [[ -f "$f" ]] || continue
    case "$(basename "$f")" in README.md|index.md) continue ;; esac
    TOTAL=$((TOTAL+1))
    rel="${f#$ROOT/}"
    if [[ "$(count_inbound "$rel")" -eq 0 ]]; then
      echo "ORPHAN  $rel"
      ORPHANS=$((ORPHANS+1))
    fi
  done
done

echo ""
echo "Summary: $ORPHANS orphan(s) / $TOTAL file(s)"
if [[ "$ORPHANS" -gt 0 ]]; then
  echo "For each orphan: add an activation pointer (workflow/rule/SKILL.md route) or delete it."
  exit 1
fi
exit 0
