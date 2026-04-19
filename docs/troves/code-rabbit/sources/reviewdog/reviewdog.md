---
id: reviewdog
url: https://github.com/reviewdog/reviewdog
fetched: 2026-04-19
type: github-repo
license: MIT
stars: 9229
language: Go
---

# reviewdog — Automated Code Review Tool

## Overview
Reviewdog is a mature, widely-adopted automated code review tool that integrates with any code analysis tool regardless of programming language. It is **not AI-powered** — it routes existing linter/analyzer output to PR review comments.

## Key Features
- **Tool-agnostic**: Integrates with any linter, static analyzer, or formatter that produces diagnostics
- **GitHub PR Review**: Posts results as PR review comments using GitHub API
- **GitHub Checks API**: Integrates with GitHub Checks for better review experience
- **GitHub Actions**: Has first-class GitHub Actions integration (`reviewdog/action-*`)
- **Diff-aware**: Only reports issues in changed lines (filtering by diff)
- **Multiple reporters**: github-pr-review, github-pr-check, github-check, local, etc.

## Platform Support
- **GitHub**: Full support (PR reviews, Checks API, Actions)
- **GitLab**: Supported
- **Gerrit**: Supported
- **Local**: Can run locally with any reporter

## Important Distinction
Reviewdog is a **deterministic** linter output router, not an AI code reviewer. It does not use LLMs to analyze code. It takes output from tools like ESLint, Pylint, Golint, ShellCheck, etc. and posts them as PR review comments.

This makes it complementary to AI reviewers, not a replacement. Many AI review tools (including CodeRabbit) already integrate linters that do similar filtering.

## Forgejo/Gitea Support
- **Not natively supported**. Reviewdog relies on platform-specific reporter implementations.
- Could potentially work with Forgejo/Gitea via local reporter output or custom integration, but no out-of-the-box support exists.

## Relationship to CodeRabbit
CodeRabbit's "40+ deterministic linters" feature serves a similar function to reviewdog — but integrated into the AI review pipeline. Reviewdog is the standalone, open-source, community-maintained alternative for deterministic-only review.