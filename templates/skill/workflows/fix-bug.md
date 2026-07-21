# Fix Bug Workflow

Use this route to determine whether observed behavior is an implementation defect and, if so, prove the smallest correct repair. For a non-Simple task, [`task-execution.md`](task-execution.md) turns these domain steps into the current Task Anchor and Native Plan without weakening the gates below. Read [`subagent-auxiliary.md`](subagent-auxiliary.md) only for an admitted independent investigation or long result-only check.

## Mandatory Pre-Step

Re-match the task route. No patch before expected behavior and the actual root cause are established.

**Design-or-defect gate:** when behavior depends on business semantics, compare the routed business model, architecture/contracts, and code/tests/runtime. Classify:

- `IMPLEMENTATION_BUG` — implementation violates the current model/contract;
- `DESIGN_CHANGE` — the requested result changes a business type, flow direction, state machine, or core invariant, or moves a stable business boundary;
- `INSUFFICIENT_BUSINESS_CONTEXT` — evidence cannot establish intended behavior.

A Design Change leaves this workflow for an approved Plan. For insufficient context, search evidence first and ask only the missing macro question; a completely absent model is created only if the user chooses “now”. Obvious technical failures need no business model.

## Steps

1. Restate the observed behavior, affected scope, and expected result.
2. Classify with the Design-or-defect gate.
3. Reproduce the defect with a failing automated check for the reported reason; if automation is impossible, give repeatable manual steps and why.
4. Trace the real root cause. If several independent hypotheses survive and delegation has positive Net Benefit, use `subagent-auxiliary.md`; synthesis stays with the main agent.
5. Implement the smallest repair without adjacent cleanup.
6. Inspect direct callers plus changed contracts, data compatibility, shared state/config, events, and async ordering. Resolve any unknown that could invalidate the fix.
7. Run the same acceptance check to green and the smallest relevant regression. Escalate to runtime/release evidence only when the changed behavior requires it.
8. Run the [Task Closure Protocol](task-closure.md). Record only a lesson that passes its gates and has an action-changing route.

After three failed approaches, stop and report the attempts and false premise instead of trying a fourth variant.

## Completion Check

- Classification and design basis are explicit.
- The failing check reproduced the real defect before code changed and passes afterward.
- Root cause, direct/indirect impact, compatibility, and residual uncertainty were inspected.
- No type/flow/state/invariant change was smuggled through Bug Fix.
- Task Closure ran once after the integrated fix.

## Final Report

Report classification/design basis, root cause, change, red→green verification, blast radius, and uncovered risk. Do not narrate the whole diff.
