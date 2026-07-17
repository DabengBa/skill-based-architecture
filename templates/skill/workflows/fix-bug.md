# Fix Bug Workflow

> **Inline by default.** Read [`subagent-auxiliary.md`](subagent-auxiliary.md) only when a sub-step is an independent, time/context-heavy, result-only workstream with real overlap and positive Net Benefit. Ordinary diagnosis, one grep, one narrow test, and the next critical-path command stay inline.

## Mandatory Pre-Step (cannot skip)

**Re-run `SKILL.md` § Session Discipline before starting.** Re-match this bug against Common Tasks; re-read the route's files only if the route changed or context was compacted (see § Session Discipline).

**Root-cause-first gate:** no fix before the actual cause is identified; a symptom patch is a guess. Three failed fixes means the premise is wrong (§ Three Strikes).

**Design-or-defect gate:** establish expected behavior before writing the red check. For business-sensitive behavior, compare the routed business global model (what should be true), architecture/rules/contracts (intended design), and code/tests/runtime (current fact). Classify `IMPLEMENTATION_BUG`, `DESIGN_CHANGE`, or `INSUFFICIENT_BUSINESS_CONTEXT`. If the proposed fix changes a business type, flow direction, state machine, or core invariant, stop this workflow and switch to planning with explicit user approval. Obvious technical failures can proceed without business modeling.

## Read First

1. Re-open `SKILL.md` → match this bug to a Common Tasks route
2. Read the route's core files only if needed by Session Discipline; then apply `references/minimal-sufficient-context.md`
3. Read the matched module's business model only when expected behavior depends on macro business semantics; expand to gotchas, source indexes, callers, or extra rules only when an escalation signal fires

## Steps

1. Restate the observed behavior and affected scope.
2. Apply the Design-or-defect gate. If context is insufficient, inspect evidence and ask only the missing business question; a completely absent model may be created only after the user chooses "now". Reuse all evidence if the task converts to planning.
3. Read the minimum necessary files; re-enter `references/minimal-sufficient-context.md` if ownership, callers, contracts, or runtime dependencies become unclear.
4. **Reproduce first** — express the confirmed bug as a repeatable failing check and verify it fails *for the reported reason* before touching code. If it passes/fails differently, repair the acceptance understanding first. Can't automate → write repeatable manual steps + why not.
5. Identify the actual root cause. If 2+ concrete hypotheses survive, use § Hypothesis Fan-out.
6. Implement the smallest correct fix — no "while we're here" cleanup.
7. Run Fix Impact Analysis against callers, data flow, and compatibility.
8. Validate: **the same check from step 4 now passes**, plus the smallest relevant regression. Keep a critical-path check inline; delegate a long independent test/build only when `subagent-auxiliary.md` passes and useful main-thread work continues—never spawn it and immediately wait.
9. **Run Task Closure Protocol** from `workflows/task-closure.md`.
10. If recording is triggered, follow `update-rules.md` destination-specific fidelity/generalization/reconciliation gates and activate costly task-relevant knowledge.

## Hypothesis Fan-out (optional, for ambiguous bugs)

When 2+ plausible root causes survive, avoid serially polluting the main context.

**Trigger** — fan out only when **all** of:

- ≥ 2 hypotheses are concrete enough to be a single-sentence claim
- Each one can be **independently verified** by reading a different region of the codebase / a different log slice / a different external check
- Inspecting them all in one context would consume > 30% of remaining budget
- Parallel verdicts save more than contract, review, and integration cost

If any condition fails, just inline the most likely one. Fan-out has dispatch overhead.

If `subagent-auxiliary.md` still passes, give each independent hypothesis a read-only contract: Goal = confirm/refute one claim; Inputs = only its proof region; Output = confirmed/refuted/inconclusive with specific evidence; Forbidden = edits; Acceptance = cited file/log evidence. Dispatch only the minimum independent set, continue named synthesis work, and use at most one bounded wait when every remaining path depends on verdicts. Without native dispatch, write each hypothesis and refutation region before reading code.

## Three Strikes — stop and question the architecture

If **three distinct fixes** have failed to resolve the same bug, stop — do not attempt a fourth patch. Three misses is not bad luck; it means the model of the problem is wrong. One of these is almost always true:

- **The root cause is not where you think.** You have been fixing a symptom; the real trigger is upstream. Re-trace from the actual call origin, not the error site.
- **The architecture is forcing the bug.** The design makes this class of error reachable; the durable fix is structural, not another patch.
- **A hidden assumption is false.** A "can't happen" invariant is happening — stale cache, race, wrong environment, shadowed config.

Write down what each of the three attempts assumed and why it failed; the contradiction usually points straight at the wrong assumption. Re-question the premise before any further attempt — and if the durable fix is now a structural change rather than the small fix the task assumed, surface that to the user instead of forcing a fourth patch.

## Fix Impact Analysis

Before final validation, inspect the actual diff and answer:

1. **Direct impact** — Which callers use the changed function/method/component? Did any parameter signature, return type, response shape, or error behavior change?
2. **Indirect impact** — Does the fix alter upstream/downstream data flow, shared state, global config, cache behavior, event timing, listeners, callbacks, or async ordering?
3. **Data compatibility** — If fields were added, removed, renamed, or changed type, do old data, persisted data, API consumers, and fallback/default paths still work?
4. **Blast-radius validation** — Which targeted tests, compile checks, type checks, or manual smoke paths cover the affected callers and compatibility assumptions?

If any answer is unknown, inspect the relevant callers or data contracts before declaring the fix safe.

## Completion Checklist

- [ ] Root cause identified (not just a plausible-looking fix)
- [ ] Expected behavior classified: implementation bug / design change / insufficient business context / obvious technical bug
- [ ] A type/flow/state/invariant change was routed to planning instead of patched as a bug
- [ ] If three fixes failed, the premise / architecture was re-questioned (not a fourth symptom patch)
- [ ] Fix Impact Analysis completed against the actual diff
- [ ] Direct callers and changed signatures/return shapes checked
- [ ] Indirect data flow, shared state, events, callbacks, and async timing considered
- [ ] Data compatibility checked for added/removed/renamed/type-changed fields
- [ ] Code fix verified (the step-4 check flipped red → green; manual repro clean)
- [ ] Task Closure Protocol was run (AAR scan completed before declaring task done)
- [ ] Recording threshold checked
- [ ] If threshold passed, generic records passed generalization; business-model records passed cross-implementation stability; docs were reconciled in place
- [ ] If the lesson was costly and task-relevant, it was activated in workflow/routing, not only stored in `references/`

## Final Report (to the user)

Close with these six fields — the checklist above is the agent's gate; this is what the user reads:

- **Classification / design basis** — implementation bug, design change, insufficient business context, or technical bug; cite the business model, contract, test, or user confirmation used
- **Root cause** — the actual cause; name any residual uncertainty
- **Change** — what behavior changed and the key files; no unrelated diff walk-through
- **Verification** — which check failed before and passed after (step 4 → step 8), and what regression ran
- **Blast radius** — callers / contracts / data compatibility / async effects, per Fix Impact Analysis
- **Uncovered risk** — what was not verified and why; anything needing user sign-off

<!-- OPTIONAL: add project-specific validation steps here — e.g. specific test suites to run, linters, smoke tests; declare the cheapest-sufficient verification path (e.g. hot-reload dev server) and what triggers escalation to a full build. -->
