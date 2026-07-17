# Workflow: Optional Auxiliary Delegation

Read this from an ordinary task workflow when one sub-step may be delegated. It governs opportunistic auxiliary work; planned multi-workstream runs use [`subagent-driven.md`](subagent-driven.md) and `subagent-orchestration.md` instead.

Delegation is optional. Inline is the default.

## Admission Test

Delegate only when all are true:

1. **Independent workstream** — input/output/acceptance are fixed and it can finish without another decision.
2. **Result-only consumption** — the main agent needs a compact verdict/artifact, not traversal as substrate for root-cause, design, or user explanation.
3. **Real overlap** — the main agent can name useful non-overlapping work it will continue immediately while the worker runs.
4. **Positive Net Benefit** — expected time/context saved exceeds startup, handoff, coordination, review, merge, and likely rework cost.
5. **Bounded fan-out** — worker count does not exceed independent workstreams. Files, tests, commands, and free slots are not automatically workstreams.

If any answer is no or unknown, stay inline. A lone foreground worker followed by waiting is not admitted.

## Small Actions Stay Inline

Do not delegate merely because a step is mechanical or isolates context:

- one file or narrow anchored excerpt;
- ordinary `rg` / symbol lookup whose hits the main agent must inspect;
- one command, one narrow validation, or the next critical-path test;
- a single-file edit or short same-context patch;
- follow-up work dependent on the immediately preceding result.

A long build, wide search, or homogeneous edit qualifies only when every Admission Test item passes.

## Purpose Test

| Sub-step | Main-agent use | Action |
|---|---|---|
| Read code to decide/explain a bug or design | raw evidence is decision substrate | inline |
| Find many callsites while main agent designs the migration | compact list; real overlap exists | may delegate |
| Run a known long regression while main agent reviews the diff | only status/first failure needed | may delegate |
| Run one test and then decide the patch | immediate critical-path result | inline |
| Apply one decided transformation to independent batches | patch + verification are enough | may batch-delegate |

## Dispatch

1. State the useful main-thread work that will run concurrently.
2. Give Goal, exact Inputs, expected Output, Forbidden Zones, and literal Acceptance Criteria.
3. Dispatch the minimum admitted workers together; never split by file/test/slot solely to create fan-out.
4. Continue the named main-thread work immediately. Wait only when all remaining critical paths depend on running workers, and then use one bounded/event-driven wait—never poll-loop.
5. Require a concise verdict/artifact and verify it against the contract before use.

Workers do not spawn workers. User-requested core implementation stays with the main agent unless the user explicitly delegates ownership differently.

## Never Delegate

- user clarification or back-and-forth discussion;
- business meaning, architecture, schema/protocol, security, permission, or destructive-operation decisions;
- root-cause synthesis and tradeoffs the main agent must defend;
- tightly coupled edits with overlapping contracts;
- work whose review cost approaches doing it inline.

Bounded implementation may delegate only after the main agent fixes design, ownership, forbidden zones, and acceptance.

## Inspect → Dispatch Transition

After pre-work identifies several independent targets, stop before reading the first target's details. Decide whether they are same-shape and independently verifiable. Batch only the admitted targets; otherwise continue inline.

## Interception Transparency

- Optional dispatch unavailable/denied while the task remains possible → continue inline; an optimization is not a blocker.
- Requested outcome blocked by required permission/tool/file/network → stop and report the concrete blocker and choices.

Never hide an actual blocker or manufacture one from an unavailable optional worker.

## Completion Checklist

- [ ] All five Admission Test items passed
- [ ] Main-thread work overlapped and no spawn-then-wait occurred
- [ ] Fan-out matched independent workstreams, not artifacts or slots
- [ ] Main-agent judgment stayed inline
- [ ] Contract bounded inputs, outputs, forbidden zones, and acceptance
- [ ] Returned result was verified before integration
