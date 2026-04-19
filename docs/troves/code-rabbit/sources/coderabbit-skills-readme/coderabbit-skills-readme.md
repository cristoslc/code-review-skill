---
id: coderabbit-skills-readme
url: https://github.com/coderabbitai/skills
fetched: 2026-04-19
type: github-repo
---

# CodeRabbit Skills

## Overview
- **Purpose**: AI-powered code review for 35+ coding agents, powered by CodeRabbit. Detects bugs, security issues, and quality risks before merging.
- **Version**: 1.0.0
- **License**: MIT
- **Agents Supported**: 35+ (Claude Code, Codex, Cursor, GitHub Copilot, etc.)

## Quickstart
1. Install the CodeRabbit CLI from [https://www.coderabbit.ai/cli](https://www.coderabbit.ai/cli).
2. Authenticate: `coderabbit auth login`.
3. Install the skill: `npx skills add coderabbitai/skills`.
4. Tell your agent: **"Review my code."**

## Installation
```bash
npx skills add coderabbitai/skills
```

### Installation Options
| Flag           | Purpose                                          |
|----------------|--------------------------------------------------|
| `-g, --global` | Install to user directory instead of project     |
| `-a, --agent`  | Target specific agents (e.g., `-a claude-code`)  |
| `-s, --skill`  | Install particular skills by name                |
| `--all`        | Install all skills to all agents without prompts |

## Usage
- **Triggers**: 
  - "Review my code"
  - "Check for security issues"
  - "What's wrong with my changes?"
  - "Run a code review"
  - "Review my PR"

- **Workflow**:
  1. Checks if CodeRabbit CLI is installed and authenticated.
  2. Runs the review on your changes.
  3. Presents findings grouped by severity.
  4. Optionally fixes issues and re-reviews.

## Supported Agents
| Agent              | `--agent`         | Project Path           | Global Path                            |
|-------------------|--------------------|------------------------|-----------------------------------------|
| Amp, Kimi Code CLI| `amp`, `kimi-cli`  | `.agents/skills/`      | `~/.config/agents/skills/`             |
| Antigravity        | `antigravity`     | `.agent/skills/`       | `~/.gemini/antigravity/global_skills/` |
| Claude Code        | `claude-code`     | `.claude/skills/`      | `~/.claude/skills/`                    |
| Cline              | `cline`           | `.cline/skills/`       | `~/.cline/skills/`                     |
| CodeBuddy          | `codebuddy`       | `.codebuddy/skills/`   | `~/.codebuddy/skills/`                 |
| Codex              | `codex`           | `.codex/skills/`       | `~/.codex/skills/`                     |
| Command Code       | `command-code`    | `.commandcode/skills/` | `~/.commandcode/skills/`               |
| Continue           | `continue`        | `.continue/skills/`    | `~/.continue/skills/`                  |
| Crush              | `crush`           | `.crush/skills/`       | `~/.config/crush/skills/`              |
| Cursor             | `cursor`          | `.cursor/skills/`      | `~/.cursor/skills/`                    |
| Droid              | `droid`           | `.factory/skills/`     | `~/.factory/skills/`                   |
| Gemini CLI         | `gemini-cli`      | `.gemini/skills/`      | `~/.gemini/skills/`                    |
| GitHub Copilot     | `github-copilot`  | `.github/skills/`      | `~/.copilot/skills/`                   |
| Goose              | `goose`           | `.goose/skills/`       | `~/.config/goose/skills/`              |
| Junie              | `junie`           | `.junie/skills/`       | `~/.junie/skills/`                     |
| Kilo Code          | `kilo`            | `.kilocode/skills/`    | `~/.kilocode/skills/`                  |
| Kiro CLI           | `kiro-cli`        | `.kiro/skills/`        | `~/.kiro/skills/`                      |
| Kode               | `kode`            | `.kode/skills/`        | `~/.kode/skills/`                      |
| MCPJam             | `mcpjam`          | `.mcpjam/skills/`      | `~/.mcpjam/skills/`                    |
| Moltbot            | `moltbot`         | `skills/`              | `~/.moltbot/skills/`                   |
| Mux                | `mux`             | `.mux/skills/`         | `~/.mux/skills/`                       |
| Neovate            | `neovate`         | `.neovate/skills/`     | `~/.neovate/skills/`                   |
| OpenClaude IDE     | `openclaude`      | `.openclaude/skills/`  | `~/.openclaude/skills/`                |
| OpenCode           | `opencode`        | `.opencode/skills/`    | `~/.config/opencode/skills/`           |
| OpenHands          | `openhands`       | `.openhands/skills/`   | `~/.openhands/skills/`                 |
| Pi                 | `pi`              | `.pi/skills/`          | `~/.pi/agent/skills/`                  |
| Pochi              | `pochi`           | `.pochi/skills/`       | `~/.pochi/skills/`                     |