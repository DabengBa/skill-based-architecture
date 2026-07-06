# Reference — Splitting a Skill by Abstraction (骨架 / 肉)

When a `rules/` (or `references/`) file tangles invariant design theory with current-code facts, split it by **abstraction** ([Progressive Rigor](progressive-rigor.md) trigger 3). This is the playbook, distilled from doing it on two real code-coupled skills. It is a *re-tiering of an existing skill*, not the initial scattered→skill migration ([full-migration.md](../workflows/full-migration.md)).

**The judgement test:** *after a big refactor that renames modules and moves files, is this statement still true and useful? Yes → 骨架 (skeleton: invariant theory). It describes the current code — a map / name / path / a landmine at a symbol → 肉 (flesh: current-code facts).*

> Rate of change is a correlated heuristic, but it mislabels **slow-drifting maps** (the module tree) as architecture — they are stable-ish yet they are flesh (a map of the code, not an invariant law). Abstraction is the real cut.

> **Cohesion exception — don't shatter a decision subsystem.** The split distributes by abstraction, but a *tightly-coupled decision subsystem* — a classifier plus the data it classifies — stays cohesive in **one** artifact even when its rows differ in rate-of-change. The permission model's 🔴 rows (invariant) and 🟡 rows (mutable) live in **one** table, not split 🔴→`architecture/` and 🟡→`conventions/`; splitting a decision procedure by rate-of-change makes it un-runnable at a glance and scatters the "what are all my rules" view. Safe because the harm the split guards against — a slow invariant re-churned by fast facts — is a *prose-tangling* harm; a table of discrete rows doesn't tangle (changing one row never forces another). **Cohesion of a decision procedure beats rate-of-change distribution.** (Generic engine still skeleton, project rows still flesh — see §7 two-root; only the tiers *within* the data table stay merged.)

## 1. Classify by abstraction — five buckets

The split is not binary. Going section by section, each lands in one of:

| Bucket | → | Kind | Example |
|---|---|---|---|
| **Abstract design theory** — layering/contract/orchestration **principles**, the "why" (NOT the module map) | `architecture/` | 骨架 | "an existing HTTP contract is a compatibility boundary" |
| **Code maps** — module tree, package/dir layout, source index, the call graph with real symbols | `references/` | 肉 | "modules: web → biz/shared → core → common/dal" |
| Volatile house style — naming, route shapes, paths, commands, formats | `conventions/` | 肉 | "`POST /{entity}/create`", "param names `page`/`limit`" |
| Code-coupled landmines — symptom→cause→fix on specific symbols | `gotchas/` (per module) | 肉 | "change a Controller, rebuild the `start` fat-jar or you run stale bytecode" |
| **Cross-cutting agent behavior / methodology** — delegation discipline, change-discipline, transparency-on-block, AAR triggers | **stays in `rules/`** | 骨架 | subagent-delegation Iron Law |

**Two buckets get missed.** (1) The **code map** looks like architecture but is flesh — `modules-and-packages.md`, a directory layout, a call graph with class names *describe the current code* and drift on every refactor; they go in `references/`, not `architecture/`. Mixing them in makes `architecture/` diverge (re-describing the code) instead of converging on the few invariant principles. (2) **Methodology** is neither architecture nor convention nor gotcha — `rules/` survives as its home (why the template ships `rules/agent-behavior.md`). `architecture/` should end up small and sparse: abstraction is compact.

## 2. Author the new files: verbatim, no duplication, cross-link

- **Reproduce technical content verbatim.** Method names, paths, field names, commands, error codes are the value — never paraphrase or summarize a rule or a gotcha.
- **Do not duplicate content that already lives in another tier file.** A new `architecture/api-contract.md` must not re-print the response-envelope mechanism already in `architecture/response-envelope.md` — cross-link (`[[response-envelope]]`) instead. Duplication re-creates the scatter you are trying to fix.
- **Gotchas stay whole, one file per module.** A bug should read one small module file (`gotchas/hotfix.md`), not a 200-line dump. Don't lump unrelated modules into one file.
- **Consolidate existing scatter.** If the same concept is stated across several old files (one principle repeated in `rules/` and a pitfall file; a module table duplicated in two references; a rule and its later rollback as separate entries), collapse it into one canonical home in the new tier and cross-link from the rest — don't carry the duplication forward. Likewise **elevate** a stable structural fact that was mis-filed as a gotcha up into `architecture/`, so routing surfaces it.

## 3. A split is a path migration — repoint or stub every old-path reference

Moving content out of `rules/backend-rules.md` or `references/gotchas.md` changes the path other files point at. Before deleting an old file:

1. `grep` for every reference to the old path across `workflows/`, `routing.yaml`, thin shells, and `SKILL.md`.
2. **Repoint** the references you own to the new tier paths.
3. For paths hard-referenced by files you can't or won't edit yet (e.g. assembled/vendored copies), leave a **redirect stub** that points to the new home and *actively corrects the stale instruction* ("record new gotchas in `gotchas/<module>.md`, not here"), then delete it once those references are mirrored.
4. **Delete old files with zero remaining references.** An unreferenced redirect stub is itself an orphan — only keep a stub that something still points at.

> A markdown `[]()` link is validated by `smoke-test`'s link check; a bare path in inline code is not. So a redirect's `[]()` links must resolve, but inline-code path mentions are free.

## 4. Every fine-grained tier needs a routed index hub — link-reachable ≠ activated

There are two different "reachable", and they are easy to conflate:

- **Link-reachable** (what `audit-orphans.sh` checks) — some scanned file mentions the path, so it isn't an orphan. **Necessary but not sufficient.**
- **Route-reachable** (activation) — some task's route actually leads the agent to read it during work.

A file can pass `audit-orphans` (e.g. listed in the `SKILL.md` manifest) yet **never be read**, because it is on no task route. That is "stored, not activated" at fine grain — and it is pure waste: you split the file out for cohesion, but the task that needs it never sees it. Real case: a skill split `architecture/` into 9 files but routed only ~4; `architecture/transactions-locks.md` was link-reachable but on no route, so transactional work never read the transaction invariants.

The fix is the hub pattern gotchas already use, applied to **every** fine-grained tier:

- Give each fine tier an `index.md` hub with a **"read when"** column (`transactions-locks.md → read when multi-step write / lock / async`).
- **Route the hub, not every file.** A task's `required_reads` is the relevant hubs (`architecture/index.md`, `conventions/index.md`, `gotchas/index.md`) — small, and complete. The agent reads the hubs and pulls the specific files its change touches. Enumerating every file in every route instead either balloons `required_reads` or silently drops the conditional ones.
- **Reading the hub is not reading the content.** After the hub, either pull the specific files whose "read when" matches the task, or **state explicitly that nothing matched and no second hop is needed** — silently treating hub-read as content-read is the failure mode this pattern creates.
- List each file in its hub as an **inline-code skill-root-relative path** (e.g. `architecture/transactions-locks.md`) — that one string doubles as the `audit-orphans` inbound *and* the path the agent reads. Register a new file in its hub the moment you create it, or it is born unreachable. (A *relative* markdown link to just `transactions-locks.md` does **not** satisfy `audit-orphans` — it lacks the tier prefix.)

## 5. Re-derive routing — the split is also a routing redesign

A move that leaves routing untouched produces incoherent routes.

- **Repoint `always_read`** off the split files onto the small cross-cutting set (agent-behavior + change-discipline, optionally the structural spine) — not the old mixed governance files.
- **Re-derive each route's `required_reads`** as the relevant tier hubs (§4) so the agent reaches the specific files it needs, together. The classic failure: `fix-bug` read the pitfalls file but not the architecture rule it needed to act — half an answer.

## 6. Validate

- `audit-orphans.sh` → **0 orphans** (every tier file is link-reachable).
- `route-reachability.sh` → **0 unreachable** (every active-tier file is route-reachable — on a route or in a routed index hub, §4; this is the check that catches the stored-not-activated waste).
- `smoke-test.sh <name>` → tier checks pass (`constraint surface` across rules/architecture/conventions; gotchas tier recognized); `routing.yaml` ≤ 140 lines.
- `route-health.sh <name>` → no routing-quality smells.

## 7. Scaling the split across two repos (skill_root / code_root)

The abstraction line above is also the natural **repo boundary**. When one skill's skeleton is *shared* — the same `architecture/` + `workflows/` + `rules/` serve many code checkouts, or a tool assembles the skill into each consumer's tool dir — split the skill across **two roots**, cut on the same 骨架/肉 line:

| Root | Owns | Why there |
|---|---|---|
| **`skill_root`** (shared / upstream "元仓") | `SKILL.md`, `routing.yaml`, `architecture/`, `rules/`, `workflows/` — skeleton + entry + routing — plus the checkout-invariant slice of `gotchas/` / `references/` (see below) | invariant; one copy, assembled/vendored to each consumer |
| **`code_root`** (per-codebase facts) | `conventions/`, `gotchas/`, `references/` — flesh | drifts with the code; lives in the code repo so it changes in the **same PR** as the code it describes |

No new concept — the skeleton/flesh cut you already make *inside* a Full skill (§1) is just drawn at the repo boundary instead.

**Which root? — the checkout-coupling test.** *Could this content legitimately differ between two simultaneously active checkouts (branches / release lines) of the code repo?* Yes → `code_root` (it must travel with the checkout it describes). No — identical for every checkout → `skill_root`. This test decides **repo placement only**; tier membership still follows §1's abstraction test. The two axes answer different questions and may disagree on the same item — that is legal, not a contradiction: the `start` fat-jar gotcha from §1 is *flesh by tier* (it names symbols; a refactor invalidates it) yet *skill_root by coupling* (the toolchain landmine holds on every checkout). So `gotchas/` and `references/` are **not** wholesale code_root: framework/toolchain-mechanism landmines that hold for every checkout live in the skill_root's own `gotchas/`, while symbol-and-state-coupled landmines stay in `code_root` — a mixed file goes where its majority lives, with a note flagging the minority entries for re-check when the implementation moves. Do **not** use the coupling test as a tier test — "same on every branch" does not make a code map architecture (§1's warning about slow-drifting maps applies unchanged).

**Routing joins the two roots with a source prefix.** `routing.yaml` lives in `skill_root`, declares a `path_resolution` block, and prefixes every `required_reads` / `workflow` with `skill:` or `code:`, so one route composes both — architecture principle (`skill:`) + current code facts (`code:`) for the same task:

```yaml
path_resolution:
  skill_root:        # shared skeleton, assembled into each consumer's tool dir
    owns: [SKILL.md, routing.yaml, architecture/**, rules/**, workflows/**]
  code_root:         # per-codebase flesh, lives in the code repo
    root: apps/<app>/skills/<name>
    owns: [conventions/**, gotchas/**, references/**]

tasks:
  - id: style-ui
    labels: { en: Adjust UI / interaction, zh: 调整前端样式 }
    required_reads:
      - skill:architecture/index.md     # skeleton, from 元仓
      - code:conventions/index.md       # flesh, from the code repo
      - code:gotchas/index.md
      - code:references/source-index.md
    workflow: skill:workflows/change-managed.md
    trigger_examples: [调整样式, UI 优化, antd 样式]
```

**When NOT to.** A single-repo skill needs neither prefixes nor `path_resolution` — keep the default single-root layout (one `skills/<name>/` dir, plain `workflows/X.md` paths). Two roots pay off only when the skeleton is genuinely shared across ≥ 2 code checkouts or centrally assembled; otherwise it is split-for-its-own-sake.

**What changes under two roots:**

- The `code_root` dir is **not** the entry — its `SKILL.md` is a thin stub that points at `skill_root` (entry / routing / skeleton live upstream).
- `audit-orphans` / `route-reachability` run **per root**; same-dir cross-links keep working because each root still holds its own tier dirs.
- The assembler that materializes `skill_root` into consumer dirs is **project-specific** — SBA specifies the *split + prefix contract*, not the tool.
- When a tier glob (e.g. `gotchas/**`) appears under **both** roots' `owns` (legal per the coupling test above), resolution follows the **path prefix** on each reference (`skill:` / `code:`) — `owns` documents intent; the prefix is the contract the scripts resolve.
- **Cross-repo writes need a guard.** Before a workflow writes into the *other* root (or any path outside the current skill dir), run a literal existence check on the target root (e.g. `test -d <code_root>/.git`) and **stop on failure** — never silently `mkdir` the target tree in whatever repo you happen to be in. (Real downstream failure: docs nearly created at the meta-repo root, where the assembler would never ship them.)
- **The repo root between the two roots is a machine-check blind spot.** Content parked there — shared workflow fragments, protocol-blocks, orchestration docs — is scanned by *neither* root's `audit-orphans` / `route-reachability` / smoke-test, and an assembler that materializes only `skill_root` won't ship it, so repo-root references break silently after assembly (a real downstream shipped a dangling `protocol-blocks/` link exactly this way). Shared fragments must either be materialized by the assembler into each skill, or vendored into each skill **with a mechanical equality check across the copies** — two hand-mirrored copies without one is pseudo-dedup that will silently drift.

## Mechanical notes

- **Watch for assembled / vendored copies.** If the file you're editing is a byte-identical assembled copy of an upstream source (vendor-class, or generated by an assembler), editing it in place gets clobbered on the next sync — confirm the source of truth first.
- **Fanning out the authoring?** If you dispatch one subagent per target file in parallel, **batch ~4 concurrent**. A burst of a dozen+ heavy file-authoring agents reliably trips API connection resets (`ECONNRESET`); small batches do not.
