---
id: qodo-pr-agent-deep-dive
url: https://github.com/qodo-ai/pr-agent
fetched: 2026-04-19
type: github-repo
license: AGPL-3.0
stars: 10926
language: Python
---

# PR-Agent (Qodo/CodiumAI) — Deep Dive

## Overview
PR-Agent is now described as "an open-source, community-maintained legacy project of Qodo" and is "distinct from Qodo's primary AI code review offering, which provides a feature-rich, context-aware experience." The README explicitly states: "This repository contains the open-source PR Agent Project. It is not the Qodo free tier."

## Critical Status Assessment
- **Archived?** No — the repo is not archived on GitHub, and releases are still being published (v0.31 as of 2026). However, Qodo's own documentation and the README describe it as a "legacy project" and "community-maintained."
- **Commercial successor**: Qodo Merge (formerly PR-Agent Pro) is the commercial product with additional features (context engine, SOC 2 compliance, priority support, SSO, managed hosting).
- **Open-source health**: The project is in maintenance mode. Qodo's development focus is on the commercial Qodo Merge product. Bug fixes and minor features still land, but substantial new features go to the commercial product first.

## Licensing
- **License**: AGPL-3.0 (not Apache 2.0 as some blog posts claim). The GitHub repo license file clearly shows AGPL-3.0.
- **Implication**: AGPL-3.0 is a copyleft license. Any modification or network use requires making source code available. This is more restrictive than Apache 2.0 and may affect enterprise adoption.

## Forge Support
- GitHub, GitLab, Gitea (docker images: `codiumai/pr-agent:0.31-github_app`, `0.31-gitlab_webhook`, `0.31-gitea-app`, `0.31-bitbucket_app`, `0.31-azure_devops_webhook`)
- **Forgejo**: Not explicitly supported. Gitea support exists (since v0.30), and Forgejo's API compatibility with Gitea may allow it to work, but this is untested.

## Qodo Merge Free Tier
- 75 PR reviews per month per organization
- Integrates with GitHub, GitLab, Bitbucket, Azure DevOps
- Has edit access to repos (unlike the @CodiumAI-Agent promotional bot)
- Is a **hosted SaaS**, not self-hosted

## Self-Hosting
- Self-hosting PR-Agent requires Docker + LLM API keys
- BYOK (bring your own key) model with OpenAI-compatible endpoints
- LiteLLM proxy support for local models (Ollama, etc.)
- Deployment documentation is available but community-maintained