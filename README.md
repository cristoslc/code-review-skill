# code-review-skill

Multi-agent AI code review. Runs up to four parallel specialized agents (security, style, logic, documentation) against your code, collects structured JSON findings, and synthesizes them into a single recommendation: approved, needs_changes, or blocked.

## What it reviews

Not just PR diffs. Review any of these:

- **Pull requests** — via GitHub PR URL or branch name
- **Worktrees** — review changes in an isolated git worktree
- **Unstaged or staged changes** — review what you're about to commit
- **An entire codebase** — develop audit plans and prompts, then run a full review

## How it works

Each review dispatches up to four agents concurrently, each with a domain-specific system prompt:

| Agent | Catches |
|-------|---------|
| **Security** | OWASP Top 10, hardcoded secrets, injection, auth flaws |
| **Style** | Naming conventions, error handling, code quality, idiomatic patterns |
| **Logic** | Null derefs, off-by-one errors, race conditions, business logic bugs |
| **Documentation** | Missing doc comments, stale docs, undocumented exports |

Agents return structured JSON findings with severity levels (critical/high/medium/low). A synthesis step applies severity overrides and produces a single recommendation.

## Research

The `docs/troves/` directory holds research on AI code review tooling — CodeRabbit's architecture, the Forgejo review gap, licensing corrections for alternatives, and feasibility analysis for building self-hosted equivalents.