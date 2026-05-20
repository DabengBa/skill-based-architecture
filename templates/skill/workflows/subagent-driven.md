# Workflow: Subagent-Driven Development

> Two modes — pick the one that fits the task shape:
>
> - **Mode 1: Surface (Sub-step Auxiliary Delegation)** — main-agent inline is the default. Inside any workflow, before doing a sub-step, ask "主 agent 看这一步的全过程是多余的吗?". If yes (a 5-signal short list), surface a reverse-question proposal to the user; on Yes, dispatch one subagent for that single sub-step, then return to main-agent inline.
> - **Mode 2: Four Phases (Full Orchestrator Pattern)** — the task is planned from the start as multi-subtask work. Main agent writes contracts, dispatches in parallel, two-stage reviews each, merges. Use case: ≥ 3 independent subtasks, > 30% context budget at risk, classic explore + implement + review pattern.
>
> Mode 1 covers most day-to-day tuning (the case the upstream chaos screenshots show); Mode 2 covers planned multi-subtask runs. Pick by task shape, not by ceremony preference.

## Harness Compatibility (shared by both modes)

| Harness | Mode 1: Surface | Mode 2: Four Phases |
|---|---|---|
| Claude Code | Full — real subagent dispatch via `Task` tool | Full — native parallel `Task` dispatch |
| Cursor / Codex / Gemini / Copilot | Degraded — falls back to **information-display isolation** (see § "Mode 1 on degraded harness" below) | Degraded — see § "Degraded Mode" at the end of this file (Mode 2 specific) |

**Degraded modes are not worthless** — the discipline (reverse-question for Mode 1, contract + two-stage review for Mode 2) still produces value without process isolation. Run the protocol; skip only the literal dispatch.

---

## Mode 1: Surface (Sub-step Auxiliary Delegation)

**Default execution model is unchanged**: main-agent inline does the work. Mode 1 only fires when a specific sub-step inside a workflow matches one of a small concrete-signal list. Then main-agent **surfaces a reverse-question proposal** to the user; user decides Y / N; silence = inline (no change to fallback).

### Signal admission test (both gates must pass)

Before adding any new signal to the list below, check:

1. **Reverse-question passes** — "主 agent 看这一步的全过程是多余的吗?" answers **yes** in the typical case
2. **Scenario is specific** — mechanical + time-consuming + only-need-result

Pass only #1 (reverse-question yes but scenario fuzzy) → don't add; agent will start "surfacing everything".
Pass only #2 (scenario concrete but reverse-question no) → don't add; overlaps with main-agent's actual job.

### Signal list (5 reverse-question signals)

1. **"主 agent 看测试跑的全过程是多余的吗?"** — running tests (≥ 30s; any `mvn test` / `pytest` / `jest` / `go test`) → verify subagent
2. **"主 agent 看构建 / 依赖解析全过程是多余的吗?"** — running build / dependency resolution (`mvn install`, `gradle build`, `npm install`, `npm build`) → build subagent. Project-level rules may suppress this signal (e.g., a project that requires the human to run Maven through their IDE).
3. **"主 agent 读完所有 grep / find usage 命中是多余的吗?"** — wide search (≥ 10 file hits) → explore subagent
4. **"主 agent 逐个文件改这堆同型编辑是多余的吗?"** — batch homogeneous edits (≥ 5 files, same-shape import add/remove / rename / annotation add) → refactor subagent (can hand off to `refactor-fanout.md`)
5. **"主 agent 翻完这段代码找 pattern 是多余的吗?"** — code scan for pattern (single file ≥ 1000 lines, or multi-file cumulative ≥ 1500 lines, looking for N callsites / patterns) → scan subagent

### Job-vs-auxiliary distinction (not file-counting; ask what the content is used for)

After reading / running, ask:

- Does the main agent **need the content as discussion / decision substrate** (user might ask about details, design choice needs reference, explanation to user uses it) → **main-agent job**, do it inline
- Does the main agent **only need the result for the next decision** (the process won't be referenced again, user won't ask "how did you run it") → **auxiliary**, reverse-question, possibly dispatch

Examples:

| Scenario | What main agent uses the content for | Verdict |
|---|---|---|
| Fix NPE; read 3 files to locate root cause | Use context to decide the fix + discuss with user | Main-agent job |
| Explore "how does auth work"; read 5 files | Understand it + explain to user | Main-agent job |
| Find 12 callsites of X; pick which to change | Only need the list | **Auxiliary** (dispatch for list) |
| Find 12 callsites of X; review each to decide change | Need each file's content | Main-agent job |

**Key**: the same action (read N files) can be main-agent's job or auxiliary, **depending on what the content is used for**. The cut is by purpose, not by action size.

### Decision flow

```text
main agent runs workflow inline
    ↓
about to do next sub-step: ask self "看全过程多余吗?"
    ├── no, main-agent's job  → inline
    └── yes, auxiliary (mechanical + time-consuming + only-need-result)
            ↓
        reverse-question surface to user
            ├── Yes → dispatch one subagent for this sub-step → subagent
            │           returns result → main agent continues inline
            └── No / silence → main agent does this sub-step inline
```

**Properties**:

- Signal recognition is an **agent judgment**, not a mechanical measurement; the admission test (reverse-question + specific scenario) is the discipline
- Yes dispatches a **single sub-step**, not the remaining whole task
- After subagent returns, main agent goes back to inline as default
- Same task may trigger multiple Surface events (one for testing, one for wide grep, etc.); each is independent — previous Y/N doesn't affect the next

### Signal is *not*

- Not a task-size signal (test ≥ 3 cycle / refactor ≥ 5 callsites / large file / cross-repo — all rejected; reverse-question doesn't pass on them)
- Not a file-count or time threshold (too coarse; not causal with main-conversation pollution)
- Not "anything time-consuming the main agent does should be dispatched" — discussing code, clarifying with user, designing, deciding-where-to-change are all main-agent's job even if time-consuming
- Not a checkpoint block in workflow files (signal recognition is in the agent's head)
- Not a PostToolUse hook (simple tasks must have zero overhead; hooks violate that)

### Mode 1 on degraded harness (Codex / Cursor / Gemini): information-display isolation

These harnesses have no native dispatch. Mode 1 still applies — falls back to **display isolation**:

- **Yes** = main agent runs the sub-step but **only pastes the conclusion**:
  - Test pass → "passed" (one line)
  - Test fail → "failed: `<short reason>`, missing mock `<specific>`" (2-3 lines)
  - Grep hits → hit list (one line per hit, no file contents)
  - Batch edit → diff summary (`changed N files, main edits: <one line>`; full diff on request)
- **No** = main agent runs the sub-step and **pastes full output** (traditional inline)

CC vs degraded comparison:

| | CC (Yes) | Degraded (Yes) |
|---|---|---|
| Context isolation | Real (separate subagent context) | None (same context) |
| Main conversation visual | Clean (subagent internals never visible) | Compressed (conclusion only) |
| Token / context accumulation | Low (main context doesn't grow) | **Same as No** (agent still reads everything) |
| `/compact` risk | Low | **Same as No** |

The real benefit on degraded harnesses: **user reading conversation history isn't drowned in stack traces**. Token cost doesn't drop, but display density does. Yes / No actually produce different visible outcomes on degraded harnesses, not just on CC.

---

## Mode 2: Four Phases (When to Invoke This Mode)

Trigger Mode 2 — not just inline + occasional Mode 1 Surface — when **any** of:

- The task decomposes into **≥ 3 independent subtasks** (independent = can be specified, executed, and verified without reading each other's output)
- A single subtask will consume **> 30% of remaining context budget** if done inline
- The work involves **exploratory search + implementation + review** (classic context-pollution pattern)
- You are about to start a **multi-hour autonomous run**

If none of the above apply, **don't invoke Mode 2** — Mode 1 Surface inside an ordinary workflow handles smaller cases without ceremony.

### Phase 1 — Plan

Write the full task list **before** touching any subagent or file.

For each item, produce a **Subagent Contract** with exactly five fields:

1. **Goal** — one sentence, outcome-focused, not procedure-focused
2. **Inputs** — exact file paths, data, or upstream artifacts the worker may read
3. **Outputs** — exact file paths the worker must produce or modify
4. **Forbidden Zones** — files, directories, or side effects the worker must not touch
5. **Acceptance Criteria** — the literal checks the main agent will run in Phase 3

Reject any contract you can't verify mechanically. "Make it clean" is not an acceptance criterion. "`grep -c FILL skills/{{NAME}}/` returns 0" is.

**Stop condition for Phase 1:** the full plan must be written down (in a scratch file, the conversation, or a TodoWrite list) before dispatching the first worker. Verbal plans drift.

### Phase 2 — Dispatch

For each contract:

1. Spawn a fresh worker (Claude Code: `Task` tool with the appropriate `subagent_type`; degraded mode: execute inline but reset your mental context — re-read only the contract)
2. Pass the contract verbatim as the task prompt. Do **not** paste the main conversation history.
3. Include the **Iron Law header** ("NO TASK IS COMPLETE WITHOUT A TASK CLOSURE PROTOCOL SCAN" — main work + 30-second AAR + record-if-needed) so the worker knows Task Closure Protocol applies to them too.
4. Dispatch workers **in parallel** when their contracts have no ordering dependency. Sequential dispatch is a defect unless justified.

**Dispatch discipline:**

- Never stream mid-task "clarifications" into the worker's context. If the contract was wrong, cancel and rewrite the contract.
- Never let a worker spawn its own workers (no recursion). Flatten the plan instead.
- Never ask a worker to review its own output.

### Phase 3 — Two-Stage Review

When a worker returns, the main agent runs **both stages** against its output. Do not merge after only one stage.

**Stage A — Spec Compliance**

- [ ] Did the worker produce every file listed in `Outputs`?
- [ ] Did the worker touch any file in `Forbidden Zones`? (Run `git status` / `git diff --stat` to verify.)
- [ ] Does every acceptance criterion pass when executed literally?
- [ ] Are there drive-by changes not covered by the contract? (Drive-bys are defects even if they look helpful.)

If any Stage A check fails → **reject and re-dispatch** with a corrected contract. Do not patch the worker's output inline in the main context; that re-pollutes the main window.

**Stage B — Quality Review**

- [ ] Code quality per `skills/{{NAME}}/rules/coding-standards.md`
- [ ] No swallowed errors, no silent fallbacks, no hardcoded secrets
- [ ] New gotchas surfaced? → candidate for `references/gotchas.md`
- [ ] Task Closure Protocol 30-second AAR scan on the delta (see [SKILL.md](../SKILL.md) Principle 10)
- [ ] Recording threshold (2/3) applied to any new findings

If Stage B finds issues but Stage A passed → record the issues, then decide: re-dispatch (preferred for non-trivial issues) or accept with a follow-up contract queued.

### Phase 4 — Merge or Reject

- **Merge**: only when both stages pass. Write one summary line per merged contract into the running task log.
- **Reject**: cancel the worker's changes (`git restore`, revert the diff, or discard the worker's patch). Rewrite the contract. Re-dispatch. Do **not** fall into the "I'll just fix it myself in the main context" trap — that's the exact failure mode subagent-driven development is designed to prevent. See the Rationalizations table.

---

## Rationalizations to Reject (both modes)

| Rationalization | Rebuttal |
|---|---|
| "It's faster to just do it myself in the main context" | True for 1 task, false for 3+. You're optimizing the wrong loop. |
| "The worker almost got it right, I'll patch the last 10%" | Inline patching re-pollutes the main context. Re-dispatch with a tighter contract. |
| "I don't have time to write a contract for this small task" | If the task is small enough to skip a contract, it's small enough to not need a subagent. Decide which. |
| "Parallel dispatch is risky, I'll do them sequentially" | Sequential dispatch without a data dependency is a latency defect. Justify it in writing or parallelize. |
| "The worker can figure out the acceptance criteria from context" | Workers have no context. That's the point. Write the criteria. |
| "I'll let the worker spawn its own helpers" | Recursive dispatch makes review impossible. Flatten the plan in Phase 1. |
| "Mode 1 Surface: I'll skip the reverse-question, I know this is auxiliary" | The reverse-question is the admission test. Skipping it is how main agent ends up doing auxiliary work it shouldn't. Just ask the question. |
| "The user is busy, I'll skip the Mode 1 Surface prompt and dispatch silently" | Silent dispatch removes user control. Surface, then take silence as "continue inline" — that's by design. |

## Red Flags — STOP (both modes)

Stop the workflow and reassess if any of these appear:

- You find yourself reading worker output and editing it inline in the main context
- You dispatched a worker without a written contract (Mode 2) or without surfacing the option to the user (Mode 1)
- A worker returned, Stage A failed, and you're tempted to "just accept it and fix later"
- You're on the third re-dispatch of the same contract → the contract is wrong, not the worker
- You notice the main context has grown past 50% — you're losing the point of the pattern
- A worker asks a clarifying question mid-task → cancel, rewrite contract, re-dispatch
- Mode 1: you surfaced "看全过程多余吗" on a main-agent's job task (e.g., reading a single file to understand a bug) → the admission test failed; revisit the job-vs-auxiliary distinction

---

## Degraded Mode (Mode 2 specific, no native dispatch)

When the harness has no subagent primitive and you're invoking **Mode 2** (Mode 1 on degraded harnesses uses display isolation; see § "Mode 1 on degraded harness" above), simulate the discipline:

1. Write the contract in a scratch file
2. Clear your mental state: re-read **only** the contract, ignore prior conversation
3. Execute the contract
4. Return to "main agent" mode: re-read the contract, run Stage A + Stage B against the diff
5. Merge or revert

You lose process isolation but keep contract discipline and two-stage review. That alone catches most drive-by defects.

<!-- FILL: project-specific Phase 3 verification commands (test runner, lint, type-check) -->
<!-- FILL: project-specific Forbidden Zone defaults (e.g., migrations/, vendored deps) -->
