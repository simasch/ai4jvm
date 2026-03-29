#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

BASE_HEAD=$(git rev-parse HEAD)

# Get the SPEC.md diff — this is what the PR changed
SPEC_DIFF=$(git diff "HEAD...$HEAD_SHA" -- SPEC.md)

if [ -z "$SPEC_DIFF" ]; then
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "ℹ️ No changes to \`SPEC.md\` found in this PR — nothing to regenerate."
  exit 0
fi

# Merge the base branch into the PR head so the regen commit is up-to-date
# and won't cause merge conflicts when the PR is merged.
if MERGED_TREE=$(git merge-tree --write-tree HEAD "$HEAD_SHA" 2>/dev/null); then
  # Clean merge — use the merged tree
  MERGE_COMMIT=$(git commit-tree "$MERGED_TREE" -p "$HEAD_SHA" -p "$BASE_HEAD" \
    -m "Merge $BASE_REF into PR branch")
  CURRENT_HTML=$(git show "$MERGE_COMMIT:index.html")
  REGEN_PARENT="$MERGE_COMMIT"
  REGEN_BASE_TREE="$MERGE_COMMIT"
else
  # Merge conflicts (likely in index.html which we're regenerating anyway).
  CURRENT_HTML=$(git show "$BASE_HEAD:index.html")
  REGEN_PARENT="MERGE"
  REGEN_BASE_TREE="$BASE_HEAD"
fi

# Build prompts — focused on just the PR's SPEC.md changes
SYSTEM_PROMPT="You are a web developer maintaining the AI4JVM website (a single-page HTML + inline CSS site, no build step).

You will receive the current index.html and a SPEC.md diff showing what changed in this PR. Your task is to apply ONLY the changes from the diff to the HTML. Do not modify anything else.

For each change in the diff:
- Added items: create the corresponding HTML (cards, people, links, etc.) matching the existing style and structure. Insert in the correct position.
- Removed items: delete the corresponding HTML block.
- Modified items: update the corresponding HTML to match.

IMPORTANT:
- Do NOT delete or modify any HTML comments — preserve them exactly.
- Do NOT change any existing content that is not affected by the diff.
- Use the WebFetch tool to verify URLs for NEW items only. If a link is broken, add <!-- LINK CHECK: 404 --> next to it.
- Return ONLY the complete updated index.html starting with <!DOCTYPE html>. No explanation, no markdown fences, no commentary."

SYSTEM_FILE=$(mktemp)
printf '%s' "$SYSTEM_PROMPT" > "$SYSTEM_FILE"

USER_FILE=$(mktemp)
cat > "$USER_FILE" <<USEREOF
Current index.html:

$CURRENT_HTML

SPEC.md diff from this PR:

\`\`\`diff
$SPEC_DIFF
\`\`\`

Apply ONLY the above changes to index.html. Return the complete updated file.
USEREOF

# Verify Claude CLI is available
DEBUG_INFO=$(mktemp)
{
  echo "Claude CLI:"
  claude --version 2>&1 || echo "claude CLI not found in PATH"
  echo "ANTHROPIC_API_KEY set: $([ -n "${ANTHROPIC_API_KEY:-}" ] && echo yes || echo no)"
  echo "User prompt size: $(wc -c < "$USER_FILE") bytes"
  echo "System prompt size: $(wc -c < "$SYSTEM_FILE") bytes"
} > "$DEBUG_INFO" 2>&1

# Call Claude Code CLI with web tools
LLM_STDERR=$(mktemp)
LLM_OUTPUT=$(mktemp)
if ! claude -p "$(cat "$USER_FILE")" \
  --system-prompt-file "$SYSTEM_FILE" \
  --allowedTools "WebFetch,WebSearch" \
  --model claude-opus-4-6 \
  --max-turns 30 \
  --output-format text \
  --verbose \
  --bare \
  >"$LLM_OUTPUT" 2>"$LLM_STDERR"; then
  ERR=$(tail -c 3000 "$LLM_STDERR")
  OUTPUT=$(head -c 1000 "$LLM_OUTPUT")
  DBG=$(cat "$DEBUG_INFO")
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "$(printf '❌ Site regeneration failed (non-zero exit):\n\nDebug:\n```\n%s\n```\n\nStderr (last 3000 chars):\n```\n%s\n```\n\nStdout (first 1000 chars):\n```\n%s\n```' "$DBG" "$ERR" "$OUTPUT")"
  exit 1
fi

NEW_HTML=$(cat "$LLM_OUTPUT")
RAW_SIZE=${#NEW_HTML}

if [ -z "$NEW_HTML" ]; then
  ERR=$(tail -c 3000 "$LLM_STDERR")
  DBG=$(cat "$DEBUG_INFO")
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "$(printf '❌ Site regeneration failed: empty stdout (exit 0).\n\nDebug:\n```\n%s\n```\n\nStderr (last 3000 chars):\n```\n%s\n```' "$DBG" "$ERR")"
  exit 1
fi

# Save raw output for error reporting
RAW_PREVIEW=$(echo "$NEW_HTML" | head -c 1000)

# Strip markdown code fences if the model wrapped the output in them
NEW_HTML=$(echo "$NEW_HTML" | sed '/^```.*$/d')

# Strip any reasoning/thinking text before the actual HTML (case-insensitive)
NEW_HTML=$(echo "$NEW_HTML" | sed -n '/<!DOCTYPE html>/I,$p')

# Validate the output looks like a complete HTML file
if [ ${#NEW_HTML} -lt 1000 ]; then
  DBG=$(cat "$DEBUG_INFO")
  ERR=$(tail -c 2000 "$LLM_STDERR")
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "$(printf '❌ Site regeneration failed: invalid HTML (%d bytes after filtering, %d raw).\n\nDebug:\n```\n%s\n```\n\nRaw output (first 1000 chars):\n```\n%s\n```\n\nStderr (last 2000 chars):\n```\n%s\n```' "${#NEW_HTML}" "$RAW_SIZE" "$DBG" "$RAW_PREVIEW" "$ERR")"
  exit 1
fi

# Store the regenerated content as a git blob object
NEW_BLOB=$(printf '%s\n' "$NEW_HTML" | git hash-object -w --stdin)

# Check whether index.html actually changed compared to the merge/base state
OLD_BLOB=$(git ls-tree "$REGEN_BASE_TREE" -- index.html | awk '{print $3}')

if [ "$OLD_BLOB" = "$NEW_BLOB" ]; then
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "ℹ️ No changes to \`index.html\` — the site is already up to date with \`SPEC.md\`."
  exit 0
fi

# Build the new tree: start from the merge/base tree and replace index.html

NEW_TREE=$(git ls-tree "$REGEN_BASE_TREE" | \
  awk -v blob="$NEW_BLOB" '/\tindex\.html$/{printf "100644 blob %s\tindex.html\n", blob; next} {print}' | \
  git mktree)

if [ "$REGEN_PARENT" = "MERGE" ]; then
  # Conflict case: create a merge commit with both parents
  NEW_COMMIT=$(git commit-tree "$NEW_TREE" -p "$HEAD_SHA" -p "$BASE_HEAD" \
    -m "regen: update index.html from SPEC.md")
else
  # Clean merge case: create a commit on top of the merge commit
  NEW_COMMIT=$(git commit-tree "$NEW_TREE" -p "$REGEN_PARENT" \
    -m "regen: update index.html from SPEC.md")
fi

if [ "${IS_FORK:-false}" = "true" ]; then
  # Fork PR — try different strategies to deliver the regen commit
  REGEN_BRANCH="regen/pr-$PR_NUMBER"
  BASE_OWNER="${REPO%%/*}"

  if [ -n "${MAINTAINER_PAT:-}" ]; then
    # Strategy 1: Push directly to the fork branch using the PAT.
    # Build a fork-safe commit: start from the fork's tree (HEAD_SHA) and only
    # replace index.html. This avoids pushing .github/ workflow changes from
    # the base repo, which GitHub would block for security.
    FORK_TREE=$(git ls-tree "$HEAD_SHA" | \
      awk -v blob="$NEW_BLOB" '/\tindex\.html$/{printf "100644 blob %s\tindex.html\n", blob; next} {print}' | \
      git mktree)
    FORK_COMMIT=$(git commit-tree "$FORK_TREE" -p "$HEAD_SHA" \
      -m "regen: update index.html from SPEC.md")

    FORK_URL="https://x-access-token:${MAINTAINER_PAT}@github.com/${HEAD_REPO}.git"
    PUSH_ERR=$(mktemp)
    if git push --force "$FORK_URL" "$FORK_COMMIT:refs/heads/$HEAD_REF" 2>"$PUSH_ERR"; then
      gh pr comment "$PR_NUMBER" --repo "$REPO" \
        --body "✅ Site regenerated and pushed to this PR branch."
      exit 0
    else
      echo "Strategy 1 (push to fork) failed: $(cat "$PUSH_ERR")" >&2
    fi
  fi

  # Push the regen commit to a branch in the base repo for all fork fallbacks
  git push origin "$NEW_COMMIT:refs/heads/$REGEN_BRANCH" --force

  # Strategy 2/3 may fail if a PR already exists from a previous /regen.
  # Since the regen branch is always force-pushed, the existing PR is already
  # up-to-date. Just notify and exit.

  if [ -n "${MAINTAINER_PAT:-}" ]; then
    # Strategy 2: Open a PR on the contributor's fork (or reuse existing)
    EXISTING_PR=$(GH_TOKEN="$MAINTAINER_PAT" gh api "repos/${HEAD_REPO}/pulls?head=${BASE_OWNER}:${REGEN_BRANCH}&base=${HEAD_REF}&state=open" 2>/dev/null | jq -r '.[0].html_url // empty')
    if [ -n "$EXISTING_PR" ]; then
      gh pr comment "$PR_NUMBER" --repo "$REPO" \
        --body "✅ Site regenerated! The PR on your fork has been updated with the latest \`index.html\`: ${EXISTING_PR}"
      exit 0
    fi
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

  # Strategy 3: Fallback — new PR to main in the base repo (or reuse existing)
  EXISTING_PR=$(gh pr list --repo "$REPO" --head "$REGEN_BRANCH" --base main --state open --json url --jq '.[0].url' 2>/dev/null)
  if [ -n "$EXISTING_PR" ]; then
    gh pr comment "$PR_NUMBER" --repo "$REPO" \
      --body "✅ Site regenerated! The existing PR has been updated: ${EXISTING_PR}"
    exit 0
  fi
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
