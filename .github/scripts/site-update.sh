#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

BASE_HEAD=$(git rev-parse HEAD)

# ── Step 1: Fetch PR comments ───────────────────────────────────────────────

COMMENTS_FILE=$(mktemp "$REPO_ROOT/pr-comments-XXXXXX.md")

# Get PR review comments (inline code review comments)
REVIEW_COMMENTS=$(gh api "repos/$REPO/pulls/$PR_NUMBER/comments" \
  --jq '.[] | "**\(.user.login)** on `\(.path)`:\n\(.body)\n"' 2>/dev/null || true)

# Get PR issue comments (top-level conversation comments)
ISSUE_COMMENTS=$(gh api "repos/$REPO/issues/$PR_NUMBER/comments" \
  --jq '.[] | "**\(.user.login)**:\n\(.body)\n"' 2>/dev/null || true)

# Get the PR description
PR_BODY=$(gh api "repos/$REPO/pulls/$PR_NUMBER" --jq '.body // ""' 2>/dev/null || true)

{
  echo "## PR Description"
  echo "$PR_BODY"
  echo ""
  echo "## Review Comments (inline)"
  echo "$REVIEW_COMMENTS"
  echo ""
  echo "## Conversation Comments"
  echo "$ISSUE_COMMENTS"
} > "$COMMENTS_FILE"

# ── Step 2: Prepare working tree with PR's SPEC.md ──────────────────────────

# Get the PR's current SPEC.md so Claude can edit it
git show "$HEAD_SHA:SPEC.md" > "$REPO_ROOT/SPEC.md"
cp "$REPO_ROOT/SPEC.md" "$REPO_ROOT/SPEC.md.orig"

# Also get the base SPEC.md for diff context
git show "$BASE_HEAD:SPEC.md" > "$REPO_ROOT/SPEC.md.base"

# ── Step 3: Have Claude update SPEC.md based on comments ────────────────────

PROMPT="You are updating SPEC.md for a website based on PR feedback.

The file SPEC.md contains the current PR version of the spec.
The file SPEC.md.base contains the base branch version.
The file $(basename "$COMMENTS_FILE") contains all PR comments and review feedback.

Read all three files. Then update SPEC.md to address the feedback in the comments.

Rules:
- Only modify SPEC.md. Do not create or modify any other files.
- Only make changes that are requested or implied by the PR comments.
- Preserve the existing structure and formatting of SPEC.md.
- Use WebFetch to verify URLs for any NEW items you add."

LLM_STDERR=$(mktemp)
if ! claude -p "$PROMPT" \
  --allowedTools "Read,Edit,WebFetch,WebSearch" \
  --model claude-opus-4-6 \
  --max-turns 30 \
  2>"$LLM_STDERR"; then
  ERR=$(tail -c 3000 "$LLM_STDERR")
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "$(printf '❌ Site update failed (SPEC.md update step):\n\n```\n%s\n```' "$ERR")"
  rm -f "$COMMENTS_FILE" "$REPO_ROOT/SPEC.md.base"
  exit 1
fi

rm -f "$COMMENTS_FILE" "$REPO_ROOT/SPEC.md.base"

# Check if SPEC.md actually changed
if diff -q "$REPO_ROOT/SPEC.md" "$REPO_ROOT/SPEC.md.orig" >/dev/null 2>&1; then
  rm -f "$REPO_ROOT/SPEC.md.orig"
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "ℹ️ No changes to \`SPEC.md\` needed based on the PR comments."
  exit 0
fi
rm -f "$REPO_ROOT/SPEC.md.orig"

# ── Step 4: Build a commit with the updated SPEC.md ─────────────────────────

SPEC_BLOB=$(git hash-object -w "$REPO_ROOT/SPEC.md")

SPEC_TREE=$(git ls-tree "$HEAD_SHA" | \
  awk -v blob="$SPEC_BLOB" '/\tSPEC\.md$/{printf "100644 blob %s\tSPEC.md\n", blob; next} {print}' | \
  git mktree)

SPEC_COMMIT=$(git commit-tree "$SPEC_TREE" -p "$HEAD_SHA" \
  -m "update SPEC.md from PR feedback")

# ── Step 5: Regenerate index.html from the updated SPEC ─────────────────────

# Now run the regen logic with the new SPEC commit as the head.
# Get the SPEC.md diff between base and our new commit
SPEC_DIFF=$(git diff "$BASE_HEAD...$SPEC_COMMIT" -- SPEC.md)

if [ -z "$SPEC_DIFF" ]; then
  # SPEC.md ended up matching base — just push the spec commit
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "ℹ️ After applying feedback, \`SPEC.md\` matches the base branch — no site regeneration needed."
  exit 0
fi

# Merge base into the spec commit to get the most up-to-date index.html
if MERGED_TREE=$(git merge-tree --write-tree HEAD "$SPEC_COMMIT" 2>/dev/null); then
  MERGE_COMMIT=$(git commit-tree "$MERGED_TREE" -p "$SPEC_COMMIT" -p "$BASE_HEAD" \
    -m "Merge $BASE_REF into PR branch")
  git show "$MERGE_COMMIT:index.html" > "$REPO_ROOT/index.html"
else
  git show "$BASE_HEAD:index.html" > "$REPO_ROOT/index.html"
fi
cp "$REPO_ROOT/index.html" "$REPO_ROOT/index.html.orig"

DIFF_FILE=$(mktemp "$REPO_ROOT/spec-diff-XXXXXX.patch")
printf '%s' "$SPEC_DIFF" > "$DIFF_FILE"

REGEN_PROMPT="Read the SPEC.md diff in $(basename "$DIFF_FILE") and update index.html to reflect ONLY those changes.

For added items: create the corresponding HTML (cards, people, links, etc.) matching the existing style/structure in index.html. Insert in the correct position.
For removed items: delete the corresponding HTML block.
For modified items: update the corresponding HTML to match.

Rules:
- Do NOT modify any HTML comments.
- Do NOT change anything not affected by the diff.
- Use WebFetch to verify URLs for NEW items. If broken, add <!-- LINK CHECK: 404 --> next to the link.
- Only edit index.html. Do not create or modify any other files."

LLM_STDERR=$(mktemp)
if ! claude -p "$REGEN_PROMPT" \
  --allowedTools "Read,Edit,WebFetch,WebSearch" \
  --model claude-opus-4-6 \
  --max-turns 30 \
  2>"$LLM_STDERR"; then
  ERR=$(tail -c 3000 "$LLM_STDERR")
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "$(printf '❌ Site update failed (index.html regen step):\n\n```\n%s\n```' "$ERR")"
  rm -f "$DIFF_FILE"
  exit 1
fi

rm -f "$DIFF_FILE"

NEW_HTML=$(cat "$REPO_ROOT/index.html")

if [ ${#NEW_HTML} -lt 1000 ]; then
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "❌ Site update failed: index.html is too small after editing (${#NEW_HTML} bytes)."
  exit 1
fi

if ! head -1 "$REPO_ROOT/index.html" | grep -qi '<!DOCTYPE html>'; then
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "❌ Site update failed: index.html does not start with <!DOCTYPE html>."
  exit 1
fi

# ── Step 6: Build final commit with both SPEC.md and index.html updates ─────

# Check if index.html changed
if diff -q "$REPO_ROOT/index.html" "$REPO_ROOT/index.html.orig" >/dev/null 2>&1; then
  rm -f "$REPO_ROOT/index.html.orig"
  # SPEC.md changed but index.html didn't — commit just the SPEC.md update
  FINAL_COMMIT="$SPEC_COMMIT"
  COMMENT_MSG="✅ Updated \`SPEC.md\` from PR feedback and pushed to this PR branch. (No \`index.html\` changes needed.)"
else
  rm -f "$REPO_ROOT/index.html.orig"
  HTML_BLOB=$(git hash-object -w "$REPO_ROOT/index.html")

  FINAL_TREE=$(git ls-tree "$SPEC_COMMIT" | \
    awk -v blob="$HTML_BLOB" '/\tindex\.html$/{printf "100644 blob %s\tindex.html\n", blob; next} {print}' | \
    git mktree)

  FINAL_COMMIT=$(git commit-tree "$FINAL_TREE" -p "$SPEC_COMMIT" \
    -m "regen: update index.html from SPEC.md")
  COMMENT_MSG="✅ Updated \`SPEC.md\` from PR feedback and regenerated \`index.html\`. Pushed to this PR branch."
fi

# ── Step 7: Push ─────────────────────────────────────────────────────────────

if [ "${IS_FORK:-false}" = "true" ]; then
  REGEN_BRANCH="update/pr-$PR_NUMBER"
  BASE_OWNER="${REPO%%/*}"

  if [ -n "${MAINTAINER_PAT:-}" ]; then
    FORK_URL="https://x-access-token:${MAINTAINER_PAT}@github.com/${HEAD_REPO}.git"
    PUSH_ERR=$(mktemp)
    if git push --force "$FORK_URL" "$FINAL_COMMIT:refs/heads/$HEAD_REF" 2>"$PUSH_ERR"; then
      gh pr comment "$PR_NUMBER" --repo "$REPO" --body "$COMMENT_MSG"
      exit 0
    else
      echo "Strategy 1 (push to fork) failed: $(cat "$PUSH_ERR")" >&2
    fi
  fi

  git push origin "$FINAL_COMMIT:refs/heads/$REGEN_BRANCH" --force

  if [ -n "${MAINTAINER_PAT:-}" ]; then
    EXISTING_PR=$(GH_TOKEN="$MAINTAINER_PAT" gh api "repos/${HEAD_REPO}/pulls?head=${BASE_OWNER}:${REGEN_BRANCH}&base=${HEAD_REF}&state=open" 2>/dev/null | jq -r '.[0].html_url // empty')
    if [ -n "$EXISTING_PR" ]; then
      gh pr comment "$PR_NUMBER" --repo "$REPO" \
        --body "✅ Site updated! The PR on your fork has been updated: ${EXISTING_PR}"
      exit 0
    fi
    GH_TOKEN="$MAINTAINER_PAT" gh api "repos/${HEAD_REPO}/pulls" \
      -f title="update: SPEC.md and index.html from PR feedback" \
      -f head="${BASE_OWNER}:${REGEN_BRANCH}" \
      -f base="$HEAD_REF" \
      -f body="Automated site update from [PR #${PR_NUMBER}](https://github.com/${REPO}/pull/${PR_NUMBER}). Merge this to update your PR branch." \
      2>/dev/null \
    && {
      gh pr comment "$PR_NUMBER" --repo "$REPO" \
        --body "✅ Site updated! I've opened a PR on your fork — merge it to update this PR."
      exit 0
    }
  fi

  EXISTING_PR=$(gh pr list --repo "$REPO" --head "$REGEN_BRANCH" --base main --state open --json url --jq '.[0].url' 2>/dev/null)
  if [ -n "$EXISTING_PR" ]; then
    gh pr comment "$PR_NUMBER" --repo "$REPO" \
      --body "✅ Site updated! The existing PR has been updated: ${EXISTING_PR}"
    exit 0
  fi
  PR_URL=$(gh pr create --repo "$REPO" \
    --head "$REGEN_BRANCH" \
    --base main \
    --title "update: SPEC.md and index.html for PR #$PR_NUMBER" \
    --body "Automated site update for #${PR_NUMBER}. Includes SPEC.md updates from PR feedback and regenerated \`index.html\`." \
    2>/dev/null) \
  && {
    gh pr comment "$PR_NUMBER" --repo "$REPO" \
      --body "✅ Site updated! Since I couldn't push to your fork, I've opened ${PR_URL}."
    exit 0
  }

  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "✅ Site updated on [\`$REGEN_BRANCH\`](https://github.com/$REPO/tree/$REGEN_BRANCH). A maintainer can merge this after your PR lands."
else
  git push origin "$FINAL_COMMIT:refs/heads/$HEAD_REF"
  gh pr comment "$PR_NUMBER" --repo "$REPO" --body "$COMMENT_MSG"
fi
