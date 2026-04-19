---
id: adamw-blog-oss-assessment
url: https://www.happyassassin.net/posts/2025/12/16/a-half-assed-assessment-of-open-source-ai-code-review-tools/
fetched: 2026-04-19
type: web
---

# A Half-Assed Assessment of Open Source AI Code Review Tools

## Author
Adam Williamson (Red Hat)

## Key Findings

### ai-code-review
- Author: Juanje Ojeda (Red Hat)
- Language: Python (typed), modular architecture
- Forges: GitLab, GitHub, local changes (Forgejo support submitted as MR)
- Model providers: Gemini, Anthropic, Ollama
- Deployment: Local execution, GitLab CI, GitHub Actions
- Status: Active (since August 2025)
- Prompts: Open, available in repo

### ai-codereview
- Author: Tuvya Korol (Red Hat internal)
- Language: Python (untyped), monolithic architecture
- No tests. Uses RH-internal model providers.
- Forges: GitLab, local changes only

### kodus-ai
- Language: TypeScript, modular architecture
- Forges: GitHub, GitLab, BitBucket (no Forgejo)
- Model providers: OpenAI, Gemini, Anthropic, Novita, OpenRouter, any OpenAI-compatible
- Deployment: Complex — containerized webapp with PostgreSQL, MongoDB, RabbitMQ
- Assessment: "deployment looks complex, and from what I've seen I don't love its review style. Hard to say why but the project overall gives me a sloppy vibe"
- Status: Active

### pr-agent (Qodo/CodiumAI)
- Language: Python (untyped), modular architecture
- Forges: GitHub, GitLab, **Gitea**, Gerrit, BitBucket, AWS CodeCommit, Azure DevOps, local changes
- Model providers: Any OpenAI-compatible (Azure special handling), LiteLLM
- Status: **Archived November 2025** (now a "community-maintained legacy project")
- Assessment: "Had the longest development history and seems the most mature and capable at the point where it was abandoned (well, they actually seem to have done a heel turn and gone closed source / SaaS). It has a documented standalone deployment process which looks relatively simple"
- License: Apache 2.0 (but note: archived, community-maintained legacy)

### ai-pr-reviewer (CodeRabbit)
- Language: TypeScript, modular
- Forges: GitHub only
- Model providers: OpenAI only
- Status: **Archived November 2023**
- Assessment: "very tied to GitHub, has no documented standalone deployment ability, and was archived fairly early in development"
- Prompts: Available in repo but project is dead

### Overall Assessment
- **Best options**: ai-code-review (Red Hat) and pr-agent (Qodo, but archived)
- **Forgejo support**: ai-code-review has a submitted MR; pr-agent has Gitea support which is close but not Forgejo-specific
- **Kodus**: Active but complex deployment, sloppy vibe
- **Reviewdog**: Not assessed (not AI-powered)
- **ai-pr-reviewer (CodeRabbit)**: Dead, GitHub-only

## Critical Notes
- The author successfully integrated ai-code-review with Forgejo Actions and tested it at Codeberg
- Long-term hope: use a Fedora-hosted LLM provider serving open source models
- pr-agent license is AGPL-3.0 (not Apache 2.0 as some sources claim — see GitHub license field)
- Kodus has dual licensing: Apache 2.0 for core, proprietary EE license for enterprise features