---
name: code-review
description: "Use when reviewing a PR, reviewing code, or checking a pull request"
license: MIT
compatibility: "Requires gh CLI (authenticated) and a repo with a pull request or diff to review"
metadata:
  author: cristoslc
  argument-hint: "<pr-url-or-branch> --agents security,style,logic,docs"
  user-invocable: true
  allowed-tools:
    - Bash
    - Read
    - Write
    - Edit
    - Grep
    - Glob
    - MCP_DOCKER_brave_web_search
---

Review a pull request or code diff using parallel specialized agents. $ARGUMENTS

## Overview

Runs up to four specialized review agents in parallel (security, style, logic, documentation), then synthesizes their findings into a single recommendation: `approved`, `needs_changes`, or `blocked`.

Each agent returns structured JSON findings with severity levels (critical/high/medium/low).

## When to Use

- User asks to review a PR or code diff
- User mentions "code review" or "review this"
- Checking a pull request before merge

## When NOT to Use

- General code exploration (not a review)
- Linting or formatting (use language-specific tools)
- Security auditing without a diff (use dedicated scanners)
- Reviews of diffs larger than ~10K lines (agents will miss things)

## Step 0 — Parse arguments

Parse `$ARGUMENTS`:
1. If the argument is a GitHub PR URL (`https://github.com/<owner>/<repo>/pull/<number>`), extract `owner`, `repo`, and `PR number`.
2. If the argument is a branch name or `<owner>/<repo>#<number>`, resolve it:
   - For `<owner>/<repo>#<number>`: extract components.
   - For a plain branch name: determine the current repo from `git remote get-url origin`, then find the open PR for that branch using `gh pr list --head <branch> --json number,headRepository,headRepositoryOwner`.
3. If no argument is given, detect the current branch and find its associated PR:
   ```bash
   BRANCH=$(git --no-pager branch --show-current)
   gh pr list --head "$BRANCH" --json number --jq '.[0].number'
   ```
4. If the user specified `--agents`, parse the comma-separated list. Otherwise, run all four agents.
5. Store: `OWNER`, `REPO`, `PR_NUMBER`, `AGENTS` (array of agent names).

If no PR can be found, ask the user to provide a PR URL or number.

## Step 1 — Fetch the PR diff and metadata

```bash
gh pr diff "$PR_NUMBER" --repo "$OWNER/$REPO" > /tmp/codereview_diff.txt 2>/dev/null
gh pr view "$PR_NUMBER" --repo "$OWNER/$REPO" --json title,body,headRefName,baseRefName,author,files --jq '.' > /tmp/codereview_meta.json 2>/dev/null
```

Check the diff size:
```bash
wc -l /tmp/codereview_diff.txt
```

If the diff exceeds 3000 lines, split it into chunks of ~2500 lines and run each agent across chunks. Otherwise, use the whole diff in a single pass.

Read the diff using the **Read tool** (not Bash) to load it into context for the agent prompts.

## Step 2 — Run review agents in parallel (use sub-agents)

For each agent in `AGENTS`, dispatch a sub-agent that:
1. Receives the agent-specific system prompt from `agent-prompts.md` (include the full text inline — sub-agents cannot read skill files)
2. Receives the diff content as the user message
3. Returns its findings as a JSON object matching the schema below

Run all agents **concurrently** — do not wait for one to finish before starting the next.

### Schema (each agent must return this)

```json
{
  "status": "passed" | "warning" | "failed",
  "findings": [
    {
      "severity": "critical" | "high" | "medium" | "low",
      "title": "Brief title, one sentence, no period",
      "description": "Specific issue: what goes wrong, under what conditions, what the consequence is. No em-dashes. Plain language.",
      "file": "relative/path/to/file.ext",
      "line": 42,
      "suggested_fix": "Raw code showing the fix. No markdown fences."
    }
  ],
  "summary": "Overall assessment"
}
```

Status values:
- `passed` — no issues found
- `warning` — minor issues, should be addressed
- `failed` — critical or high-severity issues found

## Step 3 — Collect and parse results

Each sub-agent's output must be valid JSON. Apply robust parsing:
1. Parse as JSON directly.
2. If parsing fails, strip markdown code fences and retry.
3. If still invalid, wrap the raw output as a single `low`-severity finding with title "Raw LLM Response" so the synthesis step never breaks.

Write each agent's parsed result to `/tmp/codereview_<agent>_result.json`.

## Step 4 — Synthesize

Read all `/tmp/codereview_*_result.json` files, count findings by agent and severity, then apply:

1. **Agent status rules:**
   - Any agent `failed` → overall at least `needs_changes`
   - Any agent `warning` → overall at least `needs_changes`
   - All agents `passed` with no high/critical findings → `approved`
2. **Severity overrides:**
   - Any `critical` finding → `blocked` regardless of agent status
   - 2+ `high` findings across agents → `needs_changes`
   - 1 `high` finding → `needs_changes` only if the originating agent status is `warning` or `failed`
3. Produce a narrative summary of the most important findings.

## Step 5 — Write the review report

Write a markdown report to `~/Downloads/code-review-<owner>-<repo>-<pr-number>.md`:

```markdown
# Code Review: <PR title>

**PR:** <owner>/<repo>#<number> — <title>
**Branch:** <head> → <base>
**Author:** <author>
**Date:** <today's date>

---

## Recommendation: <blocked|needs_changes|approved>

<one-paragraph synthesis summary>

---

<for each agent that ran>

### <Agent Name> — <status>

<agent's summary paragraph>

<for each finding, sorted by severity descending>

- **[SEVERITY]** <title> (`<file>:<line>`)
  <description>

  Suggested fix:
  <suggested_fix indented>

---

## Finding Counts

| Agent | Critical | High | Medium | Low | Total | Status |
|-------|----------|------|--------|-----|-------|--------|
| <agent> | <N> | <N> | <N> | <N> | <N> | <status> |

---

*Generated by code-review — multi-agent PR review system*
*Source: <PR URL>*
```

## Step 6 — Post results

Print the report path to the user. If the user wants to post to GitHub, use `gh api` for inline review comments or `gh pr comment` for a summary comment. **Only post to GitHub if the user explicitly asks.**

## Agent Prompts

Full agent system prompts are in `agent-prompts.md`. When dispatching sub-agents, copy the relevant prompt text inline — sub-agents cannot read skill files.

## Common Mistakes

- **Posting to GitHub without being asked** — Step 6 requires explicit user approval
- **Running agents sequentially** — All agents must run concurrently for speed
- **Using Bash to read the diff** — Use the Read tool so diff content enters context
- **Accepting non-JSON from agents** — Always apply the three-layer parsing fallback
- **Forgetting to split large diffs** — Diffs over 3000 lines must be chunked

## Quick Reference

| Step | Action |
|------|--------|
| 0 | Parse `$ARGUMENTS` → OWNER, REPO, PR_NUMBER, AGENTS |
| 1 | Fetch diff + metadata via `gh` |
| 2 | Dispatch sub-agents concurrently with prompts from `agent-prompts.md` |
| 3 | Parse JSON results, apply fallback for invalid output |
| 4 | Synthesize: severity overrides > agent status rules |
| 5 | Write report to `~/Downloads/` |
| 6 | Print path; post to GitHub only if user asks |