---
id: kodus-ai-review
url: https://github.com/kodustech/kodus-ai
fetched: 2026-04-19
type: github-repo
license: NOASSERTION (Apache 2.0 core + proprietary EE)
stars: 1049
language: TypeScript
---

# Kodus AI — Open Source AI Code Review

## Overview
Kodus AI is an AI code review platform that offers both cloud and self-hosted deployments. It markets itself as open source with full control over model choice and costs.

## Key Features
- **Model-agnostic**: Use Claude, GPT-5, Gemini, Llama, or any OpenAI-compatible endpoint with zero markup on LLM costs
- **Context learning**: Adapts to your architecture, standards, and workflow
- **Custom rules**: Define review rules in plain language
- **Privacy & Security**: Source code not used to train models, data encrypted in transit and at rest, self-hosted runners supported
- **AST-based engine**: Uses a deterministic, AST-based rule engine (not just LLM) to provide precise, structured context to the LLM
- **Detects rule files**: Automatically detects rule files from Cursor, Copilot, Claude, Windsurf, etc.

## Platform Support
- GitHub, GitLab, Bitbucket, Azure DevOps
- **Forgejo**: Listed in self-hosted deployment configuration ([Railway template](https://railway.com/deploy/kodus-selfhosted))
- Self-hosted via Docker with PostgreSQL (pgvector), MongoDB, and RabbitMQ

## Licensing — Dual License
- **Core**: Apache 2.0
- **Enterprise Edition (EE)**: Proprietary license — all rights retained by Kodus. Production/commercial use of EE code without a valid license is strictly prohibited. You may view, modify, and test EE code locally for evaluation purposes only.
- This is an **open-core model**, not fully open source. The "open source" marketing is misleading.

## Deployment Complexity
- Multi-service stack: Web, API, Worker, and Webhook services
- Requires PostgreSQL (with pgvector extension), MongoDB, and RabbitMQ
- AdamW assessment: "deployment looks complex"
- Self-hosted guide available but involves significant infrastructure

## Critical Notes
- The project claims to be "open source" but uses a dual-license (open core) model. Enterprise features are proprietary.
- Forgejo support exists in self-hosted deployments but is not a primary platform.
- TypeScript codebase adds deployment complexity vs. Python or Go alternatives.
- The review style was critiqued by AdamW as giving a "sloppy vibe."