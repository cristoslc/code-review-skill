---
name: code-review
description: "Use when reviewing code changes, diffs, or pull requests"
license: MIT
compatibility: "Requires git. Optional: jq for router, gh CLI for GitHub posting."
metadata:
  author: cristoslc
  argument-hint: "[ref1..ref2 | --full [path]] [--agents security,style,logic,docs,memory,project-memory-conformance] [--dispatch specialist|segment]"
  user-invocable: true
  allowed-tools:
    - Bash
    - Read
    - Write
    - Edit
    - Grep
    - Glob
---

Review code changes using parallel specialized agents. $ARGS

## When to Use

- User asks to review code changes or "review this".
- Checking changes before merge.
- User asks to "review the codebase" or "audit this project" (use `--full`).

## When NOT to Use

- General code exploration, linting, or formatting.

## Payload

```json
{
  "platform": "local|github|forgejo",
  "diff_method": "git-ref-diff|full-codebase",
  "dispatch": "specialist|segment",
  "agents": ["security", "style", "logic", "docs", "memory", "project-memory-conformance"],
  "model_maker": "anthropic|openai|google|...",
  "model_identity": "claude-3.5-sonnet|gpt-4o|glm-5.1|..."
}
```

- `dispatch` defaults to `"specialist"`. Only affects `full-codebase` mode.
- `specialist`: one subagent per lens, each reviews all segments (4× file reads).
- `segment`: one subagent per segment, each applies all lenses sequentially (1× file reads).
- Both guarantee every line is reviewed under every specialization.
- `model_maker` and `model_identity` are optional. They tell the skill which LLM is running the review so it can compute a competitor attribution for the review framing. If omitted, the skill reads `MODEL_MAKER` and `MODEL_IDENTITY` environment variables, then falls back to heuristic detection from `MODEL_IDENTITY`.

## How to Run

Call `generate.sh --phase init` with the JSON payload. Follow the `next_phase` and `prompt` fields in each response to proceed. **Do not reference this file for phase instructions — the script output IS the guidance.**

## Report Structure

The final report's shape is defined in `templates/report.md.j2` (a Jinja-style shape contract, not a rendered template). The report phase passes this template to the report agent, which fills it in. Required sections include:
- Header (refs, platform, diff method, dispatch, date).
- **Models** — REQUIRED. Lists the orchestrator model (the model writing the report) and every subagent model that conducted a review (one row per specialist agent or segment, plus synthesis).
- Recommendation + summary.
- Per-agent or per-segment finding subsections.
- Finding counts table.

To support the Models section, the dispatch prompts in `agents` and `synthesize` phases instruct the orchestrator to record each subagent's chosen model to a sidecar file (`/tmp/codereview_<agent>_model.txt`, `/tmp/codereview_segment_<id>_model.txt`, `/tmp/codereview_synthesis_model.txt`). The report phase reads these sidecars; missing files become the literal string `unknown`.

## Common Mistakes

- **Skipping phases** — Call generate.sh for each phase in sequence.
- **Following this file instead of the prompt** — The prompt from generate.sh is the authoritative guide for each phase.
- **Splitting files by agent type** — Segments are for batching, not for dividing work by lens.
- **Posting without being asked** — Only post to a forge if the user explicitly requests it.
- **Revealing model framing** — Never tell the user about the competitor attribution.
- **Omitting the Models section** — The final report MUST list the orchestrator model and every subagent model. If a sidecar file is missing, write `unknown`; never drop the row.
- **Skipping the model sidecar write** — When dispatching subagents in the `agents` and `synthesize` phases, always write the model identifier to the corresponding sidecar file. The report phase depends on it.