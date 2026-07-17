# Minimal Sufficient Context

Use this during route intake and re-enter it whenever the workflow discovers new risk. "Small" means a narrow context footprint, not lower correctness.

## Ownership

- **Route intake owns variable rigor** — choose the initial read set and expand only when signals appear.
- **Workflow owns invariant core** — `fix-bug` still reproduces, root-causes, fixes, and validates; `change-managed` still scopes, maps source of truth, syncs, and checks drift.
- **Task closure owns completion rigor** — use `workflows/task-closure.md`; do not restate closure trigger policy here.

## Initial Read

Start with:

1. Always Read files
2. The matched route's `required_reads`
3. The matched workflow
4. The smallest code/docs slice that can prove or disprove the next step

Do not preload architecture, gotchas, broad references, or extra workflows "just in case." Add them when a signal below appears.

## Expand Context When

Read more before continuing if any signal appears:

- target file, component, owner, or entry point is unclear
- root cause or source of truth has more than one plausible location
- change crosses modules, skills, public APIs, schemas, permissions, config, generated files, or shared runtime state
- code evidence conflicts with the user's report, tests, logs, or existing docs
- expected behavior depends on a business type, macro flow, state transition, boundary, or invariant: read the routed `references/business/<module>.md`; if completely absent and blocking, ask whether to model now; if present but locally unclear, search evidence first, ask only the missing macro question, and reconcile the existing file in place
- the first fix/plan attempt fails, or the premise becomes unstable
- a routed file names a task-specific gotcha, convention, source index, or compatibility note

Expansion is additive: load the one reference, rule, caller set, or workflow needed by the signal; do not restart by reading the whole skill tree.

## Validation Escalation

Pick the smallest fresh evidence that proves the changed behavior:

- **Command evidence** — targeted unit test, script, typecheck, compile, grep, or generated-file check proves logic, transformation, branching, or syntax.
- **Runtime evidence** — start local app/service/browser or hit an interface only when wiring, config, permissions, serialization, data state, or UI behavior cannot be proven by command evidence.
- **Release evidence** — full build, packaged artifact, deploy dry-run, or release-chain check only when build/deploy/release mechanics changed or the user's request explicitly requires it.

For UI/frontend work, start the environment when useful, then default to human verification for subjective visual acceptance unless the user explicitly asks the agent to inspect.

## Non-Goals

- Do not split workflows or routes by size (`small-fix-bug`, `large-fix-bug`).
- Do not add inert flags such as `rigor: dynamic` unless a script or workflow consumes them.
- Do not copy this ladder into every workflow; point workflows here when their default read set would otherwise become a safety blanket.
