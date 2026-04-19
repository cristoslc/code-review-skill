---
id: gitea-forgejo-issue
url: https://github.com/go-gitea/gitea/issues/31596
fetched: 2026-04-19
type: github-issue
---

# Gitea Issue #31596 — Add support for CodeRabbit etc?

## Key Points
- **Closed issue**: Someone requested adding CodeRabbit support to Gitea
- **Implication**: CodeRabbit does not support Gitea (or its fork Forgejo) natively
- CodeRabbit's platform integration requires a webhook handler and API access that only works with the four supported platforms (GitHub, GitLab, Bitbucket, Azure DevOps)
- Gitea/Forgejo users must look to alternatives for AI code review

## Related
- PR-Agent has added Gitea support (docker images include `gitea-app` variant since v0.30)
- auditlm is specifically built for Forgejo
- ai-review (Nikita-Filonov) also supports Gitea