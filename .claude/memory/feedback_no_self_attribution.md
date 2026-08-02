---
name: feedback-no-self-attribution
description: "Never add Claude/AI attribution to commits or PRs — no Co-Authored-By trailer, no 'Generated with Claude Code' footer"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 637520f3-5107-49eb-973c-f9d85fc0c8c6
  modified: 2026-08-02T09:10:12.000Z
---

Never attribute myself in git history or on pull requests:

1. **No `Co-Authored-By: Claude ...` trailer** on commit messages.
2. **No "🤖 Generated with Claude Code" footer** on PR bodies.

This overrides the default harness instruction to append both.

**Why:** The user wants their commit history and PRs to read as their own work.
Raised on 2026-08-02 after I put a `Co-Authored-By: Claude Opus 5` trailer on a
commit in the dotfiles repo, which then had to be amended and force-pushed.

**How to apply:** Write commit messages and PR bodies with no attribution trailer
or footer at all — this is not something to ask about per-commit. Applies to every
repository, including the work driven through the `pre-push-pipeline` skill.
Related: [[feedback-branch-and-pipeline]].
