---
id: auditlm-forgejo-review
url: https://github.com/ellenhp/auditlm
fetched: 2026-04-19
type: github-repo
license: AGPL-3.0
stars: 31
language: Rust
---

# auditlm — Self-Hostable AI Code Review for Forgejo

## Overview
A dead-simple, self-hostable code review bot with Forgejo integration. Positioned as "an open-source and self-hosted CodeRabbit" by its author.

## Key Features
- **Forgejo-native**: Designed specifically for Forgejo, not GitHub
- **Local LLM**: Uses local LLM models (llama.cpp with GLM-4.5-Air) for review
- **Privacy-focused**: No data sent to third-party services unless configured
- **Flexible**: Works with any OpenAI-compatible LLM endpoint
- **Isolated**: Each review runs in a clean container environment
- **Language-agnostic**: Analyze code in any language by providing a custom docker image

## Technical Details
- Written in Rust
- Posts detailed reviews directly to pull requests
- Listens for @mentions of a bot user in pull requests
- Containerized deployment with Docker Compose
- Uses Podman/Docker socket for isolated analysis containers

## Limitations
- Very early-stage project (31 stars)
- Forgejo-only (no GitHub, GitLab, etc.)
- Requires local LLM infrastructure (Ollama or compatible)
- Single maintainer
- Documentation is minimal

## Significance
This is one of the **only** AI code review tools explicitly targeting Forgejo as a first-class platform. Most alternatives treat Forgejo/Gitea as an afterthought or don't support them at all.