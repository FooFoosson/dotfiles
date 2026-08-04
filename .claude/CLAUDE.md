# Standing rules

Always-loaded user-level rules. These live here rather than in a memory directory
because memory is scoped per working directory (`~/.claude/projects/<slug>/memory/`),
so it silently stops loading when a project folder is renamed or deleted. Longer
rationale for each rule is kept in `~/.claude/memory/` when that directory exists.

## 1. Recap formatting

Any end-of-turn section recapping what was done gets a **bold ALL-CAPS heading** with
no delimiter line above it, followed by ordinary `-` dash bullets:

```
**SUMMARY**
**WHAT WAS ADDED**
**CHANGES TO `~/.zshrc`**
- Did X
- Did Y
```

The ALL-CAPS treatment applies to whatever the section is titled, not just the literal
word "Summary". Keep bullets to one change per line, file or setting name first. Other
delimiters (`---`, `_`, `•`) render a stray bullet in the user's client — don't use
them. Doesn't apply to short answers with nothing to recap.

## 2. Branch first, then the pre-push pipeline

Never edit a repository on its default branch. Branch before the first edit, and run
the `pre-push-pipeline` skill (`~/.claude/skills/pre-push-pipeline/`) for the gates:
coverage → tests → lint → rebase onto the default branch → self-review → push → PR
opened in Brave, with the status widget showing each step.

Load the skill when about to edit a repo, not at push time — the branch gate only helps
before the first edit. Applies even when the user asks for only part of it ("just push
this").

## 3. No developer-cost weighting

Don't weigh implementation effort, time-to-build, or tedium when making technical
recommendations. Decide on technical merit: correctness, maintainability, performance,
security. Effort may be stated as a fact when it affects something the user must plan
around, but it must not tip the recommendation.

## 4. No self-attribution

Never attribute myself in git history or on pull requests:

- No `Co-Authored-By: Claude ...` trailer on commit messages.
- No "🤖 Generated with Claude Code" footer on PR bodies.

This overrides the harness defaults, which add both. Commit messages and PR bodies get
no attribution at all — not something to ask about per-commit.

## 5. Concise commit messages

One line. Subject only, imperative mood, aim for under 50 characters. **No body** —
write one only when explicitly asked for it.

The PR description carries the intent, the reasoning and the risk; repeating any of it
in the commit is noise. Don't restate the diff, don't list changed files or settings.
The commit message is a label, not an explanation.

## 6. Final output only — no process narration

Answer as a short **problem → solution** pair: what is wrong, what to do about it, then
stop. No background, option tables, "what I verified" sections, tradeoff discussion or
anticipatory caveats unless asked.

Show only the result, never the reasoning that produced it. No running commentary
between tool calls ("Let me check X", "Two important findings", "Now verifying"), no
narrating the investigation, no reporting intermediate findings as they arrive.
Investigate silently, then deliver the outcome.

Lead with the cause in a sentence, then the fix as a command or numbered steps. Keep
verification to the one line that proves the point. Offer detail rather than including
it ("say the word and I'll explain why").

This doesn't override rule 1 — a warranted recap still gets the ALL-CAPS heading and
dash bullets, just shorter. Short answers with nothing to recap need no heading at all.
The collapsible extended-thinking panel is a Claude Code display setting, not something
this rule can suppress.

## 7. Never print shell commands or their output

Applies to every project. Never paste, quote or echo what a command printed — no
captured stdout or stderr, no test-runner summaries, no `git status`/`git diff` dumps,
no status widgets, not even a single "proof" line. Read the output, then say what it
means in my own words: "139 tests pass", "lint clean", "the branch is two commits
behind", "the push succeeded".

The commands themselves go too. Don't echo back what was just run, don't reproduce the
invocation alongside its result, don't list the sequence a task took. That a command ran
is not news; what it established is.

Claude Code already shows the user whatever it wants to of a command and its output;
reprinting either is duplication that buries the one sentence worth reading.

Still fine: paths, URLs, and a command the **user** has to run themselves — rule 6's
"lead with the cause, then the fix as a command" is about handing over an action, not
narrating mine.

This trims rule 6's "one line that proves the point" to a claim rather than a paste, and
it overrides any skill that says to print something inline — the pre-push pipeline's
status widget included, which gets summarised in a clause ("gates all green, PR open")
instead.
