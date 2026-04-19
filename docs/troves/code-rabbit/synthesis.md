# Synthesis: Building a Small-Scale CodeRabbit Equivalent for Forgejo

## The Problem

You run personal projects on a self-hosted Forgejo instance. You want AI-assisted PR review — semantic bug catching, not just linting — without paying CodeRabbit's $15K/month enterprise tax or sending your code to their SaaS. The existing options all have gaps: PR-Agent is community-maintained legacyware with untested Forgejo compat, Kodus is open-core with a brutal deployment stack, auditlm is 31 stars and single-maintainer. What would it actually take to build something suitable?

## What "Suitable" Means for Personal Projects

CodeRabbit's value proposition decomposes into four layers. For personal use, you don't need all of them:

| Layer | CodeRabbit's Version | Minimum Viable for Personal Forgejo |
|---|---|---|
| **1. Forge integration** | Webhook → billing → agent → PR comment | Webhook → agent → PR review comment |
| **2. AI semantic review** | LLM with proprietary prompts, context engineering | LLM with your own prompts, diff + file context |
| **3. Deterministic analysis** | 40+ linters, Semgrep/OpenGrep, pre-merge checks | reviewdog + whatever linters your project already uses |
| **4. Quality gates** | 5 custom pass/fail checks, request-changes workflow | Optional — a failed review comment is enough for personal use |

Layer 3 and 4 are solvable today without writing code (wire reviewdog into Forgejo Actions, point it at your linters). The hard and interesting part is Layer 1 + Layer 2.

## Architecture: The Simplest Thing That Could Work

```
┌──────────┐     webhook      ┌──────────────────┐     API       ┌──────────┐
│  Forgejo  │ ──────────────► │  Review Bot       │ ──────────► │  LLM API │
│           │                 │  (long-running)    │ ◄────────── │          │
│           │ ◄────────────── │                    │             └──────────┘
│           │   POST /reviews │                    │
└──────────┘                 └────────────────────┘
                                      │
                                      │ optional
                                      ▼
                               ┌──────────────┐
                               │  Linters /   │
                               │  reviewdog   │
                               └──────────────┘
```

### Three components, zero orchestration platforms:

**1. Forgejo webhook receiver** — A small HTTP server that:
- Listens for `pull_request` events (opened, synchronize)
- Authenticates webhook payloads via HMAC secret
- Extracts PR diff, changed file list, and base branch

**2. LLM review engine** — A single prompt pipeline that:
- Fetches the PR diff via Forgejo API (`GET /repos/{owner}/{repo}/pulls/{index}.diff`)
- Fetches relevant file contents for context (`GET /repos/{owner}/{repo}/contents/{path}`)
- Constructs a prompt with diff + context + your custom instructions
- Calls an OpenAI-compatible API (could be cloud, could be local Ollama)
- Parses the LLM response into structured review comments

**3. Review poster** — Posts the review via Forgejo API:
- `POST /repos/{owner}/{repo}/pulls/{index}/reviews` with body, event (COMMENT or REQUEST_CHANGES), and comments array
- Each comment maps to a specific file + line from the diff

That's it. No PostgreSQL, no RabbitMQ, no microVM sandboxing, no billing service. For personal projects, you run one process on the same machine as Forgejo (or a $5 VPS) and point a Forgejo webhook at it.

## The Forgejo API Surface (It Exists, It Works)

The key APIs are all present in Forgejo (carried over from Gitea):

| Operation | API | Status |
|---|---|---|
| Get PR diff | `GET /repos/{owner}/{repo}/pulls/{index}.diff` | Works |
| Get file contents | `GET /repos/{owner}/{repo}/contents/{path}?ref={branch}` | Works |
| Create a review | `POST /repos/{owner}/{repo}/pulls/{index}/reviews` | Works |
| Add comments to review | `POST /repos/{owner}/{repo}/pulls/{index}/reviews/{id}/comments` | Works (since Forgejo v7.0) |
| List PR files | `GET /repos/{owner}/{repo}/pulls/{index}/files` | Works |
| Get PR metadata | `GET /repos/{owner}/{repo}/pulls/{index}` | Works |

The API is Swagger-documented at `https://{your-forgejo}/api/swagger`. The Gitea/Forgejo API is compatible enough that PR-Agent's `gitea-app` Docker image likely works against Forgejo unmodified — Adam Williamson's Red Hat team already proved Forgejo webhook integration works with ai-code-review.

## Alternative Architecture: Forgejo Actions Only (No Bot)

If you don't want a long-running process, you can run the entire review inside Forgejo Actions:

```yaml
# .forgejo/workflows/ai-review.yml
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: docker
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Run AI review
        env:
          FORGEJO_TOKEN: ${{ secrets.GITEA_TOKEN }}
          LLM_API_KEY: ${{ secrets.LLM_API_KEY }}
          PR_INDEX: ${{ github.event.pull_request.number }}
          REPO: ${{ github.repository }}
        run: |
          pip install requests
          python3 /path/to/review_script.py
```

This is exactly what Adam Williamson did with ai-code-review at Codeberg. The trade-off: Actions run on every push to the PR (no debounce), you pay for runner time, and the review can't be triggered by @mention (it's push-based). But for personal projects with low PR volume, this is simpler than running a bot.

## Prompt Design: Where CodeRabbit's Black Box Meets Your Open One

CodeRabbit's prompts are proprietary. This is actually an advantage for a DIY tool: you can iterate on prompts in the open, test them against your own code, and tune the nitpickiness level.

Based on what CodeRabbit publicly describes (and what PR-Agent publishes), the effective prompt structure is:

```python
REVIEW_PROMPT = """You are a code reviewer for a {language} project.

## PR Description
{pr_title}
{pr_body}

## Changed Files
{changed_files_list}

## Diff
{diff_content}

## File Context (surrounding code for changed files)
{file_contexts}

## Review Instructions
{custom_instructions}

## Output Format
For each issue found, output a JSON object:
- "path": file path relative to repo root
- "line": line number in the diff (1-indexed from diff hunk start)
- "severity": "critical" | "warning" | "info"
- "message": plain text explanation of the issue
- "suggestion": optional code suggestion to fix the issue

Only report genuine issues. Do not comment on style preferences, 
documentation, or trivial naming. Focus on bugs, security issues,
logic errors, and performance problems.
"""
```

Key design decisions:

1. **How much context to include**: CodeRabbit claims 1:1 code-to-context. For personal projects, fetching the full file for each changed file (not just the diff) is usually sufficient and fits within typical context windows (128K tokens for Claude, 200K for GPT-4). You don't need CodeRabbit's "dozens of data points" for a 3-file personal PR.

2. **Custom instructions**: The `.coderabbit.yaml` equivalent is a simple text file in the repo root. Path-based glob matching is 20 lines of Python.

3. **Debouncing**: CodeRabbit debounces pushes (reviews after a quiet period). For a personal bot, a simple 30-60 second sleep after receiving the webhook, then checking if the PR head SHA still matches, is sufficient.

4. **Deterministic layer**: Don't reinvent linter orchestration. Run reviewdog (or just your project's existing linters) as a separate Forgejo Actions workflow. The AI bot and linting workflow post independent review comments. This is exactly how CodeRabbit works (two parallel systems), except you can see and control both.

## Existing Code to Start From

You don't need to write this from scratch:

| Starting Point | Language | Forgejo Support | Effort to Adapt |
|---|---|---|---|
| **auditlm** | Rust | Native (webhook bot) | Low — already works, just needs prompt tuning and maybe Ollama config |
| **ai-code-review** (Red Hat) | Python | Forgejo MR submitted | Low — add the MR branch, point at your Forgejo |
| **PR-Agent** (Qodo) `gitea-app` image | Python | Gitea (compatible with Forgejo API) | Medium — test against Forgejo, fix any API incompatibilities, write custom prompts |
| **ai-review** (Nikita-Filonov) | Python | Gitea listed | Medium — similar to PR-Agent approach |
| **Roll your own** | Any | N/A | High — but you control everything |

### Recommended path for personal projects:

**Fastest to working**: Use **auditlm**. It's Forgejo-native, Rust-based, uses local LLMs via OpenAI-compatible endpoints. Clone it, configure your Forgejo URL and Ollama endpoint, run it. The prompts are in the source code and can be edited. At 31 stars it's early, but for personal projects that's fine — you're not relying on it for enterprise SLAs.

**Most flexible**: Use **ai-code-review** (Red Hat) with the Forgejo integration MR. Python, typed, well-tested, modular. Supports Ollama natively. The Forgejo MR exists but isn't merged — use the MR branch. This gives you the cleanest prompt code to hack on.

**Most mature (if you accept Gitea compat)**: Run **PR-Agent** with the `gitea-app` Docker image against your Forgejo. The Gitea API is Forgejo's parent fork; the review API endpoints are compatible. Prompts are in `pr_agent/settings/` as configuration files. The risk is that PR-Agent is in community-maintenance mode, so bugs may linger. But it has 10K+ stars and years of production use.

## What You'd Be Missing vs. CodeRabbit

| Feature | Can you replicate it? | Effort |
|---|---|---|
| AI semantic review | Yes — same LLM APIs, your own prompts | Low |
| Inline PR review comments | Yes — Forgejo API supports this | Low |
| PR summary / walkthrough | Yes — one more prompt call | Low |
| Deterministic linters | Yes — reviewdog + your existing linter config | Low |
| Custom review instructions | Yes — `.reviewer.yaml` in repo root | Low |
| Path-based glob instructions | Yes — 20 lines of Python | Low |
| Context beyond diff (ticketing, wikis) | Partial — Forgejo Issues API, but no Jira/Confluence | Medium |
| Pre-merge quality gates | Partial — Forgejo status checks + Actions, but no "request changes" auto-block without branch protection rules | Medium |
| Debounced reviews | Yes — simple sleep + SHA check | Low |
| @mention-triggered reviews | Yes — filter webhook events by comment body | Low |
| Sandboxed code execution | No — and you don't need it for personal projects | N/A |
| Multi-repo dashboard / analytics | No — would need a separate webapp | High |
| Skills system for 35+ agents | No — CodeRabbit-specific architecture | N/A |
| Auto-fix suggestions | Yes — LLM can generate fix patches, post as suggestions | Medium |
| Incremental review (only new changes) | Yes — diff already contains only changes | None (free) |

The things you actually can't replicate cheaply are the **dashboard/analytics** and the **skills system**. For personal projects, neither matters. The dashboard is for team leads tracking review metrics. The skills system is CodeRabbit's distribution moat, not a review feature.

## Cost Model

For personal projects on Forgejo:

| Component | Cost |
|---|---|
| Forgejo | Free (self-hosted) |
| LLM API (cloud) | ~$0.01-0.10 per review (GPT-4o-mini or Claude Haiku) |
| LLM API (local) | Free (Ollama + open-weight model, needs ~8GB VRAM) |
| Hosting the bot | $0 (runs on same machine as Forgejo) or $5/month VPS |
| reviewdog + linters | Free (open source) |

**Total: $0-5/month** vs. CodeRabbit's $0 (free tier, GitHub only, rate-limited) or $24/seat/month (Pro).

## The Forgejo Gap Is Real (But Solvable)

No mainstream AI review tool treats Forgejo as a first-class platform. The API surface exists and works — `POST /repos/{owner}/{repo}/pulls/{index}/reviews` creates reviews, webhook payloads fire on PR events, and the Gitea compatibility layer means existing Gitea integrations probably work. The gap is integration effort, not API limitations.

For personal projects, the gap is small: you need one small bot process or one Forgejo Actions workflow. The hardest part isn't the Forgejo integration — it's writing good review prompts. And that's where having access to PR-Agent's published prompts (`pr_agent/settings/`) and CodeRabbit's dead OSS project's prompts (`coderabbitai/ai-pr-reviewer/src/prompts.ts`) gives you a massive head start.

## Rough Implementation Timeline

| Week | Milestone |
|---|---|
| 1 | Stand up bot: webhook receiver + Forgejo API auth + diff fetch + post review comment. No AI yet — just confirm the Forgejo integration works end-to-end with hardcoded review text. |
| 2 | Wire in LLM: diff → prompt → LLM API → parse response → post structured review comments. Iterate on prompt quality against your own repos. |
| 3 | Add config: `.reviewer.yaml` with custom instructions, path globs, severity thresholds. Add reviewdog as a parallel Actions workflow for deterministic checks. |
| 4 | Polish: @mention triggering, debouncing, auto-fix suggestions, error handling. Write a Docker Compose file for the bot. |

Four weeks of evenings for a working personal CodeRabbit on Forgejo. The codebase would be ~500-1000 lines of Python (or ~1000 lines of Rust if starting from auditlm). No PostgreSQL, no RabbitMQ, no $15K/month license.