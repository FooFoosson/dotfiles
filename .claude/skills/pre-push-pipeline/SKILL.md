---
name: pre-push-pipeline
description: The user's required workflow for changing any git repository - create a git worktree beside the repo and edit there, then run a gated pipeline (coverage, tests, lint, rebase onto the default branch, self-review, push, open a PR in Brave, watch the PR until it is conflict-free, remove the worktree) with a live status bar. Use this skill whenever you are about to edit files in a git repo, and whenever the user says commit, push, ship, open a PR, raise a PR, land this, or asks to finish/wrap up a change - even if they only ask for part of it, since the earlier gates protect the push.
---

# Pre-push pipeline

The user's standing rule: **never edit the repo's own checkout, and never push work that
hasn't been through the gates below.** Every change happens in a throwaway git worktree
beside the repo, on its own branch, and the worktree is removed once the PR is open.

The worktree is what makes several Claude instances safe on one project at the same
time: each has its own directory, index, HEAD and pipeline state, so nobody's `switch`,
rebase or half-finished edit lands in someone else's working tree. The gates are what
make the push safe: each catches a class of problem that is cheap to fix now and
expensive after it's on the remote — untested changes, style churn, a merge that
silently reverts someone, a PR whose reviewer can't tell what it was for.

Run the steps in order. A gate that fails stops the pipeline — report it, fix it, and
resume from that step. Never skip ahead to push "just this once".

## Resolving `<default>`

Several steps need the remote's default branch. Resolve it once, the same way every
time: `git symbolic-ref --quiet --short refs/remotes/origin/HEAD` (prints
`origin/main`), else `origin/main`, else `origin/master`. A repo with no remote falls
back to the local `main`/`master`.

## The status widget

Progress shows in a vertical widget in the status line, which Claude Code redraws
after every turn — so it mutates in place above the prompt instead of scrolling away
down the transcript:

```
┌ pre-push pipeline  4/10  ⎇ fix/token-refresh-race  ·  calendar_1
│ ✓ Worktree
│ ✓ Coverage
│ ✓ Tests
│ ▶ Lint
│ ○ Rebase
│ ○ Review
│ ○ Push
│ ○ PR
│ ○ Watch PR
│ ○ Cleanup
└───
```

`○` not run yet · `▶` running now · `✓` passed · `✗` failed · `⊘` not applicable

You drive it by writing state; `statusline.py` does the drawing. State lives in the
git directory of whichever worktree you are in — `.git/worktrees/<name>/pipeline-status.json`
— so it stays accurate across a long session, survives context compaction, and is
private to your run. Two instances working the same repo each see their own widget:

```bash
S=~/.claude/skills/pre-push-pipeline/scripts/status.py
python3 "$S" init                 # at the start of a change
python3 "$S" set lint run         # entering a step
python3 "$S" set lint ok          # leaving it
python3 "$S" set tests fail "3 failures in test_auth.py"
python3 "$S" set tests skip "no test suite in this repo"
```

`init` and `set` print nothing on purpose: the widget is the display, and echoing it
into the transcript after every step is the noise this replaces. `python3 "$S" show`
(add `--bar` for the one-line form) renders it for you to *read* — the user's standing
rule 7 forbids pasting command output into a reply, so report the run in a clause
("gates all green", "tests skipped: no suite") rather than reproducing the widget.
`python3 "$S" clear` deletes the state and hides the widget; you only need it for a run
you abandon without cleaning up, since step 10 takes the state file with the worktree.

Both scripts read the state from the *current directory's* git dir, so run them from
inside the worktree — which is where the session sits from step 1 onwards.

Mark a step `run` when you start it and resolve it before moving on; two `▶` at once
means a step was left dangling. Notes on `fail` and `skip` render beside the step,
which is what makes a skipped gate reviewable rather than invisible.

If the widget isn't visible, the status line isn't configured — it needs
`"statusLine": {"type": "command", "command": "python3 \"$HOME/.claude/skills/pre-push-pipeline/scripts/statusline.py\""}`
in `~/.claude/settings.json`. Outside a run it collapses to a single dim context line,
so it only costs vertical space while a pipeline is actually in flight.

## Step 1 — Worktree (before the first edit)

Do this *before* touching a file. The worktree goes in the repo's **parent folder**,
named `<repo>_<n>` with the lowest free `n`, and is branched from `origin/<default>`:

```bash
main=$(git rev-parse --show-toplevel)
git -C "$main" fetch origin
repo=$(basename "$main"); parent=$(dirname "$main"); n=1
while [ -e "$parent/${repo}_$n" ]; do n=$((n+1)); done
wt="$parent/${repo}_$n"
git -C "$main" worktree add "$wt" -b <type>/<short-description> origin/<default>
```

Then move the session into it with the **EnterWorktree** tool, passing `path="$wt"`
(not `name` — that would create a second worktree under `.claude/worktrees/`). From
there on, cwd is the worktree: edits, tests, git and `status.py` all act on your copy,
and the widget follows automatically.

EnterWorktree only accepts a sibling path on first entry from the directory the session
launched in; if the session already sits in some other linked worktree it will refuse.
Then work the new one by absolute path — `git -C "$wt"`, `cd "$wt"` before `status.py`
— and expect the status line to keep drawing the launch worktree's run, since it reads
the session's directory rather than the shell's. Use `python3 "$S" show` inline for the
real state.

Fetching first is not optional: cutting from a stale local ref is how you get conflicts
in step 5 that exist only because the branch point was old, and how you end up building
on commits that have already merged. Branch from `origin/<default>` explicitly unless
the work genuinely builds on an unmerged branch. Name the branch after the change, not
the tool — `fix/token-refresh-race`, not `claude/patch-3`.

If `git worktree add` fails because another instance took the same directory between
your check and your command, bump `n` and retry. If the session is *already* in a
`<repo>_<n>` worktree cut for this change, the step is satisfied — fetch anyway and
check the branch against the updated default; if its commits have merged, or the
default has moved on top of them, cut a fresh worktree rather than stacking onto a
stale one.

**Never `switch`, `checkout`, `stash` or edit in the main checkout.** Another instance
may be reading it, and it is the one directory everyone shares. If you find changes
already sitting there — yours from before this rule, or the user's — create the
worktree, then move them across (`refs/stash` is shared between worktrees, so this is
the clean way):

```bash
git -C "$main" stash push -u -m "move to $wt"
git -C "$wt" stash pop
```

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

A fresh worktree has no `node_modules`, `.venv` or build cache: install dependencies
inside it (`npm ci`, `uv sync`, …) rather than pointing at the main checkout's. Ignored
files aren't copied by `git worktree add`, so a local `.env` or similar may need
copying too — check before concluding the suite is broken.

Failures stop the pipeline. If a failure is pre-existing and unrelated, confirm that by
reproducing it on the base branch — `git stash` in your worktree, or a scratch checkout
of `origin/<default>` — then note it and continue; don't assume.

## Step 4 — Lint

Run the repo's configured linter and formatter (`npm run lint`, `ruff check`,
`golangci-lint run`, `cargo clippy`, `pre-commit run --all-files`). Fix what your
change introduced. Leave unrelated pre-existing warnings alone — a PR that reformats
files you didn't otherwise touch is much harder to review.

## Step 5 — Rebase onto the default branch

```bash
git fetch origin
git rebase origin/<default>
```

Run this from the worktree; it rewrites your branch only, and no other instance's
checkout can be sitting on it (git refuses to check the same branch out twice).

Rebasing before review, not after, is deliberate: you want to review the code that
will actually land, including whatever the merge resolution produced.

When there are conflicts, resolve them by understanding both sides — read the commits
that introduced the conflicting hunk (`git log -L` or `git blame` on the base side) so
you keep the other person's intent rather than clobbering it. Keep a note of every file
you resolved and the reasoning; step 6 requires it. After resolving, re-run tests and
lint if the resolution touched anything non-trivial — a clean rebase can still produce
broken code.

If the rebase is beyond you (deep conflicts in code you don't understand), stop, abort
with `git rebase --abort`, and hand it to the user with a clear description **and the
worktree path** — leave the worktree in place so they can pick it up. That's a
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
move while you review, push, or open the PR — someone else merges, or the instance in
the worktree next door lands its own PR — and yours goes conflicted after you thought
you were done. A PR left sitting in that state is worse than no PR: it looks ready and
isn't.

So don't treat step 8 as the finish line. Check mergeability once the PR exists, and
again after anything that could have moved the base:

```bash
gh pr view <n> --json mergeable,mergeStateStatus -q '.mergeable + " " + .mergeStateStatus'
```

`MERGEABLE CLEAN` means done. `CONFLICTING DIRTY` means go back to step 5 in the
worktree you still have — fetch, rebase, resolve by reading both sides, re-run tests
and lint if the resolution was non-trivial, then **re-do the review**: the diff that
will land is not the diff you reviewed, so re-read `git diff origin/<default>...HEAD`
and update the PR body's CONFLICTS and RISK sections. Then `git push --force-with-lease`
and re-check.

Repeat until it comes back clean. Mark the step `fail` with a note while it's
conflicted so the widget shows the PR is not actually ready.

`UNKNOWN` means GitHub hasn't finished computing the merge state — wait a moment and
re-check rather than reporting it as clean. If the conflict is beyond you, say so
plainly and hand it over with the conflicting paths named; leaving it silently broken is
the one unacceptable outcome.

## Step 10 — Remove the worktree

Only once the PR is open and clean — the babysitting loop needs the worktree, which is
why this is last.

Mark the step and read the widget *before* removing anything: the state file lives
inside the worktree and disappears with it, so this is the last chance to see how the
run went and summarise it alongside the PR URL.

```bash
python3 "$S" set cleanup ok
python3 "$S" show            # for you to read, not to paste (rule 7)
```

Then return the session with the **ExitWorktree** tool, `action: "keep"` — it refuses to
delete a worktree it didn't create, and `keep` is what moves cwd back to the main
checkout. Remove the worktree from there:

```bash
git -C "$main" worktree remove "$wt"
```

`worktree remove` refuses while anything is uncommitted or untracked. That refusal is a
guard, not an obstacle: look at what's left and decide deliberately — commit it and
amend the PR, or discard it — rather than reaching for `--force`.

The local branch stays behind on purpose; it's the PR's branch, and the remote already
has it. Delete it with `git -C "$main" branch -d <branch>` once the PR merges.

Leaving the worktree in place is a legitimate outcome when the work isn't finished —
handed-off conflicts, PR feedback you expect to act on. Say so, mark cleanup `⊘` with
the reason and the path, and leave the state file alone so the next session resumes
with the widget intact.

## When the user asks for only part of this

"Just push it" still means the gates run — that's the point of a standing rule; the
user is trusting the pipeline rather than re-specifying it each time. If they
explicitly want a gate skipped ("don't run the tests, I know they're broken"), that's
their call: mark it `⊘` with their reason as the note so the skipped gate is visible
in the bar and in the PR discussion.

For a change so small there's genuinely nothing to test — a typo in a comment, a README
line — say so and mark coverage and tests `⊘`. Judgement is allowed; silence is not.
The worktree is not one of the skippable gates: it costs a second, and it's what keeps
concurrent instances out of each other's way.
