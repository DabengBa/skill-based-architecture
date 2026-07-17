# Reference — Progressive Rigor

Not every skill needs the full `skills/<name>/` tree. Start at the smallest tier that fits, and upgrade only when a concrete pressure fires. Default to the cheapest structure that works — over-structuring a small skill adds maintenance cost with no compression-survival benefit.

## The three tiers

| Tier | Layout | Use when | Typical SKILL.md size |
|---|---|---|---|
| **Single-file** | `SKILL.md` only (official minimum) | < 3 topics, no task routing needed, no lesson-capture history | ≤ 60 lines |
| **Folder-light** | `skills/<name>/SKILL.md` + `rules/` | 3–5 topics, OR 1 recurring workflow that needs step-by-step instructions, OR a growing list of project conventions | 60–115 lines total (description + body), `rules/` adds 1–3 files |
| **Full** | `skills/<name>/{SKILL,architecture,conventions,gotchas,workflows,references}/` (or a single `rules/` before the rate-of-change split) + thin shells + Cursor registration entry | ≥ 3 routed task types, gotcha log needs a home, multi-harness repo (Cursor + Claude + Codex + Gemini), or lessons-learned across multiple sessions | Up to dual cap (description ≤ 25 + body ≤ 90), multiple files per subdir |

## Upgrade triggers

Add structure when **any** of these fires, not before:

1. **Line pressure** — `SKILL.md` body crosses 90 lines (or description exceeds 25 lines) despite compression attempts. Move body content to a sub-file in the next tier down (e.g. workflows go to `workflows/` once you have 2+); split intent clusters in description when activate-when grows long.
2. **Recurrence pressure** — the same pitfall is recorded in Common Pitfalls twice, or the same question gets asked by the agent twice in different sessions. Promote it into a routed Gotcha entry organized by stable root cause. A single `references/gotchas.md` is the small-skill form. Split into module files only when real tasks select them independently; add `gotchas/index.md` only when task signals use it to choose the next file, never as a passive hub by default.
3. **Abstraction tangle (骨架/肉)** — a `rules/` (or `architecture/`) file mixes invariant design theory with current-code facts: a module map or directory layout (flesh) sits next to a layering principle (skeleton), so `architecture/` both drifts and diverges (re-describing the code instead of converging on the few invariants). Split by abstraction: abstract design theory → `architecture/`, **code maps** (module tree, dir layout, source index) → `references/`, house style → `conventions/`, landmines → per-module `gotchas/`; **methodology stays in `rules/`**. The most common Full-tier pressure for code-coupled skills — judgement test + full playbook: [skeleton-flesh-split.md](skeleton-flesh-split.md).
4. **Procedure pressure** — you catch yourself writing "how to do X in steps" inside a rule file. Steps belong in `workflows/`, not `rules/`. Create the `workflows/` directory.
5. **Harness-sharing pressure** — two harness entries (e.g. `AGENTS.md` and `CLAUDE.md`) need the same route lookup logic, or you're manually keeping them in sync. Move task data into `routing.yaml` and generate thin-shell blocks.
6. **Cross-session lesson pressure** — you want a lesson from today to persist into a `/clear`-fresh session next week. A single-file skill with no `references/` has no durable place for it.

**Downgrade is also fine.** If a skill lost a domain or shed complexity, collapse back. Structure serves the content, not the other way around. Empty `workflows/` or `references/` directories are a smell.

### Optional business-global-model pressure

Product/business projects may add `references/business/<module>.md` when stable domain meaning (types, macro flow, states, boundaries, invariants) is repeatedly needed to plan or classify bugs and is not obvious from code. Start absent and then single-file. Retain/split by cross-implementation stability and independent task selection, not by length; merge parts every real caller co-loads. This is project-specific flesh, not universal architecture and not an Always Read default. See [business-global-model.md](business-global-model.md).

## Why this matters

Over-structuring a small skill:

- Adds 5–10 files the user must open and keep up to date
- Pushes simple "always do X" rules into `rules/` folders, then forces thin shells to point at them
- Creates false invariants (thin shells claim the skill routes tasks, when the skill has one task)

Under-structuring a growing skill:

- Grows SKILL.md body past 90 lines (or description past 25), defeating Principle 1
- Mixes rules and workflows in one file, defeating Principle 3
- Loses routing discipline, forcing the agent to read the whole file for every task

The tier table above is the concrete decision gate. Re-evaluate on each significant skill revision, not on every edit.

## Three-axis profile

Skill shape is not one flat choice. Profile it on three independent axes:

| Axis | Values | Question |
|---|---|---|
| Structure tier | Single-file / Folder-light / Full | How much routing and durable documentation does the project need? |
| Execution mode | Rule-only / Assisted-executable / Executable | Does the skill merely guide work, or does it own scripts, external calls, and output contracts? |
| Domain topology | Single-skill / Multi-skill candidate | Do trigger language and rules form one domain or several separable domains? |

A project can be `Full + Rule-only + Single-skill`, or `Folder-light + Executable + Single-skill`. Keep the axes separate so one pressure does not force unrelated structure.

For execution-mode pressure, see [executable-skill-architecture.md](executable-skill-architecture.md). For multi-skill topology, see [multi-skill-routing.md](multi-skill-routing.md).

## Two-root split (advanced: shared skeleton across repos)

Beyond Full, when one skill's skeleton is *shared* across multiple code checkouts (or a tool assembles it into each consumer's tool dir), relocate the 骨架/肉 split across a **repo boundary**: skeleton (`architecture` / `rules` / `workflows` + entry + routing) in a shared `skill_root`; flesh (`conventions` / `gotchas` / `references`) in the per-codebase `code_root`; routing joins them with `skill:` / `code:` path prefixes so one route composes both. This is a deployment **topology**, not more rigor — most single-repo skills stay single-root. Trigger + worked example: [skeleton-flesh-split.md §7](skeleton-flesh-split.md).

## Tests as spec (advanced: opt-in execution-mode discipline)

For projects whose work is unit-testable **and** that carry an under-testing baseline (e.g. recurring production incidents after light testing), an opt-in discipline makes the plan's test cases the spec: write cases at plan time (they double as the human-clarification question set — the human is the correctness oracle), realize them as unit tests, and treat a failing test as a code-or-understanding reconciliation (the trichotomy). Subjective/visual work goes to human sign-off, never forced unit tests. **Not a default**, and **not a blocking gate** — kept out of `conformance.yaml`; the agent's duty is faithful generation + transparently listing the cases/results, and the **user makes the final acceptance call**. Full discipline: [`../templates/skill/references/tests-as-spec.md`](../templates/skill/references/tests-as-spec.md).

## Permission model (advanced: opt-in autonomy + layered enforcement)

For projects where the agent runs side-effecting operations (schema / prod / secret / shared-contract), an opt-in discipline classifies operations by autonomy — 🟢 do-autonomously (the default, not a list) / 🟡 propose-and-stop-for-a-human / 🔴 refuse — and, more importantly, **enforces the 🔴 rules on a ladder proportional to their cost** (prose → remove-material → pre-commit → CI). A prohibition in prose alone doesn't stop an agent, so "written in a doc" ≠ enforced. Orthogonal to blast-radius buckets (path / closure-rigor) and the subagent Negative list (delegation) — cross-reference, don't merge. **Not a default**, **not a blocking gate** (🟡 is report-not-block shifted earlier; kept out of `conformance.yaml`); machine layers go only on 🔴 rules with a real baseline (imagined-pain guard). Full discipline: [`../templates/skill/references/permission-model.md`](../templates/skill/references/permission-model.md).

## Simple Route vs Advanced Route

Most routes need only `id`, `labels`, `route`, `required_reads`, `workflow`, and `trigger_examples`. Keep them simple.

Use optional advanced fields only for high-risk routing where a wrong match has a real cost:

| Field | Use for |
|---|---|
| `positive_signals` | High-signal phrases or structural evidence that should enter this route |
| `negative_signals` | Nearby phrases that should route elsewhere or be refused |
| `confidence` | HIGH/MEDIUM/LOW decision rules and when to clarify |
| `slots` | Required inputs and where to derive or ask for them |
| `target` | The exact capability, workflow, or external skill handoff |

Typical advanced-route cases: deploys, database/schema changes, remote config writes, status transitions, external skill delegation, expensive API calls. These fields are documentation and generation input; `sync-routing.sh` must stay compatible with routes that do not define them.
