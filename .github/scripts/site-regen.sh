#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

# Read SPEC.md and index.html from the PR head using git show.
# The working directory remains the trusted base branch throughout — we never
# check out PR code.
SPEC=$(git show "$HEAD_SHA:SPEC.md")
CURRENT_HTML=$(git show "$HEAD_SHA:index.html")

# Build the LLM request — ask the model to update index.html to match SPEC.md
PAYLOAD=$(jq -n \
  --arg spec "$SPEC" \
  --arg html "$CURRENT_HTML" \
  '{
    "model": "openai/gpt-4o",
    "messages": [
      {
        "role": "system",
        "content": "You are a web developer maintaining the AI4JVM website (a single-page HTML + inline CSS site, no build step). Your task is to update index.html so it exactly matches the provided SPEC.md. Preserve existing structure, styles, and inline CSS unless the spec requires changes. Return ONLY the complete updated index.html file — no explanation, no markdown code fences."
      },
      {
        "role": "user",
        "content": ("Current index.html:\n\n" + $html + "\n\nUpdate the above to match this SPEC.md:\n\n" + $spec + "\n\nReturn ONLY the complete updated index.html.")
      }
    ],
    "max_tokens": 16384
  }')

# Call GitHub Models
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" "https://models.github.ai/inference/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -d "$PAYLOAD")

HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)
RESPONSE=$(echo "$HTTP_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "Error: API call failed with HTTP $HTTP_CODE"
  echo "$RESPONSE"
  gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "❌ Site regeneration failed: API returned HTTP \`$HTTP_CODE\`."
  exit 1
fi

NEW_HTML=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

if [ -z "$NEW_HTML" ] || [ "$NEW_HTML" = "null" ]; then
  echo "Error: No content in response"
  echo "$RESPONSE" | jq .
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

git push origin "$NEW_COMMIT:refs/heads/$HEAD_REF"

gh pr comment "$PR_NUMBER" --repo "$REPO" \
  --body "✅ Site regenerated and pushed to this PR branch."
