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
