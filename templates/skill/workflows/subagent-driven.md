# Workflow: Subagent-Driven Development

Use this as a cross-cutting modifier after matching the primary task route. It selects planned multi-workstream orchestration; ordinary workflows that only have one possible auxiliary search/test/build/edit read [`subagent-auxiliary.md`](subagent-auxiliary.md) directly instead.

Delegation is an optional optimization, never a compliance target. Inline is the default.

## Mode Selection

Use Mode 2 only when all are true:

- the task has at least 3 independent workstreams with non-overlapping ownership;
- each workstream has a mechanically reviewable contract;
- the main agent can name useful synthesis/integration work that overlaps execution;
- concurrent execution has positive Net Benefit after startup, context handoff, coordination, review, merge, and likely rework cost;
- the main agent owns user discussion, business/architecture/security decisions, root-cause synthesis, and final verification.

A large task, many files, a long runtime, or explore + implement + review does not qualify by itself. If the task is mostly serial, shares one decision chain, or the next action after dispatch would be waiting, stay inline. A single auxiliary candidate belongs to `subagent-auxiliary.md`, not this selector.

## Parallelism Premise

- Dispatch only independent contracts and start them together.
- Worker count cannot exceed independent workstreams; files, tests, commands, and free slots are not workstreams.
- Name the main-thread work that runs concurrently, then continue it immediately.
- Do not wait while useful independent work remains. When every remaining critical path depends on running workers, use one bounded/event-driven wait and integrate the result; never poll-loop.
- Workers do not spawn workers. Flatten only the workstreams already present in the task.

## Mode 2 Entry

1. Finish the complete task list and identify the truly independent subset before dispatch.
2. Give each worker Goal, Inputs, Outputs, Forbidden Zones, Acceptance Criteria, and required Return Status.
3. Do not pass the conversation or intended answer; pass only contract-scoped artifacts.
4. Dispatch the minimum admitted workers in parallel and continue named main-thread synthesis/integration work.
5. Follow [`subagent-orchestration.md`](subagent-orchestration.md) for two-stage review and merge/reject routing.

A [`plan-feature.md` § Task Breakdown](plan-feature.md) may map to contracts, but only admitted independent tasks dispatch; the plan's task count is not the worker count.

## Interception Transparency

Distinguish an optional optimization from an actual blocker:

- Optional dispatch unavailable or denied, while the task remains possible inline → continue inline; do not stop merely to satisfy delegation structure.
- The requested outcome cannot proceed because a required tool, permission, file, or network path is blocked → stop and report the concrete blocker and available choices.

Never hide an actual blocker and never manufacture one from an unavailable optional worker.

## Harness Compatibility

- Native subagent harness → use real parallel/background dispatch after Mode Selection passes.
- No subagent primitive → execute inline; for an already-admitted planned Mode 2 task, the contract/review discipline in `subagent-orchestration.md` Degraded Mode may still be reused.
- User authorization required for dispatch → obtain it before relying on concurrency; if unavailable and the task itself is still possible, continue inline.

## Rationalizations / Red Flags

- “The step is mechanical, so it belongs to a worker” → mechanics still need independence, real overlap, and positive Net Benefit.
- “There are three files/tests/tasks, so use three workers” → artifacts are not workstreams.
- “Context isolation always justifies a foreground worker” → not when the main agent then idles; use bounded reads/output or stay inline.
- “The worker is running, so wait now” → continue useful independent work first; never poll-loop.
- “The worker almost got it right, so always re-dispatch” → re-run the Admission Test on the remaining delta; inline correction may now be cheaper.
- Main agent cannot name concurrent work, workers share writable files/decisions, or review costs approach inline work → stop and reassess; stay inline or re-decompose.

## Completion Checklist

- [ ] Primary intent route remained authoritative
- [ ] All Mode Selection conditions passed before dispatch
- [ ] Worker count matched independent workstreams, not artifacts or slots
- [ ] Main-thread work overlapped; no spawn-then-wait or poll loop occurred
- [ ] Every worker had a complete contract and Return Status
- [ ] Main-agent judgment stayed with the main agent
- [ ] Stage A + B review completed before merge
- [ ] Optional dispatch failure did not become a false blocker
