---
id: coderabbit-platforms
url: https://docs.coderabbit.ai/platforms
fetched: 2026-04-19
type: web
---

# CodeRabbit — Supported Platforms

## Supported Platforms
- **GitHub** (cloud and GitHub Enterprise Server)
- **GitLab** (cloud and self-managed)
- **Bitbucket** (Cloud)
- **Azure DevOps**

## Explicitly NOT Supported
- **Forgejo** — no integration, no documentation
- **Gitea** — no integration, no documentation. A Gitea issue (#31596) requested CodeRabbit support and was closed.
- **Codeberg** — not listed
- **Pagure** — not listed

## Self-Hosting
- Available only on **Enterprise tier** (Pro Plus) with a minimum of **500 seats**
- Pricing starts at **$15,000/month** for self-hosted deployments
- Requires a license key from CodeRabbit Sales
- Additional AWS infrastructure costs of **$500-8,000+/month** depending on scale
- Self-hosted option runs via Docker on AWS ECS or EKS

## Critical Assessment
CodeRabbit is fundamentally a **SaaS product**. Self-hosting is gated behind enterprise pricing that puts it out of reach for most organizations. The Forgejo/Gitea gaps are significant for self-hosting-oriented teams who have chosen those platforms precisely to avoid vendor lock-in.