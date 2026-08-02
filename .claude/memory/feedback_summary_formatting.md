---
name: feedback-summary-formatting
description: "Any end-of-turn section recapping what was done needs a bold ALL-CAPS heading (whatever its wording) plus a dash bullet list"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 063f25f8-f2a7-4133-8c25-a9912af3cf2a
  modified: 2026-08-02T06:41:35.573Z
---

Always make the end-of-turn "what changed" section visually distinct from the rest of the response:

1. A bold ALL-CAPS heading — no delimiter line above it.
2. A standard dash bullet list of the concrete changes below it.

The ALL-CAPS treatment applies to *whatever the section is titled*, not just the word "Summary". Whatever wording fits the turn, upper-case the whole heading:

```
**SUMMARY**
**WHAT WAS ADDED**
**WHAT WAS CHANGED**
**CHANGES TO `~/.zshrc`**
- Did X
- Did Y
```

**Why:** User iterated through several variants in one session — underscore delimiter, `---` delimiter, `•` bullet marker, plain unmarked lines — and each still rendered with an unwanted large bullet/circle in their client. Reverted to the simplest, standard-markdown form (bold ALL-CAPS heading + ordinary `-` bullets). They later clarified the capitalization is about the final recap section as a category, not about the literal title "Summary" — headings like "Changes to X" were still being written in sentence case.

**How to apply:** Applies to any response ending with a recap of what was done (config edits, file changes, installs, etc.), regardless of how the heading is worded. Keep bullets short — one change per line, file/setting name first. Doesn't apply to short one-line answers where there's nothing to recap.
