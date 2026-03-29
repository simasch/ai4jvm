# Generalized AI-Governed, Spec-Driven Site Framework

## Design Document

### Overview

AI4JVM demonstrates a pattern worth generalizing: a **spec-driven website** with **AI-governed contributions** and **AI-powered site generation**, all orchestrated through GitHub Actions and Claude Code. This document describes the generalized architecture, its components, and how it can be adapted for any curated content site.

---

## 1. The Three Pillars

### 1.1 Spec-Driven Content (Source of Truth)

**Pattern:** All site content lives in a single Markdown specification file (`SPEC.md`). The HTML presentation layer is derived from it, never edited directly by humans.

**Why it works:**
- Markdown is contributor-friendly — no HTML/CSS knowledge required
- Diffs are readable — reviewers see content changes, not markup noise
- The spec enforces structure — sections, ordering, required fields are all defined
- AI can reliably generate HTML from structured Markdown

**Generalized form:**
- `SPEC.md` defines content sections, items, metadata, and ordering
- `STYLE.md` (optional) defines visual design tokens, layout rules, and component patterns
- `CONTRIBUTING.md` defines editorial policy and acceptance criteria
- `index.html` is a build artifact, generated from the spec

```
SPEC.md (content) + STYLE.md (design) + CONTRIBUTING.md (policy)
        ↓ AI generation
    index.html (output artifact)
```

### 1.2 AI Governance (Automated Review)

**Pattern:** When a PR is submitted, a maintainer triggers an AI review that evaluates the contribution against documented guidelines. The AI verifies links, checks project activity, assesses relevance, and produces a structured review.

**How it works in AI4JVM:**
1. Contributor submits PR modifying `SPEC.md`
2. Maintainer comments `/review` on the PR
3. GitHub Actions workflow triggers:
   - Checks out base branch (trusted code — the review scripts)
   - Fetches PR head commit (untrusted content — the spec changes)
   - Extracts the `SPEC.md` diff
   - Feeds diff + `CONTRIBUTING.md` guidelines into Claude Code
   - Claude Code uses `WebFetch` to verify every URL in the diff
   - Claude Code checks GitHub repos for activity (recent commits, releases)
   - Produces a structured review with per-item assessments
4. Review is posted as a PR comment

**Security model:**
- Scripts are always checked out from the base branch (maintainer-controlled)
- PR content is treated as untrusted input
- Only repository OWNER/MEMBER/COLLABORATOR can trigger `/review`
- The AI has read-only access to the repository; it can only post comments

**Generalized form:**
- `contribution-review-prompt.md` — a template that defines what the AI checks
- Domain-specific validation rules injected from `CONTRIBUTING.md`
- Pluggable verification steps (URL checking, API probing, license scanning)
- Structured output format (per-item verdicts, overall recommendation)

### 1.3 AI Site Generation (Automated Build)

**Pattern:** When a maintainer is satisfied with the spec changes, they trigger AI-powered regeneration of the HTML from the updated spec.

**How it works in AI4JVM:**
1. Maintainer comments `/regen` on the PR
2. GitHub Actions workflow triggers:
   - Merges base into PR head to get the latest `index.html` as starting point
   - Extracts the `SPEC.md` diff
   - Feeds diff + current `index.html` into Claude Code
   - Claude Code edits `index.html` to reflect only the spec changes
   - Output is validated (file size > 1000 bytes, starts with `<!DOCTYPE html>`)
   - New commit is created on the PR branch (parented on HEAD, not the merge)
3. Handles fork PRs with three fallback strategies (direct push, fork PR, main PR)

**Why AI generation instead of a traditional build:**
- The "template" is implicit — the AI understands the existing HTML patterns and extends them
- No template language to maintain — the spec and existing HTML are the template
- Handles creative layout decisions (badge classes, link types, card styles) contextually
- Adapts to design evolution without template refactoring

**Generalized form:**
- AI reads the diff (not the full spec) to make surgical updates
- Existing HTML serves as few-shot examples of the desired output
- Validation gates prevent broken output from being committed
- Fork-aware commit strategy preserves clean PR history

---

## 2. Generalized Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Repository                        │
│                                                      │
│  SPEC.md          ← Content (source of truth)        │
│  STYLE.md         ← Design system (optional)         │
│  CONTRIBUTING.md  ← Editorial policy                 │
│  AGENTS.md        ← AI agent instructions            │
│  index.html       ← Generated output (artifact)      │
│                                                      │
│  .github/                                            │
│    workflows/                                        │
│      review.yml   ← AI review workflow               │
│      regen.yml    ← AI generation workflow            │
│      deploy.yml   ← Deployment (Pages, Netlify, etc) │
│    scripts/                                          │
│      review-prompt.md  ← Review prompt template      │
│      review.sh         ← Review orchestration        │
│      regen.sh          ← Generation orchestration    │
└─────────────────────────────────────────────────────┘
```

### 2.1 Workflow: Contribution Review

```
PR opened (SPEC.md changed)
        │
        ▼
Maintainer comments `/review`
        │
        ▼
┌─────────────────────────────────┐
│  GitHub Actions                  │
│                                  │
│  1. Checkout BASE (trusted)      │
│  2. Fetch HEAD (untrusted)       │
│  3. Extract SPEC.md diff         │
│  4. Inject CONTRIBUTING.md       │
│     into review prompt template  │
│  5. Run Claude Code:             │
│     - Parse diff                 │
│     - Verify URLs (WebFetch)     │
│     - Check project health       │
│     - Apply editorial policy     │
│     - Produce structured review  │
│  6. Post review as PR comment    │
└─────────────────────────────────┘
```

### 2.2 Workflow: Site Regeneration

```
Maintainer comments `/regen`
        │
        ▼
┌──────────────────────────────────┐
│  GitHub Actions                   │
│                                   │
│  1. Merge base → PR head          │
│     (get latest index.html)       │
│  2. Extract SPEC.md diff          │
│  3. Run Claude Code:              │
│     - Read diff + index.html      │
│     - Edit index.html surgically  │
│     - Verify new links            │
│  4. Validate output:              │
│     - File size check             │
│     - HTML structure check        │
│     - Diff exists check           │
│  5. Commit to PR branch           │
│     (parented on HEAD_SHA)        │
│  6. Handle fork edge cases        │
└──────────────────────────────────┘
```

---

## 3. Technical Details

### 3.1 Claude Code CLI Invocation

Both workflows use Claude Code as a CLI tool in GitHub Actions:

```bash
npm install -g @anthropic-ai/claude-code

claude -p "$PROMPT" \
  --model claude-opus-4-6 \
  --max-turns 30 \
  --allowedTools Read,Edit,WebFetch,WebSearch \
  --output-format text
```

Key parameters:
- **`-p`** — non-interactive mode, accepts prompt from argument or stdin
- **`--model`** — selects the model (opus for quality, sonnet for speed/cost)
- **`--max-turns`** — caps agentic loops to prevent runaway execution
- **`--allowedTools`** — restricts tool access (no Bash, no Write for regen)
- **`--output-format text`** — returns plain text for posting as comments

### 3.2 Security: Trusted vs. Untrusted Code

A critical design decision: **scripts execute from the base branch, not the PR**.

```yaml
# Check out base branch (trusted code)
- uses: actions/checkout@v4
  with:
    ref: ${{ github.event.pull_request.base.ref }}

# Fetch PR head (untrusted content only)
- run: git fetch origin ${{ env.HEAD_SHA }}
```

This prevents a malicious PR from modifying the review or regen scripts to bypass governance. The AI operates on the *diff* of the untrusted content, using *trusted* prompts and scripts.

### 3.3 Prompt Engineering for Review

The review prompt is a template that gets `CONTRIBUTING.md` injected at build time:

```markdown
## Contribution Guidelines
{CONTRIBUTING_MD_CONTENT}

## Your Task
Analyze the following SPEC.md diff and evaluate each change against
the contribution guidelines above.

For each added or modified item, verify:
- [ ] URLs are reachable (use WebFetch)
- [ ] Project is actively maintained
- [ ] Content matches the linked resource
- [ ] Item meets relevance threshold
```

This makes the governance policy **declarative** — changing `CONTRIBUTING.md` automatically changes what the AI enforces, with no code changes required.

### 3.4 Diff-Based Generation

The regen workflow passes only the SPEC.md **diff** to Claude Code, not the full spec:

```bash
DIFF=$(git diff HEAD...$HEAD_SHA -- SPEC.md)
```

Prompt structure:
```
Read the SPEC.md diff below. Update index.html to reflect
ONLY these changes. Do not modify unrelated sections.

<diff>
{SPEC_MD_DIFF}
</diff>
```

This approach:
- Minimizes token usage (diff is much smaller than full spec)
- Reduces risk of unintended changes to unrelated sections
- Makes the AI's task focused and verifiable

### 3.5 Fork PR Handling

Fork PRs present a challenge: the workflow can't push directly to the contributor's fork without a PAT. The regen workflow implements three fallback strategies:

1. **Direct push to fork** — uses `MAINTAINER_PAT` to push to the fork's branch
2. **PR on fork** — creates a PR against the fork's branch with the regen changes
3. **PR to main** — creates a new branch on the main repo and opens a PR

Each strategy is tried in order; if one fails, the next is attempted.

### 3.6 Commit Strategy

The regen workflow creates commits using low-level git operations to avoid merge artifacts in the PR:

```bash
# Create a tree with the updated index.html
NEW_TREE=$(git ls-tree HEAD | \
  sed "s|[^ ]* blob [^ ]*\tindex.html|100644 blob $BLOB_HASH\tindex.html|" | \
  git mktree)

# Create commit parented on the PR's HEAD (not the merge commit)
NEW_COMMIT=$(git commit-tree "$NEW_TREE" -p "$HEAD_SHA" -m "regen: ...")
```

This ensures the PR shows a clean history: the contributor's spec changes plus a single regen commit.

---

## 4. Adaptation Guide

### 4.1 Example: Curated Resource Directory

**Use case:** A community-maintained directory of resources (e.g., "Awesome Rust ML", "iOS Dev Tools", "DevOps Resources").

**Adapt by:**
- Define sections and card schema in `SPEC.md`
- Set relevance/quality criteria in `CONTRIBUTING.md`
- Customize badge types and design tokens in the HTML template
- Review prompt verifies URLs and checks project activity

### 4.2 Example: Team or Organization Directory

**Use case:** A company's internal tool catalog or team directory page.

**Adapt by:**
- `SPEC.md` lists teams, tools, or services with metadata
- `CONTRIBUTING.md` defines ownership and approval rules
- Review checks for required fields (owner, status, documentation link)
- Private deployment (not GitHub Pages) via custom deploy workflow

### 4.3 Example: Documentation or Knowledge Base

**Use case:** A curated, opinionated documentation site (e.g., best practices guide, style guide, onboarding portal).

**Adapt by:**
- `SPEC.md` uses longer-form content sections
- Review checks for accuracy, tone, and completeness
- Regen produces multi-page output (multiple HTML files or sections)
- Add `--allowedTools` for domain-specific verification (API checks, code compilation)

### 4.4 Example: Event or Conference Page

**Use case:** A conference website with speakers, talks, schedule, and sponsors.

**Adapt by:**
- `SPEC.md` sections: Schedule, Speakers, Sponsors, Venue
- Review validates speaker bios, talk abstracts, date/time consistency
- Regen handles responsive schedule grids and speaker cards
- Time-sensitive content rules in `CONTRIBUTING.md` (archive past events)

---

## 5. Design Principles

1. **Spec is the source of truth.** Humans edit Markdown. AI generates HTML. Never the reverse.

2. **Policy is declarative.** Governance rules live in `CONTRIBUTING.md`, not in code. Changing the policy document changes what the AI enforces.

3. **AI is a tool, not an authority.** Maintainers trigger review and regen explicitly. The AI advises; humans decide.

4. **Trust boundaries are explicit.** Scripts run from the base branch. PR content is untrusted input. The AI's tool access is restricted.

5. **Diffs over full rebuilds.** Pass the AI only what changed. This is cheaper, faster, and less error-prone than full regeneration.

6. **Validate outputs mechanically.** AI-generated HTML is checked for size, structure, and correctness before being committed. Trust but verify.

7. **Progressive fallback.** Handle edge cases (forks, merge conflicts, empty diffs) with ordered fallback strategies rather than failing.

---

## 6. Limitations and Considerations

- **Cost:** Each review/regen invocation uses API tokens. Opus is higher quality but more expensive; Sonnet is a viable alternative for simpler sites.
- **Determinism:** AI generation is not perfectly deterministic. Two regen runs on the same diff may produce slightly different HTML. The validation gates mitigate this.
- **Scale:** This pattern works well for single-page or small multi-page sites. For large sites (hundreds of pages), a hybrid approach with traditional templating + AI for content sections may be more appropriate.
- **Model dependency:** The system depends on Claude Code CLI availability and API access in CI. Network issues or API outages can block the workflow.
- **Review depth:** AI review is thorough but not infallible. It complements, not replaces, human review. The maintainer trigger model ensures a human is always in the loop.
