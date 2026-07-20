# Change-Managed Workflow

Use this for non-bug changes whose partial edits can drift: features, refactors, generated/copied files, shared configuration, or changes with derived targets. Inline is the default; use [`subagent-auxiliary.md`](subagent-auxiliary.md) only for one admitted auxiliary workstream and [`refactor-fanout.md`](refactor-fanout.md) only for several independent usage batches.

## Steps

1. **Define scope** — name owned files/modules and the observable outcome. For business-bearing work, record `business-model impact: unchanged / proposed change / unknown`; a proposed type/flow/state/boundary/invariant change requires an approved Plan.
2. **Find the source of truth** — distinguish canonical content from generated/copied consumers.
3. **Map fan-out** — list every derived target, registration, test, and doc/index that must stay synchronized.
4. **Make the smallest coherent change** — preserve unrelated edits and avoid adjacent cleanup.
5. **Sync derived files** with the owning generator/copy process.
6. **Check drift** across all mapped targets.
7. **Validate behavior** with the cheapest sufficient fresh evidence; escalate only when concrete runtime/release risk requires it.
8. **Run [Task Closure](task-closure.md)** once after the integrated change.

If templates, scaffolds, entry shells, or reusable project structure change, also follow [`edit-templates.md`](edit-templates.md). If this project has already activated an operation-permission model, apply its pre-operation classifier and closure check; the default scaffold assumes none.

## Completion Check

Scope, source/derived ownership, fan-out targets, sync, drift, targeted validation, and Task Closure are all accounted for.
