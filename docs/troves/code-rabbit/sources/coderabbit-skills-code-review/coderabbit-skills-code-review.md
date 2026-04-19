---
id: coderabbit-skills-code-review
url: https://github.com/coderabbitai/skills/tree/main/skills/code-review
fetched: 2026-04-19
type: github-repo
---

# CodeRabbit Code Review Skill

## Description
AI-powered code review using CodeRabbit. Enables developers to implement features, review code, and fix issues in autonomous cycles without manual intervention.

## Capabilities
- Finds bugs, security issues, and quality risks in changed code.
- Groups findings by severity (Critical, Warning, Info).
- Works on staged, committed, or all changes; supports base branch/commit.
- Provides fix suggestions (`--plain`) or minimal output for agents (`--agent`).

## When to Use
When user asks to:
- Review code changes / Review my code
- Check code quality / Find bugs or security issues
- Get PR feedback / Pull request review
- What's wrong with my code / my changes
- Run coderabbit / Use coderabbit

## How to Review
### 1. Check Prerequisites
```bash
coderabbit --version 2>/dev/null || echo "NOT_INSTALLED"
coderabbit auth status 2>&1
```

- If the CLI is already installed, confirm it is an expected version from an official source before proceeding.
- The `--agent` flag requires CodeRabbit CLI v0.4.0 or later. If the installed version is older, ask the user to upgrade.

### 2. If CLI Not Installed
Tell user:
```text
Please install CodeRabbit CLI from the official source:
https://www.coderabbit.ai/cli

Prefer installing via a package manager (npm, Homebrew) when available.
If downloading a binary directly, verify the release signature or checksum
from the GitHub releases page before running it.
```

### 3. Run Review
- Use `--agent` for minimal output suitable for agents.
- Use `--plain` for fix suggestions and more detailed output.