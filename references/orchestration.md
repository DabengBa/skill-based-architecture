# Reference — Project-Level Orchestration Patterns

Read this when a downstream project uses multi-agent execution and needs durable docs for `spawn_agents_on_csv`, wave-based orchestration, checkpointing, or structured worker contracts.

This file does **not** change the scope of the meta-skill: orchestration remains project-specific engineering. The point here is to prevent teams from rediscovering the same documentation shape from scratch once they do adopt orchestration.

## Positioning

`skill-based-architecture` still treats orchestration as out of scope for shared templates. What *is* in scope is documenting where that knowledge should live once a project depends on it:

- Project-level execution contract → `workflows/`
- Stable orchestration invariants and anti-patterns → `rules/` or `references/`
- Task routing to those files → project `SKILL.md` and thin shells

If a project uses `spawn_agents_on_csv` and nobody can answer "what is the master state, what is a wave, what do workers return, and how do we resume?", the project does not yet have usable orchestration docs.

## Pattern to Preserve

The highest-value reusable pattern observed in `maestro-flow-one` is a **CSV-wave orchestration contract**:

1. A coordinator owns state and assembles prompts.
2. A master CSV is the source of truth for task state.
3. Each wave is materialized as a temporary per-wave CSV.
4. `spawn_agents_on_csv` executes one worker per row.
5. Results are written to a results CSV with a fixed schema.
6. The coordinator merges results back into the master CSV before starting the next wave.

This matters because it moves orchestration state out of chat history and into explicit artifacts.

## Core Contracts

### 1. Coordinator does orchestration, not task work

The coordinator should primarily:

- classify steps
- build or filter the current wave CSV
- inject prior context into rows
- call `spawn_agents_on_csv`
- merge results
- decide whether to continue, branch, retry, or abort

Do not let the coordinator half-execute the same work it is dispatching. That creates split ownership and hidden state.

### 2. Master CSV is the source of truth

Keep durable state in one master table, not scattered across chat summaries.

Typical columns:

```csv
id,title,deps,context_from,wave,status,findings,error
```

Add domain-specific fields as needed, but keep orchestration fields explicit:

- `id`
- `deps`
- `context_from`
- `wave`
- `status`
- `findings`
- `error`

### 3. Per-wave CSVs are temporary execution slices

Wave files should contain only the rows needed for the current execution step.

Typical forms:

```csv
id,skill_call,topic
```

or

```csv
id,title,description,prev_context
```

Use `prev_context` only when the worker genuinely needs prior-wave findings. Do not make workers infer dependencies from unrelated files if the coordinator can assemble the needed context directly.

### 4. Barrier steps are solo; non-barriers may parallelize

Preserve a clear distinction:

- Barrier steps: plan generation, synthesis, final verification, other checkpoint-like nodes
- Non-barrier steps: independent exploration, scanning, review dimensions, per-scenario test writing

If a step consumes many predecessors or emits a canonical artifact, run it solo.

### 5. Decision nodes stay outside row execution

Do not bury branch logic inside worker rows when the branch determines the next wave.

Examples:

- proceed vs retry
- fix loop insertion
- skip downstream tasks
- escalate to user

Those are coordinator decisions between waves, not row-level side effects.

### 6. Result schema is mandatory

Workers should return a narrow, enforced schema. A useful default:

```json
{
  "id": "string",
  "status": "completed|failed|blocked",
  "findings": "string",
  "error": "string"
}
```

If workers create artifacts, add an explicit artifact field rather than forcing the coordinator to scrape prose.

### 7. Worker contract must be explicit

When using `spawn_agents_on_csv`, document the worker rules in the project workflow:

- what each row means
- which files the worker may or may not touch
- whether shared state files are read-only
- what must be reported through `report_agent_job_result`
- what counts as success vs partial success vs failure

If workers are forbidden from editing session state, say so directly.

## Recommended File Placement in a Project Skill

When a project depends on this pattern, record it in the project skill like this:

- `workflows/orchestrate-csv-wave.md`
  Describes the execution loop: build wave, spawn, merge, checkpoint, resume.
- `references/orchestration.md`
  Describes the stable contracts, schemas, and anti-patterns.
- Project `SKILL.md`
  Routes orchestration tasks to those files.

Do **not** put all orchestration detail in the project `SKILL.md`. Route to it there; store the real contract in workflow/reference files.

## Anti-Patterns

### Hidden state in conversation only

If the only record of progress is "the agent probably already knows wave 1 finished", the system is fragile. Store it in files.

### No master state file

Without a master CSV or equivalent state artifact, retries and resume logic become guesswork.

### Workers discover dependencies implicitly

If a worker has to reconstruct upstream context by reading broad project history, the coordinator failed to assemble the row contract.

### Barrier work parallelized anyway

Parallelizing synthesis or checkpoint nodes usually trades a small speed gain for a large coordination failure surface.

### Decisions embedded in result prose

If the coordinator has to infer branch decisions from long natural-language findings, the schema is too weak.

### Contracts stored but not activated

If orchestration rules exist only in a deep reference file and the normal task path never points at them, future agents will still violate them. Surface the contract in the task route that uses it.

## Minimal Checklist for Recording

If a project adopts `spawn_agents_on_csv`, record at least these facts:

1. What file is the durable state source of truth?
2. What defines a wave?
3. Which steps are barriers?
4. What row schema do workers receive?
5. What result schema must workers return?
6. How is prior-wave context propagated?
7. What is the retry/resume path after a failed wave?

If any answer only exists in team memory, the orchestration is under-documented.
