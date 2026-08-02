#!/usr/bin/env python3
"""Claude Code status line: the live pre-push pipeline widget.

Claude Code re-runs this after each turn and replaces the previous render, so
this is the one surface where the widget actually mutates in place instead of
being reprinted down the transcript.

The widget only appears while a pipeline run is active. Outside a run it falls
back to a one-line context readout, so it costs a single line when idle.

Wire it up in ~/.claude/settings.json:

    "statusLine": {"type": "command", "command": "python3 ~/.claude/skills/pre-push-pipeline/scripts/statusline.py"}
"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from status import KEYS, LABELS, MARKS, COLORS  # noqa: E402

DIM = "\033[2m"
RESET = "\033[0m"


def git(cwd, *args):
    try:
        out = subprocess.run(
            ["git", "-C", cwd, *args],
            capture_output=True, text=True, timeout=2,
        )
        return out.stdout.strip() if out.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def main():
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        payload = {}

    cwd = (payload.get("workspace", {}).get("current_dir")
           or payload.get("cwd") or os.getcwd())
    model = payload.get("model", {}).get("display_name", "")

    git_dir = git(cwd, "rev-parse", "--absolute-git-dir")
    head = git(cwd, "symbolic-ref", "--quiet", "--short", "HEAD")
    state = {}
    if git_dir:
        try:
            with open(os.path.join(git_dir, "pipeline-status.json")) as f:
                state = json.load(f)
        except (OSError, ValueError):
            state = {}

    steps = state.get("steps") or {}
    notes = state.get("notes") or {}
    active = any(v != "pending" for v in steps.values())

    if not active:
        # idle: one dim line of context, no widget
        bits = [b for b in (model, os.path.basename(cwd), head and "⎇ " + head) if b]
        print(DIM + "  ·  ".join(bits) + RESET)
        return

    done = sum(1 for k in KEYS if steps.get(k) in ("ok", "skip"))
    header = "┌ pre-push pipeline  %d/%d" % (done, len(KEYS))
    if head:
        header += "  ⎇ %s" % head
    out = [DIM + header + RESET]
    for k in KEYS:
        st = steps.get(k, "pending")
        row = "%s %-8s" % (MARKS.get(st, "○"), LABELS[k])
        note = notes.get(k)
        if note and st in ("fail", "skip"):
            row += "  %s" % note
        out.append(DIM + "│ " + RESET + COLORS.get(st, "") + row.rstrip() + RESET)
    out.append(DIM + "└───" + RESET)
    print("\n".join(out))


if __name__ == "__main__":
    main()
