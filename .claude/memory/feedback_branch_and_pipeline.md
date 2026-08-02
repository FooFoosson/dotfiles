---
name: feedback-branch-and-pipeline
description: "Never edit a repo on its default branch; branch first, and run the pre-push-pipeline skill before any push"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 36298959-c14f-4f30-8288-f000ca8ca7fa
  modified: 2026-08-02T07:06:25.486Z
---

Standing rule for every git repository:

1. **Branch before the first edit** — never make changes on `main`/`master`.
2. **Before pushing, run the `pre-push-pipeline` skill** — coverage → tests → lint →
   rebase onto the default branch → self-review → push → PR opened in Brave, with a
   status bar showing each step's state.

**Why:** The user wants these gates applied automatically rather than re-requesting
them each time. The full procedure lives in the `pre-push-pipeline` skill (at
`~/.claude/skills/pre-push-pipeline/`) because it's a long multi-step workflow with
bundled scripts — too big for memory, and only needed once work actually starts. This
memory exists purely as the always-loaded trigger that points at it.

**How to apply:** Load the skill at the moment you're about to edit a repo, not at
push time — step 1 (branch) has to happen before the first edit to be useful. Applies
even when the user asks only for part of it ("just push this"). Related:
[[feedback-summary-formatting]].
