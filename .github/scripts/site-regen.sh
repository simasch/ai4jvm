#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read SPEC.md and index.html from the PR head using git show.
# The working directory remains the trusted base branch throughout — we never
# check out PR code.
SPEC=$(git show "$HEAD_SHA:SPEC.md")
CURRENT_HTML=$(git show "$HEAD_SHA:index.html")

# Build prompts for the LLM
export SYSTEM_PROMPT="You are a web developer maintaining the AI4JVM website (a single-page HTML + inline CSS site, no build step). Your task is to update index.html so it exactly matches the provided SPEC.md. Preserve existing structure, styles, and inline CSS unless the spec requires changes. IMPORTANT: Do NOT delete or modify any HTML comments in the file — preserve all comments exactly as they are. You may use the fetch_webpage tool to look up any URLs mentioned in SPEC.md if you need more context. Return ONLY the complete updated index.html file — no explanation, no markdown code fences."
export USER_PROMPT="Current index.html:

$CURRENT_HTML

Update the above to match this SPEC.md:

$SPEC

Return ONLY the complete updated index.html."
export MAX_TOKENS=32000

# Call GitHub Models with tool-calling support (fetch_webpage tool)
LLM_STDERR=$(mktemp)
if ! NEW_HTML=$(python3 "$SCRIPT_DIR/llm_with_tools.py" 2>"$LLM_STDERR"); then
  ERR=$(cat "$LLM_STDERR")
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "$(printf '❌ Site regeneration failed:\n\n```\n%s\n```' "$ERR")"
  exit 1
fi

if [ -z "$NEW_HTML" ]; then
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "❌ Site regeneration failed: no content returned from the model."
  exit 1
fi

# Strip markdown code fences if the model wrapped the output in them
NEW_HTML=$(echo "$NEW_HTML" | sed '/^```.*$/d')

# Store the regenerated content as a git blob object
NEW_BLOB=$(printf '%s\n' "$NEW_HTML" | git hash-object -w --stdin)

# Check whether index.html actually changed
OLD_BLOB=$(git ls-tree "$HEAD_SHA" -- index.html | awk '{print $3}')

if [ "$OLD_BLOB" = "$NEW_BLOB" ]; then
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "ℹ️ No changes to \`index.html\` — the site is already up to date with \`SPEC.md\`."
  exit 0
fi

# Build a new commit directly on top of the PR head without checking out the
# PR branch, using git plumbing commands.
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

NEW_TREE=$(git ls-tree "$HEAD_SHA" | \
  awk -v blob="$NEW_BLOB" '/\tindex\.html$/{printf "100644 blob %s\tindex.html\n", blob; next} {print}' | \
  git mktree)
NEW_COMMIT=$(git commit-tree "$NEW_TREE" -p "$HEAD_SHA" -m "regen: update index.html from SPEC.md")

if [ "${IS_FORK:-false}" = "true" ]; then
  # Fork PR — try different strategies to deliver the regen commit
  REGEN_BRANCH="regen/pr-$PR_NUMBER"
  BASE_OWNER="${REPO%%/*}"

  if [ -n "${MAINTAINER_PAT:-}" ] && [ "${MAINTAINER_CAN_MODIFY:-false}" = "true" ]; then
    # Strategy 1: Push directly to the fork branch using the PAT
    FORK_URL="https://x-access-token:${MAINTAINER_PAT}@github.com/${HEAD_REPO}.git"
    if git push "$FORK_URL" "$NEW_COMMIT:refs/heads/$HEAD_REF" 2>/dev/null; then
      gh pr comment "$PR_NUMBER" --repo "$REPO" \
        --body "✅ Site regenerated and pushed to this PR branch."
      exit 0
    fi
  fi

  # Push the regen commit to a branch in the base repo for all fork fallbacks
  git push origin "$NEW_COMMIT:refs/heads/$REGEN_BRANCH" --force

  if [ -n "${MAINTAINER_PAT:-}" ]; then
    # Strategy 2: Open a PR on the contributor's fork
    GH_TOKEN="$MAINTAINER_PAT" gh api "repos/${HEAD_REPO}/pulls" \
      -f title="regen: update index.html from SPEC.md" \
      -f head="${BASE_OWNER}:${REGEN_BRANCH}" \
      -f base="$HEAD_REF" \
      -f body="Automated site regeneration from [PR #${PR_NUMBER}](https://github.com/${REPO}/pull/${PR_NUMBER}). Merge this to update your PR branch." \
      2>/dev/null \
    && {
      gh pr comment "$PR_NUMBER" --repo "$REPO" \
        --body "✅ Site regenerated! I've opened a PR on your fork with the updated \`index.html\` — merge it to update this PR."
      exit 0
    }
  fi

  # Strategy 3: Fallback — new PR to main in the base repo
  PR_URL=$(gh pr create --repo "$REPO" \
    --head "$REGEN_BRANCH" \
    --base main \
    --title "regen: update index.html for PR #$PR_NUMBER" \
    --body "Automated site regeneration for #${PR_NUMBER}. This PR includes the SPEC.md changes and the regenerated \`index.html\`." \
    2>/dev/null) \
  && {
    gh pr comment "$PR_NUMBER" --repo "$REPO" \
      --body "✅ Site regenerated! Since I couldn't push to your fork, I've opened ${PR_URL} with the updated \`index.html\`."
    exit 0
  }

  # Last resort: just link to the branch
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "✅ Site regenerated on [\`$REGEN_BRANCH\`](https://github.com/$REPO/tree/$REGEN_BRANCH). A maintainer can merge this after your PR lands."
else
  git push origin "$NEW_COMMIT:refs/heads/$HEAD_REF"

  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "✅ Site regenerated and pushed to this PR branch."
fi
