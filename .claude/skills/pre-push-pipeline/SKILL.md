---
name: pre-push-pipeline
description: The user's required workflow for changing any git repository - branch before editing, then run a gated pipeline (coverage, tests, lint, rebase onto the default branch, self-review, push, open a PR in Brave, then watch the PR until it is conflict-free) with a live status bar. Use this skill whenever you are about to edit files in a git repo, and whenever the user says commit, push, ship, open a PR, raise a PR, land this, or asks to finish/wrap up a change - even if they only ask for part of it, since the earlier gates protect the push.
---

# Pre-push pipeline

The user's standing rule: **never edit a repo on its default branch, and never push
work that hasn't been through the gates below.** The point isn't ceremony — each gate
catches a class of problem that is cheap to fix now and expensive after it's on the
remote: untested changes, style churn, a merge that silently reverts someone, or a PR
whose reviewer can't tell what it was for.

Run the steps in order. A gate that fails stops the pipeline — report it, fix it, and
resume from that step. Never skip ahead to push "just this once".

## The status widget

Progress shows in a vertical widget in the status line, which Claude Code redraws
after every turn — so it mutates in place above the prompt instead of scrolling away
down the transcript:

```
┌ pre-push pipeline  3/9  ⎇ fix/token-refresh-race
│ ✓ Branch
│ ✓ Coverage
│ ✓ Tests
│ ▶ Lint
│ ○ Rebase
│ ○ Review
│ ○ Push
│ ○ PR
│ ○ Watch PR
└───
```

`○` not run yet · `▶` running now · `✓` passed · `✗` failed · `⊘` not applicable

You drive it by writing state; `statusline.py` does the drawing. State lives in
`.git/pipeline-status.json`, so it stays accurate across a long session, survives
context compaction, and is per-repo:

```bash
S=~/.claude/skills/pre-push-pipeline/scripts/status.py
python3 "$S" init                 # at the start of a change
python3 "$S" set lint run         # entering a step
python3 "$S" set lint ok          # leaving it
python3 "$S" set tests fail "3 failures in test_auth.py"
python3 "$S" set tests skip "no test suite in this repo"
python3 "$S" clear                # after the PR is open - hides the widget
```

`init`, `set` and `clear` print nothing on purpose: the widget is the display, and
echoing it into the transcript after every step is the noise this replaces. When you
do want it inline — a final recap, or answering "where are we?" — use
`python3 "$S" show` (add `--bar` for the one-line form).

Mark a step `run` when you start it and resolve it before moving on; two `▶` at once
means a step was left dangling. Notes on `fail` and `skip` render beside the step,
which is what makes a skipped gate reviewable rather than invisible.

If the widget isn't visible, the status line isn't configured — it needs
`"statusLine": {"type": "command", "command": "python3 \"$HOME/.claude/skills/pre-push-pipeline/scripts/statusline.py\""}`
in `~/.claude/settings.json`. Outside a run it collapses to a single dim context line,
so it only costs vertical space while a pipeline is actually in flight.

## Step 1 — Branch (before the first edit)

Do this *before* touching a file, not before committing. If you're already deep in
edits on the default branch, `git switch -c <branch>` still carries the working tree
over — do it immediately.

**Always fetch before branching.** Cutting from a stale local ref is how you get
conflicts in step 5 that exist only because the branch point was old, and how you end
up building on commits that have already merged.

```bash
git fetch origin
git rev-parse --abbrev-ref HEAD
git switch -c <type>/<short-description> origin/<default>   # e.g. fix/token-refresh-race
```

Branch from `origin/<default>` explicitly rather than from wherever HEAD happens to
sit, unless the work genuinely builds on an unmerged branch. Resolve `<default>` as
step 5 does: `git symbolic-ref refs/remotes/origin/HEAD`, else `origin/main`, else
`origin/master`.

If HEAD is already on a purpose-made branch for this work, that satisfies the step —
but fetch anyway and check the branch against the updated default. If its commits have
since merged, or the default has moved on top of them, cut a fresh branch from
`origin/<default>` instead of stacking onto a stale one. Name the branch after the
change, not the tool.

## Step 2 — Coverage

Only meaningful if the repo has a test suite (look for `tests/`, `*_test.go`,
`*.spec.ts`, `pytest.ini`, `jest.config.*`, a `test` script in `package.json`, etc.).
No suite → `⊘ skip` with a note, and skip step 3 too.

With a suite, every behaviour you changed needs a test that would fail without your
change. Read the existing tests first and match their structure — a test that doesn't
look like its neighbours is friction for the next person. Write the missing ones now;
this is the step where "I'll add tests later" dies.

Ask yourself per changed function: what input would produce the old behaviour? Is
there a test that distinguishes the two? If not, write it.

## Step 3 — Tests

Run the whole suite, not just your new tests — the ones you didn't think about are
exactly where a regression hides. Use the repo's own command (`npm test`,
`pytest`, `go test ./...`, `cargo test`, a Makefile target).

Failures stop the pipeline. If a failure is pre-existing and unrelated, confirm that
by checking out the base branch and reproducing it there, then note it and continue —
don't assume.

## Step 4 — Lint

Run the repo's configured linter and formatter (`npm run lint`, `ruff check`,
`golangci-lint run`, `cargo clippy`, `pre-commit run --all-files`). Fix what your
change introduced. Leave unrelated pre-existing warnings alone — a PR that reformats
files you didn't otherwise touch is much harder to review.

## Step 5 — Rebase onto the default branch

```bash
git fetch origin
git rebase origin/<default>      # default: origin/HEAD, else main, else master
```

Resolve `origin/HEAD` first (`git symbolic-ref refs/remotes/origin/HEAD`); fall back to
`origin/main`, then `origin/master`.

Rebasing before review, not after, is deliberate: you want to review the code that
will actually land, including whatever the merge resolution produced.

When there are conflicts, resolve them by understanding both sides — read the commits
that introduced the conflicting hunk (`git log -L` or `git blame` on the base side) so
you keep the other person's intent rather than clobbering it. Keep a note of every file
you resolved and the reasoning; step 6 requires it. After resolving, re-run tests and
lint if the resolution touched anything non-trivial — a clean rebase can still produce
broken code.

If the rebase is beyond you (deep conflicts in code you don't understand), stop, abort
with `git rebase --abort`, and hand it to the user with a clear description. That's a
legitimate outcome, not a failure to hide.

## Step 6 — Review

Write a review of the exact diff that is about to be pushed
(`git diff origin/<default>...HEAD`). Read it as if someone else wrote it and you're
the reviewer who has to approve it. Structure:

```
**INTENT** — what problem this solves and why this approach
**CHANGES** — the substantive changes, grouped by concern (not a file-by-file recital)
**CONFLICTS** — each conflict resolved, which side won, and why (omit if none)
**RISK** — functionality that could break, edge cases, anything a reviewer should
           look at hardest; say "none identified" only if you actually looked
```

Be concrete about risk: name the callers you checked, the migration that has to run
first, the config that must exist in prod. If the review surfaces a real problem, that's
the pipeline working — go fix it and re-run the affected gates.

Show the review to the user before pushing. It doubles as the PR body, so writing it
well here saves the work later.

## Step 7 — Push

```bash
git push -u origin HEAD
```

If the branch was already pushed and rebased since, `git push --force-with-lease`
(never bare `--force`: `--force-with-lease` refuses when someone else has pushed to
your branch, which is exactly the accident worth preventing).

## Step 8 — PR, opened in Brave

With the `gh` CLI:

```bash
gh pr create --title "<title>" --body "<the step 6 review>" --base <default>
brave "$(gh pr view --json url -q .url)" &
```

**Create the PR yourself — never hand the user a compare form to fill in.** `gh` is
installed at `~/.local/bin/gh` (on PATH). The user's remote uses an `~/.ssh/config`
host alias, so pass `--repo` explicitly if `gh` cannot infer it.

Only if `gh` is genuinely unavailable or unauthenticated (`gh auth status`), fall back
to the pre-filled form and paste the review into it:

```bash
brave "$(~/.claude/skills/pre-push-pipeline/scripts/pr-url.sh)" &
```

`pr-url.sh` builds the compare URL from the remote and current branch, and handles
GitHub, GitLab and Bitbucket. Brave is at `/snap/bin/brave` here; `brave` on PATH
resolves to it. Background the call (`&`) so a browser that stays in the foreground
doesn't block the session.

## Step 9 — Babysit the PR until it's mergeable

The rebase in step 5 only proves the branch was current *then*. The default branch can
move while you review, push, or open the PR — someone else merges, or an earlier PR of
your own lands — and the PR goes conflicted after you thought you were done. A PR left
sitting in that state is worse than no PR: it looks ready and isn't.

So don't treat step 8 as the finish line. Check mergeability once the PR exists, and
again after anything that could have moved the base:

```bash
gh pr view <n> --json mergeable,mergeStateStatus -q '.mergeable + " " + .mergeStateStatus'
```

`MERGEABLE CLEAN` means done. `CONFLICTING DIRTY` means go back — and *back* means step
5, not a quick fix on top:

1. `git fetch origin` and rebase onto the updated default branch.
2. Resolve conflicts the same way step 5 demands — read both sides, keep the other
   person's intent, note what you resolved and why.
3. Re-run tests and lint if the resolution touched anything non-trivial. A conflict
   resolved wrong compiles fine.
4. **Re-do the review.** The diff that will land is not the diff you reviewed; at
   minimum re-read `git diff origin/<default>...HEAD` and update the PR body's
   CONFLICTS and RISK sections to cover the new resolution.
5. `git push --force-with-lease`, then check mergeability again.

Repeat until it comes back clean. Mark the step `fail` with a note while it's
conflicted so the widget shows the PR is not actually ready.

`UNKNOWN` means GitHub hasn't finished computing the merge state — wait a moment and
re-check rather than reporting it as clean. If the conflict is beyond you, say so
plainly and hand it over with the conflicting paths named; leaving it silently broken is
the one unacceptable outcome.

Finish by printing the completed widget inline (`python3 "$S" show`) alongside the PR
URL, then `python3 "$S" clear` so the status line returns to its idle one-liner. The
inline copy is the permanent record of how the run went; the widget is transient.

## When the user asks for only part of this

"Just push it" still means the gates run — that's the point of a standing rule; the
user is trusting the pipeline rather than re-specifying it each time. If they
explicitly want a gate skipped ("don't run the tests, I know they're broken"), that's
their call: mark it `⊘` with their reason as the note so the skipped gate is visible
in the bar and in the PR discussion.

For a change so small there's genuinely nothing to test — a typo in a comment, a README
line — say so and mark coverage and tests `⊘`. Judgement is allowed; silence is not.
