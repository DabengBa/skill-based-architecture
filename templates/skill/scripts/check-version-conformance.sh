#!/usr/bin/env bash
# check-version-conformance — verify a skill matches its conformance manifest.
#
# Usage:
#   bash check-version-conformance.sh <skill-root> [--conformance <path>]
#
# The conformance.yaml lists required sections / phrases / files. Each rule
# applies to a path resolved relative to <skill-root>.
#
# Default conformance.yaml path: <skill-root>/conformance.yaml
#
# Useful as part of update-upstream workflows to ensure downstream skills
# carry every section the upstream template promises. Complementary to
# check-upstream-changes.sh (changelog enforcement) and smoke-test.sh
# (structural budgets / routing) — none of those validates content presence.
#
# Exit codes: 0 pass, 1 fail, 2 usage error.

set -euo pipefail

SKILL_ROOT="${1:-}"
CONFORMANCE_PATH=""

if [[ -z "$SKILL_ROOT" || "$SKILL_ROOT" == "-h" || "$SKILL_ROOT" == "--help" ]]; then
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
  [[ -z "$SKILL_ROOT" ]] && exit 2 || exit 0
fi
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --conformance)
      [[ $# -ge 2 ]] || { echo "Missing value for --conformance" >&2; exit 2; }
      CONFORMANCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

[[ -d "$SKILL_ROOT" ]] || { echo "Skill root not found: $SKILL_ROOT" >&2; exit 2; }

if [[ -z "$CONFORMANCE_PATH" ]]; then
  CONFORMANCE_PATH="$SKILL_ROOT/conformance.yaml"
fi
[[ -f "$CONFORMANCE_PATH" ]] || { echo "conformance.yaml not found: $CONFORMANCE_PATH" >&2; exit 2; }

PARSED_FILE="$(mktemp)"
trap 'rm -f "$PARSED_FILE"' EXIT

if ! python3 - "$CONFORMANCE_PATH" > "$PARSED_FILE" <<'PY'
from __future__ import annotations

import sys
from pathlib import Path
def normalize(line: str) -> str:
    """Strip YAML comments while preserving hashes inside quoted strings."""
    out: list[str] = []
    quote: str | None = None
    for char in line:
        if char in ("'", '"'):
            if quote is None:
                quote = char
            elif quote == char:
                quote = None
            out.append(char)
        elif char == "#" and quote is None:
            break
        else:
            out.append(char)
    return "".join(out).rstrip()
def parse(path: Path) -> list[tuple[str, str, str]]:
    lines: list[tuple[int, str]] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = normalize(raw)
        if line.strip():
            lines.append((len(line) - len(line.lstrip()), line.strip()))

    records: list[tuple[str, str, str]] = []
    section: str | None = None
    item_indent: int | None = None
    list_indent: int | None = None
    current_file: str | None = None
    phrase_kind: str | None = None
    def flush_exists() -> None:
        if section == "required_files" and current_file:
            records.append(("EXISTS", current_file, ""))

    for indent, body in lines:
        if indent == 0 and body.endswith(":"):
            flush_exists()
            section = body[:-1].strip()
            item_indent = list_indent = None
            current_file = phrase_kind = None
            continue
        if section not in ("required_sections", "required_files"):
            continue
        if (
            phrase_kind is not None
            and list_indent is not None
            and indent >= list_indent
            and body.startswith("- ")
        ):
            phrase = body[2:].strip().strip('"').strip("'")
            if current_file and phrase:
                records.append((phrase_kind, current_file, phrase))
            continue
        if body.startswith("- ") and (item_indent is None or indent <= item_indent):
            flush_exists()
            item_indent = indent
            list_indent = None
            current_file = phrase_kind = None
            payload = body[2:].strip()
            if ":" in payload:
                key, _, value = payload.partition(":")
                if key.strip() in ("file", "path"):
                    current_file = value.strip().strip('"').strip("'")
            continue
        if ":" not in body:
            continue
        key, _, value = body.partition(":")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key in ("file", "path"):
            current_file = value
            phrase_kind = None
        elif key == "must_contain":
            phrase_kind = "CONTAINS"
            list_indent = indent + 2
        elif key == "must_not_contain":
            phrase_kind = "NOT_CONTAINS"
            list_indent = indent + 2
    flush_exists()
    return records
def main() -> int:
    path = Path(sys.argv[1])
    for kind, file, phrase in parse(path):
        print(f"{kind}\t{file}\t{phrase}")
    return 0
raise SystemExit(main())
PY
then
  echo "Failed to parse conformance.yaml" >&2
  exit 2
fi

if [[ ! -s "$PARSED_FILE" ]]; then
  echo "conformance.yaml produced no rules" >&2
  exit 2
fi

PASS=0
FAIL=0

red()   { printf '\033[31m%s\033[0m' "$*"; }
green() { printf '\033[32m%s\033[0m' "$*"; }

pass_msg() { PASS=$((PASS+1)); printf "  %s %s\n" "$(green OK)"   "$*"; }
fail_msg() { FAIL=$((FAIL+1)); printf "  %s %s\n" "$(red FAIL)" "$*"; }

echo "Skill root:  $SKILL_ROOT"
echo "Manifest:    $CONFORMANCE_PATH"
echo ""
echo "Required content"
echo "----------------"

while IFS=$'\t' read -r kind file phrase; do
  target="$SKILL_ROOT/$file"
  case "$kind" in
    CONTAINS)
      if [[ ! -f "$target" ]]; then
        fail_msg "$file -- file missing (cannot scan for: $phrase)"
        continue
      fi
      if grep -qF -- "$phrase" "$target"; then
        pass_msg "$file <- contains: $phrase"
      else
        fail_msg "$file <- MISSING: $phrase"
      fi
      ;;
    NOT_CONTAINS)
      if [[ ! -f "$target" ]]; then
        fail_msg "$file -- file missing (cannot scan forbidden phrase: $phrase)"
        continue
      fi
      if grep -qF -- "$phrase" "$target"; then
        fail_msg "$file <- FORBIDDEN: $phrase"
      else
        pass_msg "$file <- does not contain: $phrase"
      fi
      ;;
    EXISTS)
      if [[ -e "$target" ]]; then
        pass_msg "$file <- exists"
      else
        fail_msg "$file <- MISSING (file not found)"
      fi
      ;;
  esac
done < "$PARSED_FILE"

echo ""
echo "==========================="
if [[ "$FAIL" -eq 0 ]]; then
  printf "Results: %s passed, 0 failed\n" "$(green "$PASS")"
  printf "%s\n" "$(green 'Conformance check passed.')"
  exit 0
else
  printf "Results: %s passed, %s failed\n" "$(green "$PASS")" "$(red "$FAIL")"
  printf "%s\n" "$(red 'Conformance check failed.')"
  echo ""
  echo "If running as part of update-upstream: re-apply the missing sections"
  echo "from the upstream template, then re-run."
  exit 1
fi
