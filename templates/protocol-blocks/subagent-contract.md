# Subagent Contract (drop-in block)

Every subagent dispatched via [`workflows/subagent-driven.md`](../skill/workflows/subagent-driven.md) gets a contract with **five dispatch fields** the controller fills (Goal, Inputs, Outputs, Forbidden Zones, Acceptance Criteria) **plus a required Return Status** the worker fills on the way back. Paste this block as the worker's task prompt — no main-conversation history.

**From a plan?** When the work came through a plan, these five dispatch fields are that plan's Task Breakdown task lifted verbatim — see [`../skill/workflows/plan-feature.md` § Task Breakdown](../skill/workflows/plan-feature.md) for the field mapping (Files+Produces → Outputs, Files+Consumes → Inputs, other tasks' files → Forbidden Zones, Acceptance → Acceptance Criteria). Dispatch with zero re-derivation.

```markdown
## Goal
<!-- FILL: one sentence, outcome-focused. E.g., "Extract the retry logic in api/client.ts into a reusable helper with identical behavior." -->

## Inputs
<!-- FILL: exact file paths or artifacts the worker may read. Nothing implicit. -->
- path/to/file-a
- path/to/file-b

## Outputs
<!-- FILL: exact file paths the worker must create or modify. -->
- path/to/new-helper.ts
- path/to/file-a (modified to use new helper)

## Forbidden Zones
<!-- FILL: files, directories, or side effects the worker must NOT touch. Default to "everything not in Outputs" if unsure. -->
- tests/** (except tests covering the modified files)
- package.json / lockfiles
- any unrelated modules

## Acceptance Criteria
<!-- FILL: literal, mechanically verifiable checks the main agent will run in Phase 3 Stage A. "Looks clean" is not acceptable. -->
- [ ] `<test command>` passes
- [ ] `<lint command>` passes
- [ ] `git diff --stat` shows only files listed in Outputs
- [ ] New helper has no callers other than file-a

## Return Status
<!-- The worker ends its report with exactly ONE of these words — the controller routes on it: -->
<!-- DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED -->
```

**Rules of the contract:**

1. No field may be empty. Missing field = contract is invalid, do not dispatch.
2. Goal is outcome-focused, not procedure-focused. Do not micromanage steps.
3. Forbidden Zones default to deny: if you're unsure, list it.
4. Acceptance Criteria must be executable commands or `git` checks, not prose.
5. The worker never mutates this contract. If the contract is wrong, the main agent rewrites it and re-dispatches.
6. The worker ends with exactly one Return Status word (below). A bare "done" with no status is an invalid return — treat it as `NEEDS_CONTEXT`.

## Worker Return Status (inbound contract)

The worker reports back with one of four statuses; the controller's response is fixed per status — never patch a worker's output inline in the main context.

| Status | Meaning | Controller response |
|---|---|---|
| `DONE` | All Acceptance Criteria pass, no reservations | Run Phase 3 Stage A + B, then merge |
| `DONE_WITH_CONCERNS` | Criteria pass, but the worker flags a risk it could not resolve in scope (fragile area, thin coverage, suspected latent bug) | Read the concern before merging; queue a follow-up contract if non-trivial |
| `NEEDS_CONTEXT` | Inputs were insufficient to finish; worker names exactly what is missing | Do **not** patch inline — widen `Inputs`, re-dispatch |
| `BLOCKED` | An obstruction the worker cannot resolve (permission denied, tool unavailable, contract self-contradictory) | Resolve the blocker — surface to the user per the Interception Transparency Rule when you cannot — then re-dispatch |

The worker self-reviews against its own Acceptance Criteria before choosing a status; "close enough" is not `DONE`.

*(The four-status vocabulary is adapted from the superpowers `subagent-driven-development` skill — a battle-tested return contract, not a speculative one. It earns its place by making Phase 4 routing mechanical instead of re-reading free-text prose; a project that prefers free-text returns can drop it.)*
