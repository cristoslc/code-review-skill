---
id: pr-agent-forgejo-issue
url: https://github.com/qodo-ai/pr-agent/issues/1657
fetched: 2026-04-19
type: github-issue
---

# PR-Agent Issue #1657 — Gitea/Forgejo Support

## Key Points
- **Feature request**: Support running PR-Agent against repositories on Forgejo/Gitea
- **Motivation**: Self-hosting users with personal Forgejo servers want AI review capabilities
- **Status**: As of v0.30+, PR-Agent now has a `gitea-app` Docker image (`codiumai/pr-agent:0.30-gitea-app`)
- **Important**: PR-Agent supports **Gitea**, not Forgejo directly. Since Forgejo is a fork of Gitea with compatible API, this may work with Forgejo but is not explicitly tested or documented.

## Implications
- PR-Agent is the most mature open-source AI code review tool with the broadest forge support
- Gitea support was added in v0.30, but Forgejo compatibility remains untested
- Self-hosting PR-Agent requires Docker and an LLM API key (OpenAI or compatible)
- PR-Agent is now a "community-maintained legacy project" — Qodo has moved to the commercial Qodo Merge product