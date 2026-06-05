#!/usr/bin/env bash
# upstream-status.sh — Report which upstream UPSTREAM-CHANGES.md entries are newer
# than this project's recorded sync point (.upstream-sync). Diagnosis only; porting
# stays manual via workflows/update-upstream.md.
#
# NOT the same as the upstream repo's check-upstream-changes.sh (that is an
# upstream-side guard that a change added a changelog entry). This is a DOWNSTREAM
# "am I behind upstream, and what changed" reporter.
#
# Usage:
#   bash scripts/upstream-status.sh [skill-name|skill-root] [--upstream <url-or-path>]
#
# Exit: 0 = up to date · 1 = behind (entries listed) · 2 = usage / cannot determine
set -uo pipefail

TARGET=""; UPSTREAM_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --upstream) UPSTREAM_OVERRIDE="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: bash upstream-status.sh [skill-name|skill-root] [--upstream <url-or-path>]"
      echo "Lists UPSTREAM-CHANGES entries newer than .upstream-sync synced_sha. Exit 1 if behind."
      exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

# Resolve the skill root (where SKILL.md + .upstream-sync live).
if [[ -n "$TARGET" && -f "$TARGET/SKILL.md" ]]; then SKILL_ROOT="$TARGET"
elif [[ -n "$TARGET" && -f "skills/$TARGET/SKILL.md" ]]; then SKILL_ROOT="skills/$TARGET"
elif [[ -f "SKILL.md" ]]; then SKILL_ROOT="."
else echo "Usage: bash upstream-status.sh [skill-name|skill-root] [--upstream <url-or-path>]" >&2; exit 2; fi

SYNC_FILE="$SKILL_ROOT/.upstream-sync"
if [[ ! -f "$SYNC_FILE" ]]; then
  echo "No sync point: $SYNC_FILE not found."
  echo "Run workflows/update-upstream.md once — its final step creates this file."
  exit 2
fi

field() { grep -E "^$1:[[:space:]]*" "$SYNC_FILE" 2>/dev/null | head -1 | sed -E "s/^$1:[[:space:]]*//"; }
UPSTREAM="${UPSTREAM_OVERRIDE:-$(field upstream)}"
SYNCED_SHA="$(field synced_sha)"

if [[ -z "$UPSTREAM" || -z "$SYNCED_SHA" || "$SYNCED_SHA" == *"<"* ]]; then
  echo "FAIL: $SYNC_FILE needs a real 'upstream:' URL and 'synced_sha:' (run update-upstream.md to set them)." >&2
  echo "  current: upstream='$UPSTREAM' synced_sha='$SYNCED_SHA'" >&2
  exit 2
fi

# Get the upstream repo: reuse a local clone if given, else clone to a temp dir.
CLEAN=""; trap '[[ -n "$CLEAN" ]] && rm -rf "$CLEAN"' EXIT
if [[ -d "$UPSTREAM/.git" ]]; then
  REPO="$UPSTREAM"; git -C "$REPO" fetch -q 2>/dev/null || true
else
  CLEAN="$(mktemp -d)"; echo "Fetching upstream: $UPSTREAM"
  git clone -q "$UPSTREAM" "$CLEAN" 2>/dev/null || { echo "FAIL: cannot clone $UPSTREAM" >&2; exit 2; }
  REPO="$CLEAN"
fi

HEAD_SHA="$(git -C "$REPO" rev-parse HEAD 2>/dev/null || true)"
[[ -z "$HEAD_SHA" ]] && { echo "FAIL: no upstream HEAD found." >&2; exit 2; }

if [[ "$SYNCED_SHA" == "$HEAD_SHA" ]]; then
  echo "✓ Up to date with upstream ($HEAD_SHA)."; exit 0
fi

if ! git -C "$REPO" cat-file -e "${SYNCED_SHA}^{commit}" 2>/dev/null; then
  echo "⚠ Recorded synced_sha ($SYNCED_SHA) not found upstream (rebased or shallow clone?)."
  echo "  Showing the 8 most recent entries instead — verify manually:"
  git -C "$REPO" show "HEAD:UPSTREAM-CHANGES.md" 2>/dev/null | grep -E '^## [0-9]{4}-' | head -8 | sed 's/^/  /'
  exit 1
fi

# New entries = dated '## ' headings added to the changelog since synced_sha.
NEW="$(git -C "$REPO" diff "$SYNCED_SHA..$HEAD_SHA" -- UPSTREAM-CHANGES.md 2>/dev/null \
        | grep -E '^\+## [0-9]{4}-' | sed -E 's/^\+//' || true)"

if [[ -z "$NEW" ]]; then
  echo "✓ No new UPSTREAM-CHANGES entries since your sync point."
  echo "  (Upstream HEAD moved $SYNCED_SHA → $HEAD_SHA, but nothing downstream-facing.)"
  exit 0
fi

COUNT="$(printf '%s\n' "$NEW" | grep -c '^##' || true)"
echo "▲ Behind by $COUNT UPSTREAM-CHANGES entr$([[ "$COUNT" == 1 ]] && echo y || echo ies)."
echo "  your sync point : $SYNCED_SHA"
echo "  upstream HEAD   : $HEAD_SHA"
echo ""
echo "New since your sync point (read these in upstream UPSTREAM-CHANGES.md for refresh guidance):"
printf '%s\n' "$NEW" | sed 's/^/  /'
echo ""
echo "→ Port via workflows/update-upstream.md, then set 'synced_sha: $HEAD_SHA' in $SYNC_FILE"
exit 1
