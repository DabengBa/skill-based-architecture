# Skeleton/Flesh Axis — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement task-by-task. Steps use `- [ ]` checkboxes.

**Goal:** Re-base the skill content axis on abstraction (骨架 invariant theory vs 肉 current-code facts): purify `architecture/` to abstract theory only, move code maps to `references/`, reconcile SBA docs, propagate to chaos & chaos_web.

**Architecture:** Flat tiers kept (no parent dirs). The skeleton/flesh distinction is a conceptual lens realized by (a) tier purity, (b) a top-level declaration, (c) the migration playbook's judgement test. Validation = the framework's own scripts. Spec: [prd.md](prd.md).

**Tech Stack:** Markdown docs + bash validation scripts (`check-all.sh`, `audit-orphans.sh`, `route-reachability.sh`, `smoke-test.sh`). Three repos: SBA (`/Users/shiqi/IdeaProjects/skill-based-architecture`), chaos (`/Users/shiqi/chaos`), chaos_web (`/Users/shiqi/chaos_web`).

**The judgement test (used throughout):** *"After a big refactor that renames modules and moves files, is this statement still true and useful? Yes → skeleton (architecture/workflows/rules). It describes the current code (a map / name / path / a landmine at a symbol) → flesh (references/conventions/gotchas)."*

---

## Task 1: SBA — reframe the axis docs to skeleton/flesh

**Files:**
- Modify: `SKILL.md` (§ Content Classification table + intro line)
- Modify: `references/layout.md` (the Full-tier split note)
- Modify: `TEMPLATES-GUIDE.md` (§ Classification Guide)
- Modify: `references/progressive-rigor.md` (trigger 3 "Rate-of-change tangle")
- Rename + reframe: `references/rate-of-change-split.md` → `references/skeleton-flesh-split.md`
- Modify inbound links to the renamed file: `SKILL.md`, `references/progressive-rigor.md`, `references/layout.md`, `workflows/full-migration.md`, `UPSTREAM-CHANGES.md`

- [ ] **Step 1: Reframe SKILL.md Content Classification.** Change the table's framing from "rate of change" to "abstraction (骨架/肉)". Keep the 6 rows but re-caption: `architecture/` = "Abstract design theory (skeleton — invariant)"; `references/` = "Code maps + background (flesh — current-state, drifts)"; `conventions/`/`gotchas/` = flesh. The first-column header note becomes: `tier by abstraction — 骨架 (architecture/workflows/rules: invariant theory) vs 肉 (conventions/gotchas/references: current-code facts); see references/skeleton-flesh-split.md`. Keep body ≤ 90 lines (it's at 90 — net-zero edit; if over, trim the "Changes" column header text).

- [ ] **Step 2: Rename + reframe the playbook.** `git mv references/rate-of-change-split.md references/skeleton-flesh-split.md`. Reframe its title + §1 around the skeleton/flesh judgement test (above). The "four buckets" become: architecture (abstract theory/skeleton), conventions (volatile house style/flesh), gotchas (per-module landmines/flesh), **code maps → references/ (flesh)**, methodology stays in rules/. Add a one-line note: "rate of change is a correlated heuristic that mislabels slow-drifting code maps as architecture; abstraction is the real cut." Keep §2-§6 (no-dup authoring, path-migration, routed index hubs, routing re-derivation, validation) — they're axis-agnostic; s/rate-of-change/skeleton-flesh/ in prose where it names the axis.

- [ ] **Step 3: Update the 5 inbound links** to `skeleton-flesh-split.md` (was `rate-of-change-split.md`) in `SKILL.md`, `references/progressive-rigor.md`, `references/layout.md`, `workflows/full-migration.md`, `UPSTREAM-CHANGES.md`. Grep to find them: `grep -rn 'rate-of-change-split' . --include='*.md'`.

- [ ] **Step 4: Reframe progressive-rigor trigger 3 + layout + TEMPLATES-GUIDE.** In `references/progressive-rigor.md` trigger 3: lead with the skeleton/flesh distinction — "split `rules/` by **abstraction**: abstract design theory → `architecture/`, current-code maps → `references/`, volatile house style → `conventions/`, landmines → per-module `gotchas/`; methodology stays in `rules/`." In `references/layout.md` and `TEMPLATES-GUIDE.md § Classification Guide`: change "stable structure → architecture/" to "**abstract design theory** → architecture/ (NOT the module map — that's a current-code fact → references/)".

- [ ] **Step 5: Validate.** Run: `cd /Users/shiqi/IdeaProjects/skill-based-architecture && bash scripts/check-all.sh`. Expected: "All upstream maintenance checks passed." (Catches the renamed file's broken links — fix any the grep in Step 3 missed.) Also confirm SKILL.md body ≤ 90: `awk 'NR==1{next} /^---$/{c++;next} c>=1{b++} END{print b}' SKILL.md` → ≤ 90.

- [ ] **Step 6: Commit.**

```bash
git add -A
git commit -m "refactor: re-base content axis on skeleton/flesh (abstraction over rate-of-change)"
```

---

## Task 2: SBA — purity prompt + changelog

**Files:**
- Modify: `templates/skill/workflows/task-closure.md` (path-integrity gate / rationalizations)
- Modify: `UPSTREAM-CHANGES.md` (new entry)

- [ ] **Step 1: Add the skeleton purity prompt.** In `templates/skill/workflows/task-closure.md`, in the path-integrity gate (next to the audit-orphans / route-reachability lines), add a non-script review line: "If this task added an `architecture/` file: apply the skeleton test — is it an invariant principle, or a map/name/path/symbol of the current code? A map belongs in `references/`, not `architecture/`. (Not script-checkable — purity is human discipline.)"

- [ ] **Step 2: Add UPSTREAM-CHANGES entry** dated 2026-06-24, title "Content axis re-based on skeleton/flesh (abstraction)". Cover: architecture/ definition tightened to abstract theory only; code maps → references/; `rate-of-change-split.md` renamed `skeleton-flesh-split.md` with the judgement test; rate-of-change demoted to a heuristic note. Downstream guidance: move module/dir maps out of `architecture/` into `references/`; re-run `audit-orphans` + `route-reachability`.

- [ ] **Step 3: Validate.** `bash scripts/check-all.sh` → green.

- [ ] **Step 4: Commit.**

```bash
git add -A
git commit -m "docs: skeleton purity prompt in task-closure + UPSTREAM-CHANGES entry"
```

- [ ] **Step 5: Push SBA** (per this repo's direct-to-main pattern): `git push origin main`.

---

## Task 3: chaos — purify architecture/

**Files (under `/Users/shiqi/chaos/skills/chaos/`):**
- Move: `architecture/modules-and-packages.md` → `references/modules-and-packages.md`
- Move: `architecture/dal-layout.md` → `references/dal-layout.md`
- Modify: `architecture/call-chains.md` (purge concrete class-named chains → keep direction principle; move the concrete chain diagram to `references/modules-and-packages.md` or a `references/call-map.md`)
- Modify: `architecture/response-envelope.md` (move field-name/class bindings → `conventions/`; keep the mechanism principle)
- Modify: `architecture/index.md` (drop moved files; keep skeleton files)
- Modify: `references/` (add the moved maps; mark them "drifts with refactor, verify against code")
- Modify: `routing.yaml` (if any required_read pointed at a moved file — they point at `architecture/index.md`, so likely unchanged; verify)
- Modify: `SKILL.md` (manifest: move the two files from architecture list to references list)

- [ ] **Step 1: Move the two clear maps.** `cd /Users/shiqi/chaos/skills/chaos && git mv architecture/modules-and-packages.md references/modules-and-packages.md && git mv architecture/dal-layout.md references/dal-layout.md` (use `mv` if not git-tracked). Add a top line to each: `> 代码地图(肉):随 refactor 漂,以真实代码为准。`

- [ ] **Step 2: Purge call-chains.md.** Keep only the abstract direction principle (web→biz→core→dal, no reverse deps, RPC contract ripples to consumers). Cut the concrete `class XxxManagerImpl`-named chain listings; append those to `references/modules-and-packages.md` (they're map detail). If little abstract content remains, merge call-chains' principle into `architecture/manager-layer.md` and delete the file.

- [ ] **Step 3: Purge response-envelope.md.** Keep the mechanism principle (unified envelope, errors in-band HTTP 200, pagination is a boundary conversion). Move the concrete field names (success/errorCode/msg/traceId) + class names (GlobalResponseAdvice/BizExceptionHandler) into a `conventions/response-envelope.md` (house-style symbols), registered in `conventions/index.md`.

- [ ] **Step 4: Update hubs + manifest.** In `architecture/index.md`: remove the moved/merged files, keep only skeleton (api-contract, manager-layer, prohibitions, transactions-locks, integration-and-config, call-chains-if-kept, response-envelope). In `references/` add a hub/index line for the new maps if a references index exists; else they get inbound from `SKILL.md`. In `SKILL.md` manifest: move the two maps from the architecture list to the references list; add `conventions/response-envelope.md` to conventions list.

- [ ] **Step 5: Validate.** From repo root `/Users/shiqi/chaos`:

```bash
cd /Users/shiqi/chaos
bash skills/chaos/scripts/route-reachability.sh chaos 2>/dev/null || (cd skills/chaos && bash scripts/route-reachability.sh)
(cd skills/chaos && bash scripts/audit-orphans.sh)
bash /Users/shiqi/IdeaProjects/skill-based-architecture/templates/skill/scripts/smoke-test.sh chaos | grep -E 'constraint surface|gotchas/ tier|❌'
```

Expected: audit-orphans `0 orphan(s)`; route-reachability `0 unreachable`; smoke-test tier lines ✅ (remaining ❌ = pre-existing aii shell artifacts). **Note:** run audit-orphans/route-reachability from the skill dir (`skills/chaos`) per their `$PWD` contract.

- [ ] **Step 6: Commit (chaos repo).**

```bash
cd /Users/shiqi/chaos
git add -A
git commit -m "refactor(skill): purify architecture/ to abstract skeleton; move code maps to references/"
```

---

## Task 4: chaos_web — purify architecture/

**Files (under `/Users/shiqi/chaos_web/skills/chaos-web/`):** chaos_web's `architecture/` is already mostly skeleton (hybrid-rendering / schema-layering / prohibitions are principles). Only the stack snapshot is flesh.

- [ ] **Step 1: Audit each architecture/ file against the test.** Read `architecture/{tech-baseline,hybrid-rendering,schema-layering,prohibitions}.md`. Classify: `hybrid-rendering`, `schema-layering`, `prohibitions` = skeleton (keep). `tech-baseline` (version list React18/TS4.9/Amis3.6/...) = current-state stack fact → flesh.

- [ ] **Step 2: Move tech-baseline.** `cd /Users/shiqi/chaos_web/skills/chaos-web && git mv architecture/tech-baseline.md references/tech-baseline.md` (or `mv`). Add top line: `> 技术栈快照(肉):版本随升级漂。`

- [ ] **Step 3: Update hubs + manifest.** Remove `tech-baseline` from `architecture/index.md`; add it to the references list in `SKILL.md`. Verify `routing.yaml` required_reads (they point at `architecture/index.md`, so unchanged).

- [ ] **Step 4: Validate.** From `/Users/shiqi/chaos_web`:

```bash
cd /Users/shiqi/chaos_web/skills/chaos-web
bash scripts/audit-orphans.sh
bash scripts/route-reachability.sh
cd /Users/shiqi/chaos_web && bash skills/chaos-web/scripts/smoke-test.sh chaos-web | grep -E 'constraint surface|gotchas/ tier|❌'
```

Expected: 0 orphans, 0 unreachable, tier lines ✅.

- [ ] **Step 5: Commit (chaos_web repo).**

```bash
cd /Users/shiqi/chaos_web
git add -A
git commit -m "refactor(skill): move tech-stack snapshot out of architecture/ into references/ (flesh)"
```

---

## Task 5: Cross-check + memory

- [ ] **Step 1: Confirm architecture/ is pure across all three.** For chaos and chaos_web: `ls architecture/` — every remaining file should pass the skeleton test (no module trees, directory layouts, version snapshots, or concrete-symbol maps). Spot-read one or two to confirm they're principles, not maps.

- [ ] **Step 2: Update memory.** Append to `/Users/shiqi/.claude/projects/-Users-shiqi-IdeaProjects-skill-based-architecture/memory/taxonomy-tier-split.md`: the axis was re-based from rate-of-change to skeleton/flesh (abstraction); architecture/ = abstract theory only; code maps → references/; playbook renamed `skeleton-flesh-split.md`; chaos/chaos_web architecture/ purified. Keep it one concise entry.

---

## Self-Review (run before execution)

- **Spec coverage:** prd § ① (lens/tier) → Tasks 1,3,4. § ② (purify architecture) → Tasks 3,4. § ③ (SBA reconcile) → Task 1. § ④ (tooling) → no change (validated in 3,4,5). § ⑤ (purity prompt) → Task 2. § ⑥ (downstream) → Tasks 3,4. ✓
- **Placeholder scan:** Tasks describe exact files + exact moves + exact validation commands. The doc-content reframes (Content Classification, playbook) describe the precise change rather than reproduce full new text — acceptable for prose reframes where the executor has the current file + the judgement test. No "TBD".
- **Consistency:** the renamed file `skeleton-flesh-split.md` is updated in all 5 inbound links (Task 1 Step 3) and the new task-closure/UPSTREAM references (Task 2). The judgement test wording is identical in the plan header, prd, and the playbook §1.
