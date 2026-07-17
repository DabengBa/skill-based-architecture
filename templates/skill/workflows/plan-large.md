# Large Plan Extension

Read this file only after `plan-feature.md` classifies the task as **Large**: multi-subsystem, irreversible/expensive, high uncertainty, or many unknowns that must be resolved before implementation. A Complex plan that does not meet those signals must not load this extension.

## Multi-Perspective Analysis

Analyze the problem from the independent lenses it actually warrants. Each selected lens gets a naturally named sibling file; do not create unused files to satisfy a taxonomy.

| Possible lens | What it decides |
|---|---|
| `architecture.md` | boundaries, components, data flow, ownership |
| `risks.md` | failure modes, blast radius, fail-open/closed, persisted state |
| `alternatives.md` | genuinely different solution shapes and why one wins |
| `contracts.md` | schema/API/wire/business-model impact and migration artifact |
| `integration.md` | downstream consumers and cross-repo/service effects |
| `rollout.md` | sequencing, compatibility, rollback, verification |
| `decomposition.md` | build order and independent dispatch cut-points |

For business-bearing work, at least one selected lens must explicitly compare business-model intent, architecture/contracts, and current code/tests/runtime. Do not turn current implementation into intended business truth by omission.

## Angle Contract

Every angle file:

1. opens with `> Conclusion: <one line>`;
2. answers one independent decision question;
3. names evidence and remaining uncertainty;
4. avoids restating another angle's full conclusion;
5. changes a decision, risk treatment, task boundary, or validation step in `prd.md`.

If an angle would be read only with every sibling and does not change the synthesis independently, merge it into the nearest angle or `prd.md`.

## Synthesis

Keep `prd.md` as the short decision index. Add `## Synthesis` that links every angle, states the chosen path, and identifies conflicts resolved across lenses. An angle absent from Synthesis is not part of the plan; a Synthesis claim with no supporting angle is ungrounded.

Before approval or freeze:

- diff overlapping claims across angles and Synthesis;
- verify every `see <file>` link still supports the sentence citing it;
- make blockers visible in Open Questions;
- ensure accepted target business semantics remain in the Plan until implementation lands;
- convert `decomposition.md` cut-points into Files / Consumes / Produces / Acceptance contracts.

## Parallel Analysis

Independent lenses are suitable for Mode 2 analysis subagents. Give each worker only its lens question and evidence region; do not leak the intended answer. The main agent owns cross-lens decisions and Synthesis. If the lenses are dependent or the main agent needs their raw evidence for user discussion, analyze inline.

## Large-Plan Checklist

- [ ] Selected lenses are justified by risk/uncertainty, not by template completeness
- [ ] Each angle has an independent loading reason and one-line conclusion
- [ ] `prd.md` Synthesis links every angle and resolves contradictions
- [ ] Business-model impact is explicit where macro semantics may change
- [ ] Failure behavior, migrations/contracts, rollout/rollback, and task cut-points are decided when relevant
- [ ] Multi-file semantic drift check passed before plan approval and freeze
