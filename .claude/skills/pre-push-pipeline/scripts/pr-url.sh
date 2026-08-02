#!/usr/bin/env bash
# Print the "open a pull request" web URL for the current branch.
# Used when the `gh` CLI is unavailable: the URL opens the PR form pre-filled
# with the right base and compare branches, so the browser finishes the job.
#
# Usage: pr-url.sh [base-branch]   (base defaults to the remote's default branch)
set -euo pipefail

remote="$(git remote 2>/dev/null | grep -qx origin && echo origin || git remote | head -1)"
[ -n "$remote" ] || { echo "no git remote configured" >&2; exit 1; }

url="$(git remote get-url "$remote")"
# normalise scp-style (git@host:owner/repo.git) and https forms to host/owner/repo
url="${url%.git}"
url="${url#ssh://}"
case "$url" in
    *@*:*) host="${url#*@}"; host="${host%%:*}"; path="${url#*:}" ;;
    https://*|http://*) rest="${url#*://}"; rest="${rest#*@}"; host="${rest%%/*}"; path="${rest#*/}" ;;
    *) echo "unrecognised remote URL: $url" >&2; exit 1 ;;
esac

branch="$(git symbolic-ref --quiet --short HEAD)" || { echo "detached HEAD" >&2; exit 1; }

base="${1:-}"
if [ -z "$base" ]; then
    base="$(git symbolic-ref --quiet --short "refs/remotes/$remote/HEAD" 2>/dev/null || true)"
    base="${base#$remote/}"
    if [ -z "$base" ]; then
        for candidate in main master; do
            if git show-ref --verify --quiet "refs/remotes/$remote/$candidate"; then
                base="$candidate"; break
            fi
        done
    fi
    # nothing fetched yet: fall back to a local main/master
    if [ -z "$base" ]; then
        for candidate in main master; do
            if git show-ref --verify --quiet "refs/heads/$candidate"; then
                base="$candidate"; break
            fi
        done
    fi
fi
[ -n "$base" ] || { echo "could not determine base branch" >&2; exit 1; }

case "$host" in
    *github*)    echo "https://$host/$path/compare/$base...$branch?expand=1" ;;
    *gitlab*)    echo "https://$host/$path/-/merge_requests/new?merge_request%5Bsource_branch%5D=$branch&merge_request%5Btarget_branch%5D=$base" ;;
    *bitbucket*) echo "https://$host/$path/pull-requests/new?source=$branch&dest=$base" ;;
    *)           echo "https://$host/$path/compare/$base...$branch?expand=1" ;;
esac
