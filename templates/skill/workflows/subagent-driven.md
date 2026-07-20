# Workflow: Subagent-Driven Development

Use this only as a modifier after matching the primary task route. It decides whether a planned multi-workstream task enters Mode 2; one opportunistic auxiliary candidate uses [`subagent-auxiliary.md`](subagent-auxiliary.md).

## Mode Selection

Enter Mode 2 only when:

- at least three workstreams have independent writable ownership;
- each has a mechanically reviewable contract;
- useful main-thread synthesis/integration overlaps execution;
- concurrency has positive Net Benefit after coordination and review;
- user discussion and business/architecture/security/root-cause decisions remain with the main agent.

Many files/tasks, a long runtime, or “explore + implement + review” do not qualify by themselves. Mostly serial work and spawn-then-wait stay inline.

## Mode 2 Entry

1. Finish the task list and identify the truly independent subset.
2. Give each worker Goal, Inputs, Outputs, Forbidden Zones, Acceptance Criteria, and required Return Status.
3. Pass contract-scoped artifacts, not the conversation or intended answer.
4. Dispatch the minimum independent set together and continue the named main-thread work.
5. Follow [`subagent-orchestration.md`](subagent-orchestration.md) for review and merge/reject routing.

A Plan task breakdown can supply contract fields, but task count never determines worker count.

## Harness Compatibility

Native subagent primitive → dispatch admitted work concurrently. No primitive or optional dispatch denied → execute inline; Mode 2 contracts/review may still organize already-admitted work. If the task itself is blocked by a required capability, report that blocker rather than pretending degraded execution is equivalent.

## Completion Check

Primary route stayed authoritative; selection passed before dispatch; ownership did not overlap; main-agent judgment stayed inline; every result passed orchestration review.
