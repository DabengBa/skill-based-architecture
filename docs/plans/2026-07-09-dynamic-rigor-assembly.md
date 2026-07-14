---
date: 2026-07-09
status: done
distilled_to:
  - templates/skill/references/minimal-sufficient-context.md
  - templates/skill/SKILL.md.template
  - templates/skill/routing.yaml
  - templates/skill/workflows/fix-bug.md
  - templates/skill/workflows/change-managed.md
  - templates/skill/conformance.yaml
---

# Plan: Dynamic Rigor Assembly

## Context

Recent downstream pressure from `chaos` / `chaos-web` shows that small requests are slowed down less by any single validation command and more by the whole skill stack firing at once: full route reads, broad gotcha/reference loading, heavy workflow gates, browser/runtime verification, and closure checks.

The working insight from the discussion:

> Workflow owns the invariant core. Packs own variable rigor.

For example, `fix-bug` always has the same core flow: reproduce, obtain failing evidence, identify root cause, make the smallest fix, validate the same evidence, report. What varies is the context read before the core, the validation evidence after the core, and the closure rigor.

## Problem

The current routing model mostly treats a route as:

```text
intent -> fixed required_reads + workflow
```

That makes two bad options tempting:

1. Put light/heavy distinctions inside every workflow, which duplicates the same "small vs large" logic across `fix-bug`, `change-managed`, `add-page`, `refactor`, etc.
2. Split routes/workflows by size, such as `small-fix-bug`, `large-fix-bug`, `small-add-page`, `large-add-page`, which causes workflow explosion.

The deeper issue is that "small" is not a workflow intent. It is a narrow context footprint:

```text
Small task = narrow context footprint, not low-quality task.
```

The system needs a way to keep the intent core stable while dynamically adding only the context, validation, and closure rigor required by the actual risk signals.

## Options Considered

- **Option A: split every workflow by size**
  Example: `small-fix-bug`, `large-fix-bug`, `small-change-managed`, `large-change-managed`.
  Pros: easy to understand at first glance.
  Cons: route/workflow explosion; repeated logic; size becomes a sibling of intent; every new workflow must solve the same problem again. Rejected.

- **Option B: put a full pack schema in `routing.yaml`**
  Example: top-level `packs.context.micro`, `packs.validation.runtime`, route-level `assembly`, defaults, stop lists, evidence types.
  Pros: very explicit; could become machine-readable later.
  Cons: bloats routing; risks turning `routing.yaml` into a second workflow language; most fields are inert unless scripts and workflows consume them. Rejected for now.

- **Option C: add minimal route hooks plus one shared explanation**
  Example: keep `required_reads` as the invariant core, optionally add a small `expand_when` list for high-value routes, and put the dynamic assembly rules in one shared reference/workflow.
  Pros: avoids workflow explosion; keeps routing lean; gives agents concrete escalation signals; can be adopted incrementally.
  Cons: needs careful wording so `expand_when` changes behavior instead of becoming decorative metadata. Candidate approach.

- **Option D: no routing schema change; only update workflow prose**
  Example: `fix-bug.md` and `change-managed.md` say "read minimally, expand on risk signals."
  Pros: lowest implementation cost; no script changes.
  Cons: less visible in generated Common Tasks; downstream projects may re-invent the wording; harder to audit. Candidate fallback.

## Chosen Approach

Draft direction: use **Dynamic Rigor Assembly** as a cross-cutting mechanism, not a route family.

Do not introduce `rigor: dynamic` unless some workflow or script explicitly consumes it. A bare flag is inert metadata.

Prefer this model:

```text
Intent route:
  - stable core workflow
  - minimal core required_reads
  - optional escalation signals

Shared assembly guidance:
  - what counts as minimal sufficient context
  - when to expand context
  - when to escalate validation
  - when closure needs to move from none/light/full
```

The exact routing field is still open. If we add one, `expand_when` or `escalate_when` is more behavior-shaped than `rigor: dynamic`, because it tells the agent what to watch for.

Important boundary:

```text
Route intake protocol owns context assembly.
Workflow owns the invariant intent core.
Task closure owns completion rigor.
```

Dynamic rigor should not be copied into each workflow as a "Context Gate" block. That would recreate the same duplication problem under a new name. Workflows may mention that they operate on the context assembled by route intake, but the tier definitions and expansion rules live once in the shared protocol.

## Requirements & Acceptance Criteria

- Intent routes remain intent-based. Size does not create sibling workflows.
- "Small" is defined by objective signals, not by user adjectives or diff size.
- `required_reads` should mean "minimum core reads for the route," not "everything that might ever be relevant."
- Dynamic expansion must be additive: when risk appears, read/validate/close more; do not restart the whole workflow from scratch.
- No inert metadata: any new routing field must be rendered, checked, or explicitly consumed by workflow text.
- Existing line budgets stay plausible: `routing.yaml` should not become a pack DSL.
- Downstream projects can adopt the pattern without copying a long schema into every route.

## Proposed Changes To Brainstorm

### 1. Add One Shared Concept Doc

Potential file:

```text
references/dynamic-rigor-assembly.md
```

Purpose:

- Define "Workflow owns invariant core; packs own variable rigor."
- Define "Small task = narrow context footprint, not low-quality task."
- Define the three variable axes:
  - context: read less or expand reads
  - validation: command evidence, runtime evidence, release evidence
  - closure: none, light AAR, full structure gate
- Define escalation signals:
  - target unclear
  - ownership unclear
  - cross-module or cross-skill impact
  - public contract changed
  - DB / RPC / API / permission / config touched
  - runtime behavior cannot be proven by command evidence
  - first fix failed or root cause model became unstable

### 2. Update Routing Guidance, Not Necessarily Routing Schema

Candidate minimal route shape:

```yaml
tasks:
  - id: fix-bug
    required_reads:
      - workflows/fix-bug-core.md
    workflow: workflows/fix-bug.md
    expand_when:
      - ownership_unclear
      - cross_module
      - public_contract_changed
      - runtime_dependency
      - first_fix_failed
```

Open point: `expand_when` is only worth adding if either:

- `sync-routing.sh` renders it into Common Tasks / shells, or
- workflows explicitly say "when the matched route has `expand_when`, treat it as the route's escalation list."

If neither happens, skip the field and keep the signals in the shared concept doc.

### 3. Add A Route Intake Protocol

Candidate home:

```text
references/route-intake-protocol.md
```

or, if the name should emphasize the main benefit:

```text
references/minimal-sufficient-context.md
```

This protocol should define the shared tiering once:

- initial context assembly: minimal / standard / expanded
- expansion signals: unclear target, unclear ownership, cross-module impact, contract/runtime risk, failed first attempt
- validation escalation: command evidence -> runtime evidence -> release evidence
- closure delegation: use `task-closure.md`; do not duplicate its trigger policy

The protocol runs before a workflow and can also be re-entered when a workflow discovers a new expansion signal.

### 4. Trim Workflow Templates Back To Their Core

Candidate changes:

- `fix-bug.md`: keep root-cause core; remove embedded "small bugfix" / "light validation" tier definitions. It may say: use route intake for context assembly; if root-cause work exposes an expansion signal, return to intake and expand.
- `change-managed.md`: keep source-of-truth, fan-out, sync, drift, and targeted validation steps. Remove any generic "small task" tiering that belongs to intake.
- `plan-feature.md`: keep its own Simple / Complex / Large gate. This is not cross-cutting dynamic rigor; plan depth is the workflow's own artifact shape.
- `task-closure.md`: keep as the sole owner of closure trigger policy and blast-radius buckets. It is already the closure axis; do not restate it in the route intake protocol.
- New downstream workflows such as `add-page` or `fix-schema-error` should not copy a full lightweight mode. They should rely on route intake for "read less / expand when needed" and keep only their domain core.

### 5. Adjust Routing Template Comments

Potential changes to `templates/skill/routing.yaml` comments:

- Clarify that `required_reads` are core route-specific reads.
- Warn against using `required_reads` as a safety blanket.
- Add a short note: for routes with variable rigor, use shared dynamic assembly guidance; do not split by size.
- If `expand_when` is adopted, document it as optional and high-signal only.

### 6. Add Lightweight Scenario Tests / Examples

Potential examples:

- "指定文件改文案" should not load full architecture/gotchas or enter bug workflow.
- "接口 500" routes to `fix-bug`, starts with core bug flow, expands if ownership/root cause unclear.
- "改 RPC 返回字段" expands immediately because public contract changed.
- "页面按钮样式小改" uses minimal context, user page sign-off, no production build by default.

These could live in `examples/behavior-failures.md` or a new scenario doc only if they are valuable enough. Avoid invented-pain examples.

## Out of Scope

- Do not design a full routing DSL in this pass.
- Do not require every downstream skill to add `micro/simple/complex` route variants.
- Do not make "small" an official workflow id.
- Do not move project-specific facts like `fat jar`, `Nacos`, `Amis`, or browser hot reload into SBA's generic mechanism.
- Do not add machine gates until a real repeated failure proves prose is insufficient.

## Task Breakdown

### Task 1 - Converge The Concept

- **Files**: owns this plan file
- **Consumes**: current discussion and existing SBA routing/progressive-rigor docs
- **Produces**: agreed vocabulary and rejected alternatives
- **Acceptance**: user agrees the plan captures the shape of the problem and the viable design space

### Task 2 - Draft Shared Dynamic Assembly Guidance

- **Files**: likely owns `references/dynamic-rigor-assembly.md`; may touch `references/layout.md`
- **Consumes**: this plan's chosen approach
- **Produces**: one concise active reference with objective escalation signals
- **Acceptance**: the guidance changes agent behavior when read and does not exceed the value of the saved context

### Task 3 - Decide Whether Routing Needs A Field

- **Files**: may touch `templates/skill/routing.yaml`, `templates/skill/scripts/sync-routing.sh`, generated template summaries
- **Consumes**: Task 2 guidance
- **Produces**: either no schema change, or one minimal field such as `expand_when`
- **Acceptance**: no inert metadata; any field is rendered or explicitly consumed

### Task 4 - Add Route Intake Protocol

- **Files**: likely owns `references/route-intake-protocol.md` or `references/minimal-sufficient-context.md`; may touch `references/layout.md`
- **Consumes**: Task 2/3 decisions
- **Produces**: a single shared protocol for initial context assembly, expansion signals, validation escalation, and delegation to task closure
- **Acceptance**: workflows no longer need to carry their own duplicated "small vs large" blocks

### Task 5 - Trim Workflow Templates Back To Invariant Cores

- **Files**: likely touches `templates/skill/workflows/fix-bug.md`, `templates/skill/workflows/change-managed.md`, and downstream-derived guidance examples
- **Consumes**: Task 4 protocol
- **Produces**: workflow text that assumes route intake has assembled context and asks for expansion only when the workflow discovers a signal
- **Acceptance**: `fix-bug` keeps bugfix core; `change-managed` keeps change-management core; `plan-feature` keeps artifact-depth tiers; no generic tier ladder is duplicated in each workflow

### Task 6 - Validate With Downstream Pressure Cases

- **Files**: may use `chaos` / `chaos-web` as read-only pressure cases, or add examples if justified
- **Consumes**: updated template guidance
- **Produces**: before/after scenario notes showing reduced context loading without skipping real risk
- **Acceptance**: at least one small targeted task and one escalating task are both handled correctly

## Open Questions

Resolved in this implementation:

- Name: `Minimal Sufficient Context`, because it names the user-visible benefit more directly than "dynamic rigor."
- No `expand_when` schema yet. Signals live in one reference and are activated by SKILL/routing/workflow prose; no inert metadata.
- No `rigor: dynamic` flag. A flag without a consumer was rejected.
- No small/large workflow split. `fix-bug` and `change-managed` keep their invariant cores.
- Activation points: generated SKILL Common Tasks prose, `routing.yaml` route comments, and the two broad workflow Read First sections.
- Validation escalation lives in the shared reference; closure trigger policy remains in `task-closure.md`.

Not added:

- Scenario tests. The implementation is prose/routing behavior, and upstream `check-all.sh` already instantiated a sample downstream proving the new reference is reachable from Common Tasks. Add scenario tests only after a repeated behavioral miss shows prose is insufficient.
- Project-specific validation examples such as fat jar refresh, Nacos, browser hot reload, or Amis. Those belong downstream.
