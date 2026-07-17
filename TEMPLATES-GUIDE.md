# Templates Guide

> **The authoritative, byte-for-byte copyable files live in [`templates/`](templates/) — copy from there, do not paste from this guide.** This file gives a minimal starter scaffold for projects that don't yet need the full directory split, plus pointers to the canonical workflow templates so this guide cannot drift against them.

## Minimal Starter Template

Use this when a project has only one small skill and does **not** yet need the full `skills/<name>/rules|workflows|references` split.

```md
---
name: <project-name>
description: >
  This skill should be used when the user asks within this skill's domain, such as
  "<trigger phrase 1 in real user language>", "<trigger phrase 2>", or "<trigger phrase 3>".
  Activate when <condition 1> or <condition 2>.
---

# <Project Name>

One-line summary.

## Always Read
1. `<core-file-or-section>`

## Common Tasks
- Main task → read `<core-file-or-section>` and follow `<closest workflow or section>`
- Other → use the guidance above and keep edits minimal
```

Start here when:

- the skill is still short and self-contained
- rules are not duplicated across multiple entry files
- there is no strong need yet for separate `rules/`, `workflows/`, and `references/`

Upgrade to the full skill-based directory only when the single file starts to sprawl, duplicates appear, or knowledge needs active maintenance. See [`references/progressive-rigor.md`](references/progressive-rigor.md) for the upgrade triggers.

## Classification Guide

When promoting content out of a single SKILL.md into the full directory, tier by **abstraction (骨架/肉)** — invariant theory vs current-code facts:

- Abstract design theory — layering/contract/orchestration **principles**, the "why" (**NOT** the module map) → `architecture/` (骨架)
- Code maps — module tree, dir layout, source index, build/env notes → `references/` (肉)
- House style — naming, paths, commands, formats, must/never conventions → `conventions/` (肉)
- Code-coupled landmines (symptom → cause → fix) → `gotchas/` only after independently routed module pressure; add a selecting `gotchas/index.md` only for multiple task-selectable files
- Task procedures with ordered steps (process theory) → `workflows/` (骨架)
- Cross-cutting agent behavior / methodology → `rules/` (骨架)
- External-facing material → `docs/`

A small skill uses a single `rules/` for constraints and splits it by abstraction (theory → `architecture/`, maps → `references/`, house style → `conventions/`) only under pressure — see [references/progressive-rigor.md](references/progressive-rigor.md) and the judgement test in [references/skeleton-flesh-split.md](references/skeleton-flesh-split.md).

## Sync Targets

Keep `routing.yaml` and the documentation tree consistent on these change types:

| Change type | Files to update |
|---|---|
| New/renamed workflow or reference file | `routing.yaml`, then `scripts/sync-routing.sh` |
| New rule that future agents would guess wrong without | The relevant `rules/*.md`, plus `SKILL.md` summary if the pitfall should surface earlier |
| Behavior-change UI / interaction / overlay layering / styling-affecting-outcomes | `references/*.md` for the lesson, and `workflows/*.md` for the closure-gate update |
| (project-specific triggers) | (corresponding files) |

Threshold: if this change would cause someone to guess wrong on a similar task without reading the docs, update. Otherwise skip.

> The trigger table itself is a living document — when you discover a new change-to-update mapping during a real task, add it.

## Task Closure Protocol

Canonical source: [`templates/skill/workflows/task-closure.md`](templates/skill/workflows/task-closure.md#task-closure-protocol).

This guide intentionally does not restate the protocol. When the protocol changes, update `task-closure.md` first; other files should link, not parallel-define. The invariant is short: no non-trivial task is complete without main-work verification, a 30-second AAR scan, and any triggered path-integrity, route-path, cross-reference, behavior-validation, or external-fact checks.

For the protocol-level concepts (recording threshold, where to record, generalization rule, activation check, when not to record), see [`references/protocols.md`](references/protocols.md).

Reusable reinforcement blocks live in [`templates/skill/protocol-blocks/`](templates/skill/protocol-blocks/) and are copied inside each downstream skill — workflows link them without user-visible setup (`reboot-check.md`, `ambiguous-request-gate.md`, `subagent-contract.md`). Task Closure Rationalizations and Red Flags live only in `workflows/task-closure.md`.

Route intake uses [`templates/skill/references/minimal-sufficient-context.md`](templates/skill/references/minimal-sufficient-context.md) to keep per-task context and validation proportional: workflows keep their invariant core, while extra references/runtime/release evidence are added only when concrete risk signals appear.

## Workflow Templates

Real workflow templates live under [`templates/skill/workflows/`](templates/skill/workflows/) — they are copied byte-for-byte into downstream skills:

| Template | Purpose |
|---|---|
| [`task-closure.md`](templates/skill/workflows/task-closure.md) | The cross-cutting closure gate every behavior-changing task runs — Task Closure Protocol (Trigger Policy + steps), AAR scan, Rationalizations Table, Red Flags. Every other workflow's closure step references this file. |
| [`update-rules.md`](templates/skill/workflows/update-rules.md) | Recording mechanics: threshold, fidelity, five-way reconciliation, activation, destination durability, sync, and retirement. |
| [`fix-bug.md`](templates/skill/workflows/fix-bug.md) | Bug-fix workflow with design-or-defect classification, root-cause/reproduction gates, impact analysis, and Task Closure. |
| [`maintain-docs.md`](templates/skill/workflows/maintain-docs.md) | Independent-load-reason and semantic before/after audits, then split/merge/index and link integrity. |
| [`plan-feature.md`](templates/skill/workflows/plan-feature.md) | Core feature planning with Question/Complexity/Business-Semantics gates, plan interfaces, and closure distillation. |
| [`plan-large.md`](templates/skill/workflows/plan-large.md) | Large-only multi-perspective analysis and Synthesis contract; not loaded by ordinary plans. |
| [`profile-project.md`](templates/skill/workflows/profile-project.md) | Three-axis project profiling (structure / execution / topology) before scaffolding. |
| [`profile-business-model.md.example`](templates/skill/workflows/profile-business-model.md.example) | Opt-in product-project workflow for stable macro business meaning: initialization candidates, missing vs unclear calibration, semantic read-back, and routed activation. Rename/adapt only after real pressure. |
| [`update-upstream.md`](templates/skill/workflows/update-upstream.md) | Agent-led upstream refresh — clone, classify, compare, port, validate (including conformance against upstream's manifest). |
| [`change-managed.md`](templates/skill/workflows/change-managed.md) | Non-bug changes with multiple derived/synced targets — defines scope, finds source-of-truth, maps fan-out, runs drift checks. |
| [`edit-templates.md`](templates/skill/workflows/edit-templates.md) | Editing the upstream `templates/` tree — admission threshold, two-real-projects test, anti-pattern list. |
| [`subagent-auxiliary.md`](templates/skill/workflows/subagent-auxiliary.md) | Day-to-day mechanical/result-only delegation from ordinary workflows. |
| [`subagent-driven.md`](templates/skill/workflows/subagent-driven.md) | Planned multi-subtask/long-run mode selector; routes to full orchestration. |
| [`subagent-orchestration.md`](templates/skill/workflows/subagent-orchestration.md) | Mode 2 contract dispatch, two-stage review, Return Status routing, and degraded mode. |

For the "would two real projects disagree?" admission test that gates new template content, see [`templates/ANTI-TEMPLATES.md`](templates/ANTI-TEMPLATES.md).

For per-project byte budgets and the growth-health table, see [`templates/README.md`](templates/README.md).
