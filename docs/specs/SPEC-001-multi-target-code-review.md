# SPEC-001: Multi-Target Code Review Skill

## Overview

A multi-target code review skill that supports git ref diffs, worktrees, and unstaged changes via a scripted router. The skill uses a JSON-in/JSON-out architecture where a shell script (`route.sh`) assembles only the relevant content based on the detected platform and diff method.

## Goals

- Support reviewing any git ref range (branches, commits, tags, HEAD~N..HEAD).
- Support reviewing staged and unstaged changes.
- Be platform-agnostic at the core (git-based), with optional forge-specific posting instructions.
- Minimize token cost by only returning relevant skill content via the router.
- Include unit tests for script output validation.

## Non-Goals

- Directory-to-directory diff (not in v1).
- Multi-tenant or team dashboards.
- Replacing CodeRabbit for enterprise use cases.

## Architecture

### File Structure

```
skills/code-review/
  SKILL.md                       # Orchestration instructions
  scripts/
    route.sh                     # JSON-in, JSON-out router
    test_route.sh                # Unit tests for route.sh
  agents/
    security.md                  # Security agent system prompt
    style.md                     # Style agent system prompt
    logic.md                     # Logic agent system prompt
    docs.md                      # Documentation agent system prompt
    synthesis.md                 # Synthesis agent system prompt
  platforms/
    forgejo.md                   # Forgejo detection + posting
    github.md                    # GitHub detection + posting
    local.md                     # Local-only mode
  diff-methods/
    git-ref-diff.md              # Diff acquisition via git refs
```

### Router Script (`scripts/route.sh`)

**Purpose:** Assemble skill content dynamically based on input parameters.

**Input:** JSON via stdin
```json
{
  "platform": "forgejo",
  "diff_method": "git-ref-diff",
  "agents": ["security", "style", "logic"]
}
```

**Logic:**
1. Parse JSON payload.
2. Auto-add `synthesis` to agents list if `agents.length >= 2`.
3. Read content from:
   - `../SKILL.md` (orchestration)
   - `../diff-methods/${diff_method}.md`
   - `../platforms/${platform}.md`
   - `../agents/${agent}.md` for each agent
4. Validate all files exist (error with clear message if not).
5. Output structured JSON.

**Output:** JSON to stdout
```json
{
  "orchestration": "...content of SKILL.md...",
  "diff_acquisition": "...content of git-ref-diff.md...",
  "platform": "...content of forgejo.md...",
  "agent_prompts": {
    "security": "...",
    "style": "...",
    "logic": "...",
    "synthesis": "..."
  },
  "meta": {
    "platform": "forgejo",
    "diff_method": "git-ref-diff",
    "agents": ["security", "style", "logic", "synthesis"]
  }
}
```

**Error Handling:**
- Exit code 0 with valid JSON on success.
- Exit code 1 with JSON error object on failure:
  ```json
  {"error": "Invalid JSON input", "details": "..."}
  ```

### Unit Tests (`scripts/test_route.sh`)

**Test Coverage:**
1. Valid input produces valid JSON output.
2. Missing required fields returns error JSON.
3. Invalid agent names return error JSON.
4. Invalid diff_method returns error JSON.
5. Invalid platform returns error JSON.
6. Synthesis agent auto-added when 2+ agents.
7. Synthesis agent NOT added when only 1 agent.
8. Output JSON contains all expected keys.

**Test Runner:**
```bash
./scripts/test_route.sh
```

Returns exit code 0 with "All tests passed" or exit code 1 with failed test details.

## Diff Methods

### `git-ref-diff`

**Purpose:** Review changes between two git refs.

**Arguments:**
- No args: Auto-detect
  - If staged changes exist → review staged (`git diff --cached`)
  - Else → review `main...HEAD` (or `trunk...HEAD` if `main` doesn't exist)
- One arg: Review `<arg>...HEAD` (or `main...<arg>` depending on context)
- Two args: Review `<arg1>...<arg2>`

**Diff Acquisition:**
```bash
# Staged changes
git diff --cached

# Two refs
git diff <ref1>...<ref2>
```

**Chunking:**
- Diffs > 3000 lines are split into chunks of ~2500 lines.
- Each chunk is reviewed independently by agents.
- Findings are merged before synthesis.

## Platforms

### Detection

The skill detects the platform by sniffing `git remote get-url origin`:

- Contains `github.com` or `github:` → `github`
- Contains `forgejo` or `gitea` → `forgejo`
- No remote or no match → `local`

### Platform Files

**`platforms/forgejo.md`**
- Detection pattern for Forgejo remotes.
- Instructions for posting reviews via Forgejo API.
- Required: `FORGEJO_TOKEN` env var.
- Optional posting steps (only if user explicitly asks).

**`platforms/github.md`**
- Detection pattern for GitHub remotes.
- Instructions for posting reviews via `gh` CLI.
- Required: `gh` CLI authenticated.
- Optional posting steps (only if user explicitly asks).

**`platforms/local.md`**
- No remote detected.
- No posting instructions (reports written to `~/Downloads/` only).

## Agents

### Review Agents (4)

1. **security** — OWASP Top 10, secrets, injection, auth issues.
2. **style** — Naming conventions, error handling, idiomatic patterns.
3. **logic** — Correctness, edge cases, performance, resource leaks.
4. **docs** — Doc comments, comment quality, missing documentation.

**Agent Prompt Structure:**
Each agent prompt file contains:
- Role definition.
- Focus areas (bullet list of what to check).
- Do NOT report list (anti-patterns to avoid).
- Output format (JSON schema).
- Severity guidelines.

### Synthesis Agent (auto-added)

**Purpose:** Merge findings from all review agents, deduplicate, rank by severity.

**Input:** Array of agent results.
**Output:** Single JSON with:
- `recommendation`: `approved`, `needs_changes`, or `blocked`.
- `findings`: Merged, deduplicated, severity-sorted list.
- `summary`: Narrative summary of key issues.

**Deduplication Rules:**
- Same file + line + title → keep highest severity, merge descriptions.
- Similar titles within 3 lines → likely same issue, merge.

## Division of Responsibilities

To avoid ambiguity about what happens where:

| Component | Responsibility |
|-----------|--------------|
| `SKILL.md` orchestration | Parse user arguments, detect platform from git remote, resolve refs (staged, HEAD~3, etc.), build router JSON payload, invoke router, dispatch agents, write report. |
| `scripts/route.sh` | Receive JSON payload, validate inputs, read and inline content from relevant `.md` files, return structured JSON with all skill content. |
| `diff-methods/git-ref-diff.md` | Contains git commands for diff acquisition — `git diff --cached`, `git diff <ref1>...<ref2>`. The orchestration layer substitutes actual refs into these templates. |
| `platforms/*.md` | Platform detection patterns and optional posting instructions for each forge. |
| `agents/*.md` | Agent system prompts that get inlined into sub-agent dispatches. |

## Orchestration Flow

1. **Parse arguments** → SKILL.md detects refs, agents, platform.
2. **Build payload** → JSON with platform, diff_method, agents (refs resolved by SKILL.md).
3. **Invoke router** → `cat payload.json | ./scripts/route.sh`.
3. **Parse router output** → extract orchestration, diff-method, platform, agent prompts.
4. **Acquire diff** → follow diff-method instructions (git commands).
5. **Dispatch agents** → run each review agent concurrently with diff content.
6. **Parse agent results** → apply JSON fallback for invalid output.
7. **Synthesize** → run synthesis agent with all findings.
8. **Write report** → markdown to `~/Downloads/code-review-<timestamp>.md`.
9. **Optional posting** → only if user explicitly asks.

## Error Handling

**Router failures:**
- Agent parses error JSON and presents clear message to user.

**Diff acquisition failures:**
- Git errors surfaced as findings with severity `high`.
- Skill continues with partial or empty diff.

**Agent JSON failures:**
- Layer 1: Parse as-is.
- Layer 2: Strip markdown fences, retry.
- Layer 3: Wrap raw output as single `low` severity finding.

## Security Considerations

- Never post to forge without explicit user approval.
- `FORGEJO_TOKEN` and `GITHUB_TOKEN` are env vars, never logged.
- Diff content may contain secrets — agents are instructed not to log findings to console.

## Testing Strategy

1. **Unit tests:** `scripts/test_route.sh` validates router output.
2. **Integration tests:** Sample repos with known issues, verify agent catch rate.
3. **Manual tests:** Run against own PRs, compare to CodeRabbit free tier quality.

## Migration from Current Skill

Current `skills/code-review/SKILL.md` is GitHub-only via `gh` CLI.

**Changes:**
- Remove all `gh` CLI usage for diff acquisition.
- Replace with `scripts/route.sh` invocation.
- Agent prompts move to `agents/*.md` (content unchanged).
- Add `scripts/`, `platforms/`, `diff-methods/` directories.
- Add synthesis agent prompt (new).

## Open Questions

1. Should the router support a `--list` mode to enumerate available platforms/diff-methods/agents?
2. Should agent prompts include language-specific instructions, or remain language-agnostic?
3. Should findings include a confidence score (0-1) for each agent?

## Dependencies

- `git` — for diff acquisition.
- `jq` — for JSON parsing in `route.sh` (or pure shell fallback).
- `gh` — optional, only for GitHub posting.

## Success Criteria

- [ ] `route.sh` returns valid JSON for all valid inputs.
- [ ] `test_route.sh` passes all 8 test cases.
- [ ] Reviewing staged changes works: `skills/code-review 'staged'`.
- [ ] Reviewing ref range works: `skills/code-review 'main...feature'`.
- [ ] Auto-detect works when no args provided.
- [ ] Report written to `~/Downloads/` contains finding counts table.
- [ ] Synthesis agent runs automatically when 2+ agents selected.
- [ ] No forge posting occurs without explicit user approval.
