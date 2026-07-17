# Receiving Code Review Workflow

Use this when acting on user, reviewer, PR/MR, or agent review feedback. Evaluating a critique and deciding to accept or push back is main-agent judgment; only an admitted mechanical recheck may use [`subagent-auxiliary.md`](subagent-auxiliary.md).

## Process

1. Read the whole review before acting on any item.
2. Restate each technical claim; clarify genuinely ambiguous feedback before editing.
3. Verify every claim against current code, behavior, and constraints. Reviewers can be wrong or stale.
4. Check whether the suggested change is warranted: inspect real usage and reject speculative “proper” implementations.
5. For accepted items, implement the smallest correction. For rejected items, state concrete evidence without defensiveness or performative agreement.
6. Re-run fresh targeted evidence, then [Task Closure](task-closure.md) if behavior changed.

Push back when feedback breaks a real case, misses a binding constraint, has no actual usage, or conflicts with an explicit user decision. Surface conflicts rather than silently overriding either side.

## Completion Check

- Whole review was read first.
- Every accepted/rejected item has code or runtime evidence.
- No praise/apology substituted for verification.
- Accepted changes were re-verified; rejected changes have concise evidence.
