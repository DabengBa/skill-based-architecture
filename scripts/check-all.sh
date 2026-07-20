#!/usr/bin/env bash
# Run the upstream repo's full maintenance check suite.

set -euo pipefail

MODE="worktree"
BASE="${UPSTREAM_CHANGES_BASE:-HEAD}"

usage() {
  cat <<'EOF'
Usage: scripts/check-all.sh [--base <git-ref>] [--staged]

Runs the self-hosting upstream maintenance checks used before commit/push:
  - upstream change-note guard
  - upstream supersedes refs check
  - template routing manifest check
  - template SessionStart hook runtime contract
  - temporary downstream scaffold smoke test
  - self-hosting shells + activation check
  - whitespace diff check
  - single-root + two-root integrity contracts
  - self-hosting scenario checks
  - self-hosting phase 7 smoke test
  - self-hosting orphan audit
  - template content conformance (downstream contract)
  - self-hosting content conformance (upstream-canon)

Default mode checks the working tree. Use --staged from a pre-commit hook to
check the pending commit for UPSTREAM-CHANGES.md coverage and whitespace.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      [[ $# -ge 2 ]] || { echo "Missing value for --base" >&2; exit 2; }
      BASE="$2"
      shift 2
      ;;
    --staged)
      MODE="staged"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

run() {
  local label="$1"
  shift
  printf '\n==> %s\n' "$label"
  "$@"
}

check_downstream_scaffold() {
  local tmp name summary upstream_ref upstream_sha status
  tmp="$(mktemp -d)"
  name="sample-skill"
  summary="Sample downstream scaffold for upstream regression checks"
  upstream_ref="$(git -C "$ROOT" config --get remote.origin.url 2>/dev/null || printf '%s' "$ROOT")"
  upstream_sha="$(git -C "$ROOT" rev-parse HEAD)"

  set +e
  (
    set -euo pipefail
    cd "$tmp"
    mkdir -p "skills/$name"
    cp -R "$ROOT/templates/skill/." "skills/$name/"
    mv "skills/$name/SKILL.md.template" "skills/$name/SKILL.md"
    cp -R "$ROOT/templates/shells/." .
    mv ".cursor/skills/{{NAME}}/SKILL.md.template" ".cursor/skills/{{NAME}}/SKILL.md"
    mv ".cursor/skills/{{NAME}}" ".cursor/skills/$name"

    find "skills/$name" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor \
      -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.yaml' \) \
      -exec sed -i.bak \
        -e "s/{{NAME}}/$name/g" \
        -e "s/{{SUMMARY}}/$summary/g" \
        -e "s/<trigger phrase 1>/fix sample bug/g" \
        -e "s/<trigger phrase 2>/plan sample feature/g" \
        -e "s/<trigger phrase 3 \\/ 中文触发短语>/更新示例技能/g" \
        -e "s/<condition 1>/working on the sample project/g" \
        -e "s/<condition 2>/maintaining sample project rules/g" \
        -e "s/FILL:/FILLED:/g" \
        {} +
    find . -name '*.bak' -type f -delete

    printf 'upstream: %s\nsynced_sha: %s\nsynced_date: %s\n' \
      "$upstream_ref" "$upstream_sha" "$(date +%F)" > "skills/$name/.upstream-sync"

    bash "skills/$name/scripts/sync-routing.sh" "$name" --check
    bash "skills/$name/scripts/smoke-test.sh" "$name" --phase 8
    (
      cd "skills/$name"
      bash scripts/audit-orphans.sh
      bash scripts/route-reachability.sh
    )
  )
  status=$?
  set -e
  rm -rf "$tmp"
  return "$status"
}

check_two_root_integrity() {
  local tmp skill_root code_root routing
  tmp="$(mktemp -d)"
  skill_root="$tmp/skill"
  code_root="$tmp/code"
  routing="$skill_root/routing.yaml"
  mkdir -p "$skill_root/rules" "$skill_root/workflows" "$skill_root/gotchas" "$code_root/gotchas"

  printf '# Base\n' > "$skill_root/rules/base.md"
  printf '# Run\n' > "$skill_root/workflows/run.md"
  printf '# Code shared\n' > "$code_root/gotchas/shared.md"
  printf '# Skill collision\n' > "$skill_root/gotchas/shared.md"
  cat > "$routing" <<'YAML'
path_resolution:
  skill_root: {owns: [rules/**, workflows/**, gotchas/**]}
  code_root: {owns: [gotchas/**]}
always_read:
  - skill:rules/base.md
tasks:
  - id: fixture
    required_reads:
      - code:gotchas/shared.md
    workflow: skill:workflows/run.md
YAML

  if (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh" --namespace skill --routing "$routing") >/dev/null 2>&1; then
    echo "two-root audit failed to isolate a same-path skill:/code: collision" >&2
    rm -rf "$tmp"
    return 1
  fi
  if (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh" --namespace skill --routing "$routing") >/dev/null 2>&1; then
    echo "two-root route check failed to isolate a same-path skill:/code: collision" >&2
    rm -rf "$tmp"
    return 1
  fi

  rm "$skill_root/gotchas/shared.md"
  (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh" --namespace skill --routing "$routing")
  (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh" --namespace skill --routing "$routing")
  (cd "$code_root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh" --namespace code --routing "$routing")
  (cd "$code_root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh" --namespace code --routing "$routing")
  rm -rf "$tmp"
}

check_conformance_option_like_phrases() {
  local tmp script
  tmp="$(mktemp -d)"
  script="$ROOT/templates/skill/scripts/check-version-conformance.sh"
  printf '%s\n' '# Fixture' '--present' > "$tmp/fixture.md"

  cat > "$tmp/pass.yaml" <<'YAML'
required_sections:
  - file: fixture.md
    must_contain:
      - "--present"
YAML
  bash "$script" "$tmp" --conformance "$tmp/pass.yaml" >/dev/null

  cat > "$tmp/fail.yaml" <<'YAML'
required_sections:
  - file: fixture.md
    must_not_contain:
      - "--present"
YAML
  if bash "$script" "$tmp" --conformance "$tmp/fail.yaml" >/dev/null 2>&1; then
    echo "conformance must_not_contain accepted an option-like phrase that exists" >&2
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"
}

if [[ "$MODE" == "staged" ]]; then
  run "upstream change-note guard (staged)" bash scripts/check-upstream-changes.sh --base "$BASE" --staged
  run "whitespace diff check (staged)" git diff --cached --check
else
  run "upstream change-note guard" bash scripts/check-upstream-changes.sh --base "$BASE"
  run "whitespace diff check" git diff --check
fi

run "upstream supersedes refs check" bash scripts/check-upstream-supersedes.sh

run "template routing manifest check" bash templates/skill/scripts/sync-routing.sh templates/skill --check
run "template SessionStart hook runtime contract" bash scripts/check-template-hooks.sh
run "temporary downstream scaffold smoke test" check_downstream_scaffold
run "single-root + two-root integrity contracts" check_two_root_integrity
run "conformance option-like phrase contract" check_conformance_option_like_phrases
run "self-hosting shells + activation check" bash scripts/check-self-shells.sh
run "self-hosting scenario checks" bash scripts/check-self-scenarios.sh
run "self-hosting phase 7 smoke test" bash templates/skill/scripts/smoke-test.sh skill-based-architecture --phase 7
run "self-hosting orphan audit" bash templates/skill/scripts/audit-orphans.sh
run "template content conformance" bash templates/skill/scripts/check-version-conformance.sh templates/skill
run "self-hosting content conformance" bash templates/skill/scripts/check-version-conformance.sh . --conformance references/self-hosting-conformance.yaml

printf '\nAll upstream maintenance checks passed.\n'
