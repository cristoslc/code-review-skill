---
id: kilo-code-review
url: https://kilo.ai/features/code-reviews
fetched: 2026-04-19
type: web
---

# Kilo — Open Source AI Coding Agent (with Code Review)

## Overview
Kilo (formerly a fork of Cline) is primarily an AI coding agent/assistant for IDEs (VS Code, JetBrains, CLI) — not a dedicated PR review tool. It has added a "Code Reviews" feature that automatically reviews PRs and posts findings to GitHub.

## Code Review Feature
- Automatically reviews PRs
- Posts findings as inline comments
- Supports multiple models (Claude Opus 4.5, GPT-5.2, etc.)
- 2-minute review time, can run on every push

## Platform Support
- **GitHub, GitLab, Bitbucket (coming soon)**
- **No Forgejo/Gitea support**
- **No Azure DevOps support**

## Licensing
- **Apache 2.0** for the core extension
- 1.5M+ users, 25 trillion tokens processed
- BYOK (bring your own key) with zero markup, or use Kilo's routing with pay-as-you-go
- "Open source" claim is justified for the core — the Apache 2.0 license covers the VS Code extension

## Critical Assessment
- Kilo is **not primarily a code review tool**. It's a coding agent that added PR review as a feature.
- The code review feature is GitHub-first; GitLab and Bitbucket are listed as "coming soon."
- No evidence of Forgejo/Gitea/Azure DevOps support.
- The "open source" label is more justified than Kodus (actually Apache 2.0, not open-core), but the product is fundamentally an IDE assistant, not a dedicated code review system.
- Comparison to CodeRabbit is apples-to-oranges: Kilo reviews PRs as one feature among many; CodeRabbit is purpose-built for PR review with deterministic linters, context engineering, and pre-merge checks.