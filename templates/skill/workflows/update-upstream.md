# Update From Upstream

Use when the user says the upstream skill-based-architecture project changed and asks the agent to update this downstream project. The user should not have to run diffs; the agent owns comparison, patching, and validation.

<!-- upstream-source: repo=https://github.com/WoJiSama/skill-based-architecture.git -->

## Hard Rules

1. **No blind overwrite** — never copy an upstream file over a downstream file without reading both.
2. **Project knowledge wins** — preserve project-filled rules, gotchas, workflows, routing examples, descriptions, boundaries, and validation commands.
3. **Agent does the diff** — do not ask the user to compare files. Ask only when a semantic conflict cannot be resolved from local evidence.
4. **Patch, don't replace** — apply upstream improvements as small edits with `apply_patch` or equivalent. Whole-file replacement is allowed only for a missing file or a file verified to be an unmodified old upstream template.
5. **Upstream notes stay upstream** — read `$tmp/upstream/UPSTREAM-CHANGES.md` when present, but never create, copy, or update `UPSTREAM-CHANGES.md` in the downstream project.
6. **Generated shells stay generated** — do not hand-edit generated routing blocks; update `routing.yaml`, then run `scripts/sync-routing.sh`.

## Procedure

1. **Preflight** — run `git status --short`; note existing local changes and do not revert them. Identify `NAME` and `skills/<name>/`.
2. **Fetch upstream** — clone the latest upstream to a temp directory:
   ```bash
   tmp="$(mktemp -d)"
   git clone https://github.com/WoJiSama/skill-based-architecture.git "$tmp/upstream"
   ```
3. **Read upstream update notes, scoped to your sync point** — run `bash "skills/$NAME/scripts/upstream-status.sh" "$NAME" --upstream "$tmp/upstream"`. It lists exactly the `UPSTREAM-CHANGES.md` entries added since this project's recorded `.upstream-sync` (no pointer yet → it shows the newest entries). **That list is your work-list for this refresh** — read those entries in `$tmp/upstream/UPSTREAM-CHANGES.md` to learn likely changed areas and intended downstream handling. Use them as a map, not as proof that a file should change, and do not copy the changelog into the downstream repo. **Skip any entry whose first bullet is `- Status: superseded by …` or `- Status: deprecated …`** — superseded entries describe guidance that has since been reversed (follow the newer entry the line points to instead); deprecated entries describe mechanisms that were removed entirely.
4. **Classify files before editing**
   - Upstream-only: `$tmp/upstream/UPSTREAM-CHANGES.md`. Read during refresh; never port into downstream.
   - Project-owned: `rules/project-rules.md`, `rules/coding-standards.md`, `references/gotchas.md`, project-specific workflows, `SKILL.md` prose, `routing.yaml` task examples, and `.upstream-sync` (this project's recorded sync point — maintained locally, never ported from upstream). Preserve; merge manually if needed.
   - Mechanism-owned: `scripts/*.sh`, `scripts/_parse_conformance.py`, `conformance.yaml`, universal hooks, protocol-blocks, reusable workflow scaffolding. Compare and port useful upstream changes. The local `conformance.yaml` is a **snapshot from initial scaffold** — overwrite it from upstream after a successful refresh; otherwise it silently re-validates against the old contract.
   - Generated: Always Read, Common Tasks, thin-shell bootstraps. Regenerate only.
5. **Scan for new mechanism files** — list files under `$tmp/upstream/templates/skill/scripts/`, `$tmp/upstream/templates/skill/workflows/`, `$tmp/upstream/templates/protocol-blocks/`, and `$tmp/upstream/templates/hooks/` that have no counterpart in your skill. Examples this pass already shipped: `conformance.yaml`, `check-version-conformance.sh`, `_parse_conformance.py`. For each missing mechanism file, copy whole-file as new (Hard Rule #4 permits this for missing files). After copy, treat the new file as mechanism-owned for future refreshes — it joins the comparison set in step 6.
6. **Compare as the agent** — for each candidate upstream file, inspect local and upstream versions (`git diff --no-index` is fine). If local contains project-specific edits, keep them and cherry-pick upstream improvements into the local file.
7. **Use upstream history only as evidence** — if considering whole-file replacement, verify the local file matches a previous upstream version from the cloned repo's history. If no exact historical match, do not replace.
8. **Update routing deliberately** — add a route only when the downstream project should expose that task. Preserve existing task ids and trigger examples unless clearly obsolete.
9. **Validate**
   ```bash
   bash "skills/$NAME/scripts/sync-routing.sh" "$NAME"
   bash "skills/$NAME/scripts/sync-routing.sh" "$NAME" --check
   bash "skills/$NAME/scripts/smoke-test.sh" "$NAME"
   (cd "skills/$NAME" && bash scripts/audit-orphans.sh)
   bash "skills/$NAME/scripts/route-health.sh" "$NAME"
   ```
10. **Conformance check — use upstream's manifest, not local** — the local `skills/$NAME/conformance.yaml` is a snapshot from the initial scaffold. If upstream added new mandatory sections (e.g. a new Gate, Task Closure phrase, or workflow), the local manifest doesn't know about them and would falsely report green. Always validate against the freshly cloned upstream contract:
    ```bash
    bash "skills/$NAME/scripts/check-version-conformance.sh" "skills/$NAME" \
      --conformance "$tmp/upstream/templates/skill/conformance.yaml"
    ```
    If this fails: the upstream upgrade is incomplete. Re-apply the missing template sections (e.g. port the Gate/section text from the upstream workflow file into the downstream one), then re-run. After it passes, sync the local manifest with upstream's so the next refresh starts from a fresh snapshot:
    - **Default case** (local matches a historical upstream version — verify with `git -C "$tmp/upstream" log -p -- templates/skill/conformance.yaml`): replace from upstream as a mechanism-owned file, consistent with Hard Rule #4.
    - **If you added project-specific `must_contain` entries to local**: do not replace. Merge new upstream entries into local while keeping your additions, then re-run the conformance check against the merged manifest.
11. **Update the sync pointer** — after a successful refresh with passing validation, record the upstream HEAD you synced from, so the next `upstream-status.sh` is precise:
    ```bash
    printf 'upstream: %s\nsynced_sha: %s\nsynced_date: %s\n' \
      "https://github.com/WoJiSama/skill-based-architecture" \
      "$(git -C "$tmp/upstream" rev-parse HEAD)" "$(date +%F)" > "skills/$NAME/.upstream-sync"
    ```
    (Preserve any leading comment lines if the file already has them.) This is what keeps "am I current?" a one-command check instead of a manual diff.
12. **Final report** — list upstream note entries consulted, upstream changes adopted, local customizations preserved, files intentionally left untouched, validation results (including the conformance check against upstream's manifest), any new mechanism files copied, and any unresolved semantic conflicts.

## Stop Conditions

- Upstream cannot be fetched and the user did not provide a local upstream path.
- A file has both upstream mechanism changes and local semantic rewrites that cannot be reconciled from evidence.
- Validation fails after the merge and the cause is not isolated.

Do not solve stop conditions by overwriting downstream project knowledge.
Do not solve missing upstream notes by creating a downstream `UPSTREAM-CHANGES.md`.
