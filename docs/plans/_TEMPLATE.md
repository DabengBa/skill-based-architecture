---
date: YYYY-MM-DD                       # day the plan was drafted; filename uses the same date
status: draft                          # draft | executing | done | abandoned
# distilled_to:                        # set on close — the live-structure files that received load-bearing content
#   - rules/<topic>.md                 # for "must / must not do X" conclusions
#   - references/gotchas.md            # for "we tried Y; here is why Y is wrong" anti-patterns
#   - SKILL.md § Common Pitfalls #N    # if Pitfalls is the right home
# Omit distilled_to entirely if status is abandoned, OR if you genuinely judged no
# conclusion was load-bearing. Note that judgment in the plan body.
---

# Plan: {{Title}}

> **Canonical structure lives in [`templates/skill/workflows/plan-feature.md` § Plan Skeleton](../../templates/skill/workflows/plan-feature.md).** This file mirrors it; if the two ever disagree, plan-feature.md wins. Do not redefine the section list here.
>
> Plans are frozen snapshots. Edit freely while `status: draft` or `executing`. Once `status: done` or `abandoned`, this file is read-only — lift any still-load-bearing content into `rules/` / `references/gotchas.md` / SKILL.md Pitfalls instead.

## Context

Why are we drafting this plan? What changed?

## Problem

The thing we are trying to solve, stated concretely.

## Options Considered

≥ 2 genuinely distinct approaches (different shape, not one + strawmen). Diverge before converging.

- **Option A: ...** — Pros / cons.
- **Option B: ...** — Pros / cons.

## Chosen Approach

Which option won, and the one or two sentences of "why" that will survive into the live structure on close.

## Requirements & Acceptance Criteria

Testable outcomes. What proves this plan was delivered.

## Out of Scope

Explicit exclusions.

## Task Breakdown

Executable decomposition — **omit this section for a single-task plan**. One block per task; each declares its interface so it can be built and verified independently (and dispatched to a subagent with zero re-derivation).

### Task 1 — <verb-noun>

- **Files**: owns `...`; shares `...` (read-only); forbidden: everything else
- **Consumes**: the interface(s) earlier tasks or existing code expose that this task depends on
- **Produces**: the interface later tasks rely on — exact signatures / types / exports / routes
- **Acceptance**: a literal check — `<test cmd>` exits 0 / `grep -c X` returns 0 / observable behavior
- [ ] sub-steps only when the path is non-obvious

## Open Questions

Unresolved *decisions* at the time of drafting (a "what happens when the dependency is down?" decision is an open question, not just a missing input value). Closed questions move into the body above as decisions, not left here as resolved checkboxes.

<!-- Large task: split analysis into angle files (architecture.md / risks.md / ...). Each angle file opens with `> Conclusion: <one line>`; add a `## Synthesis` section above that links every angle and states the chosen path. See plan-feature.md § Large Plan. -->

<!-- For abandoned plans, replace the body with a single section: -->
<!-- ## Why Abandoned -->
<!-- One paragraph. Do not distill; the absence of a decision is itself the record. -->
