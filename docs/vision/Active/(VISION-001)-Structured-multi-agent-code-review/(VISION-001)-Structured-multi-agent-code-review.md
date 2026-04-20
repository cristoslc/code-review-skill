---
title: "Structured multi-agent code review"
artifact: VISION-001
track: standing
status: Active
product-type: personal
author: cristoslc
created: 2026-04-19
last-updated: 2026-04-19
priority-weight: high
depends-on-artifacts: []
evidence-pool: ""
---

# Structured multi-agent code review

## Target Audience

Developers who want better code review than a single LLM pass provides — especially solo developers and small teams on self-hosted forges (Forgejo, Gitea) where commercial AI review tools (CodeRabbit, Qodo Merge) are unavailable or prohibitively expensive.

## Problem Statement

Single-pass LLM code review is noisy. It catches some bugs but misses entire categories (security, style violations, missing docs) or overreports trivia. Existing tools either lock you into a SaaS (CodeRabbit), are community-maintained legacyware (PR-Agent), or require massive infrastructure (Kodus). None natively support Forgejo.

## Existing Landscape

- **CodeRabbit**: Best-in-class UX, but proprietary SaaS. Self-hosting starts at $15K/month. No Forgejo support.
- **PR-Agent (Qodo)**: AGPL-3.0, community-maintained legacy. Has Gitea support (Forgejo compat untested). Prompts are published and reusable.
- **Kodus AI**: Open-core (not truly open source). Complex deployment stack (PostgreSQL, MongoDB, RabbitMQ).
- **auditlm**: Only Forgejo-native option. AGPL-3.0, Rust, 31 stars, single maintainer.
- **reviewdog**: Gold standard for deterministic linter routing (MIT, 9.2K stars). Not AI-powered.
- **DIY**: Wire up any LLM to Forgejo Actions (proven by Red Hat's ai-code-review at Codeberg).

## Build vs. Buy

Priority: (2) glue-code existing tools. The building blocks exist — reviewdog for deterministic checks, PR-Agent's published prompts for LLM review, Forgejo's PR review API — but no one has assembled them into a coherent personal-scale system. Building from scratch would be ~500-1000 lines of Python; extending auditlm or ai-code-review is less.

## Maintenance Budget

Low. This is a personal utility, not a product. It should run unattended on a $5 VPS or the same machine as Forgejo, with no database dependencies. Prompt iteration is the main ongoing cost.

## Success Metrics

- Reviews post automatically on PR open/push in Forgejo
- Review quality is competitive with CodeRabbit's free tier (measured by bug catch rate on own repos)
- Zero per-month operational cost when using local LLMs
- Deterministic linting runs as a parallel Forgejo Actions workflow

## Non-Goals

- Multi-tenant hosting or team dashboards
- Supporting GitHub/GitLab (Forgejo-first, though the architecture shouldn't prevent it)
- Replacing CodeRabbit for enterprise use cases
- Building a SaaS or commercial product

## Lifecycle

| Phase | Date | Commit | Notes |
|-------|------|--------|-------|
| Active | 2026-04-19 | -- | Initial creation from README seed