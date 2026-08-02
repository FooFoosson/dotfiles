#!/usr/bin/env python3
"""Track pre-push pipeline state and render it as a vertical widget.

State lives in the repo's .git directory, so it never shows up in a diff and
each repo tracks its own run. `init`, `set` and `clear` are silent - the live
widget is drawn by statusline.py, which re-reads this state on every refresh.

    status.py init                          # all steps pending
    status.py set tests ok                  # mark one step (prints nothing)
    status.py set lint fail "eslint: 3 errors in src/api.ts"
    status.py set tests skip "no test suite in repo"
    status.py set rebase run                # currently executing
    status.py show                          # print the widget on demand
    status.py show --bar                    # single-line form instead
    status.py clear                         # end the run, hide the widget

States: pending (o) | run (>) | ok (v) | fail (x) | skip (-)
"""
import json
import os
import subprocess
import sys

STEPS = [
    ("branch", "Branch"),
    ("coverage", "Coverage"),
    ("tests", "Tests"),
    ("lint", "Lint"),
    ("rebase", "Rebase"),
    ("review", "Review"),
    ("push", "Push"),
    ("pr", "PR"),
]
MARKS = {"pending": "○", "run": "▶", "ok": "✓", "fail": "✗", "skip": "⊘"}
KEYS = [k for k, _ in STEPS]
LABELS = dict(STEPS)


def state_path():
    try:
        git_dir = subprocess.run(
            ["git", "rev-parse", "--absolute-git-dir"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        git_dir = os.getcwd()
    return os.path.join(git_dir, "pipeline-status.json")


def load():
    try:
        with open(state_path()) as f:
            data = json.load(f)
    except (OSError, ValueError):
        data = {}
    return {
        "steps": {k: data.get("steps", {}).get(k, "pending") for k in KEYS},
        "notes": data.get("notes", {}),
    }


def save(data):
    with open(state_path(), "w") as f:
        json.dump(data, f, indent=2)


def branch():
    try:
        return subprocess.run(
            ["git", "symbolic-ref", "--quiet", "--short", "HEAD"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def render(data, color=False):
    """Vertical widget - one step per line, notes inline beside the step."""
    head = branch()
    lines = ["┌ pre-push pipeline" + (" · %s" % head if head else "")]
    for k in KEYS:
        state = data["steps"][k]
        note = data["notes"].get(k)
        row = "%s %-8s" % (MARKS.get(state, "○"), LABELS[k])
        if note and state in ("fail", "skip"):
            row += "  %s" % note
        lines.append("│ " + tint(row, state) if color else "│ " + row.rstrip())
    lines.append("└" + "─" * 3)
    return "\n".join(lines)


COLORS = {"pending": "\033[2m", "run": "\033[33m", "ok": "\033[32m",
          "fail": "\033[31m", "skip": "\033[2;35m"}


def tint(text, state):
    return "%s%s\033[0m" % (COLORS.get(state, ""), text.rstrip())


def render_bar(data):
    """Single-line form, for when vertical space is precious."""
    return "  ".join(
        "%s %s" % (MARKS.get(data["steps"][k], "○"), LABELS[k]) for k in KEYS
    )


def main():
    argv = [a for a in sys.argv[1:] if a not in ("--bar", "--color")]
    bar_form = "--bar" in sys.argv
    color = "--color" in sys.argv
    cmd = argv[0] if argv else "show"

    if cmd == "init":
        data = {"steps": {k: "pending" for k in KEYS}, "notes": {}}
        save(data)
    elif cmd == "set":
        if len(argv) < 3:
            sys.exit("usage: status.py set <step> <pending|run|ok|fail|skip> [note]")
        data = load()
        step, state = argv[1], argv[2]
        if step not in KEYS:
            sys.exit("unknown step %r; expected one of: %s" % (step, ", ".join(KEYS)))
        if state not in MARKS:
            sys.exit("unknown state %r; expected one of: %s" % (state, ", ".join(MARKS)))
        data["steps"][step] = state
        if len(argv) > 3:
            data["notes"][step] = " ".join(argv[3:])
        elif state in ("ok", "run", "pending"):
            data["notes"].pop(step, None)
        save(data)
    elif cmd == "clear":
        try:
            os.remove(state_path())
        except OSError:
            pass
    elif cmd == "show":
        data = load()
        print(render_bar(data) if bar_form else render(data, color))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
