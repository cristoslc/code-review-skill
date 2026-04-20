# SPEC-001 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the code-review skill with a JSON-in/JSON-out router architecture, supporting git-ref-diff, multiple platforms, and auto-added synthesis agent.

**Architecture:** Shell-based router (`scripts/route.sh`) receives JSON payload and assembles relevant skill content. SKILL.md orchestrates argument parsing, router invocation, agent dispatch, and report writing. Agent prompts, platform instructions, and diff method guides live in separate files under `agents/`, `platforms/`, and `diff-methods/`.

**Tech Stack:** Shell scripts, git, jq (optional — pure shell fallback), markdown files.

---

## File Structure

```
skills/code-review/
  SKILL.md                       # Orchestration instructions
  scripts/
    route.sh                     # JSON-in, JSON-out router (NEW)
    test_route.sh                # Unit tests for router (NEW)
  agents/
    security.md                  # Security agent prompt (MOVE from agent-prompts.md)
    style.md                     # Style agent prompt (MOVE from agent-prompts.md)
    logic.md                     # Logic agent prompt (MOVE from agent-prompts.md)
    docs.md                      # Documentation agent prompt (MOVE from agent-prompts.md)
    synthesis.md                 # NEW synthesis agent prompt
  platforms/
    forgejo.md                   # Forgejo detection + posting (NEW)
    github.md                    # GitHub detection + posting (NEW)
    local.md                     # Local-only mode (NEW)
  diff-methods/
    git-ref-diff.md              # Git ref diff acquisition (NEW)
```

---

## Task 1: Create Directory Structure

**Files:**
- Create: `skills/code-review/scripts/` (directory)
- Create: `skills/code-review/agents/` (directory)
- Create: `skills/code-review/platforms/` (directory)
- Create: `skills/code-review/diff-methods/` (directory)

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p skills/code-review/scripts
mkdir -p skills/code-review/agents
mkdir -p skills/code-review/platforms
mkdir -p skills/code-review/diff-methods
```

- [ ] **Step 2: Verify directories exist**

```bash
ls -la skills/code-review/scripts/ skills/code-review/agents/ skills/code-review/platforms/ skills/code-review/diff-methods/
```

Expected output: Four empty directories listed.

- [ ] **Step 3: Commit**

```bash
git add skills/code-review/scripts skills/code-review/agents skills/code-review/platforms skills/code-review/diff-methods
git commit -m "chore: create skill directory structure for multi-target code review"
```

---

## Task 2: Extract Agent Prompts to Individual Files

**Files:**
- Read: `skills/code-review/agent-prompts.md` (existing)
- Create: `skills/code-review/agents/security.md`
- Create: `skills/code-review/agents/style.md`
- Create: `skills/code-review/agents/logic.md`
- Create: `skills/code-review/agents/docs.md`

- [ ] **Step 1: Extract security agent prompt**

Read `skills/code-review/agent-prompts.md` and extract the content between `## Security Agent Prompt` and `## Style Agent Prompt` (excluding the Style header). Write to `skills/code-review/agents/security.md`:

```markdown
# Security Code Review Agent

**CRITICAL: You MUST respond ONLY with valid JSON. Do not include any text before or after the JSON. Your entire response must be parseable as JSON.**

You are an expert security code reviewer specializing in identifying vulnerabilities and security issues in pull requests.

## Your Role

Analyze the provided code diff for security vulnerabilities, focusing on:

### OWASP Top 10 Vulnerabilities
- **SQL Injection**: Unsanitized user input in database queries
- **XSS (Cross-Site Scripting)**: Unescaped user input in HTML/JavaScript
- **Authentication Issues**: Weak authentication, missing session validation, insecure password storage
- **Authorization Issues**: Missing access controls, privilege escalation, IDOR (Insecure Direct Object References)
- **Security Misconfiguration**: Default credentials, debug mode enabled, exposed secrets
- **Sensitive Data Exposure**: Unencrypted sensitive data, logging credentials, exposed API keys
- **XML External Entities (XXE)**: Unsafe XML parsing
- **Broken Access Control**: Missing authorization checks, path traversal
- **Command Injection**: Unsafe execution of system commands
- **Insecure Deserialization**: Unsafe deserialization of untrusted data

### Additional Security Concerns
- Hardcoded secrets (API keys, passwords, tokens)
- Unsafe cryptographic practices
- Missing input validation
- Race conditions in security-critical code
- Unsafe file operations (path traversal, file inclusion)
- Missing rate limiting on sensitive endpoints
- Insufficient logging of security events
- Dependency vulnerabilities (known CVEs)

## Do NOT Report

- Observations about what the diff does or how it works
- Summaries of security-related changes ("this adds validation", "this updates auth logic")
- Theoretical risks with no concrete attack path
- Findings where you cannot state the specific vulnerable line and the exploit scenario
- Suggestions that are good practice but not a real vulnerability in this code

If you have no actionable findings, return an empty findings array and status "passed".

## Review Guidelines

1. **Be specific**: Point to exact lines and explain the vulnerability
2. **Provide context**: Explain why it's a security issue
3. **Suggest fixes**: Recommend secure alternatives when possible
4. **Prioritize severity**: Critical issues should be flagged clearly

## Output Format

**IMPORTANT: Your response must be ONLY valid JSON. No markdown code blocks, no explanatory text, no preamble. Just the raw JSON object.**

Your response must match this EXACT schema:

```json
{
  "status": "passed" | "warning" | "failed",
  "findings": [
    {
      "severity": "critical" | "high" | "medium" | "low",
      "title": "Brief title for the issue (one sentence, no period)",
      "description": "Do NOT describe what the diff does or summarize the change. Explain the specific vulnerability: what an attacker can do, how, and what the consequence is. Walk through the concrete attack path. Write plainly: no em-dashes, no 'it's worth noting', no 'leverage', no 'ensure', no 'utilize'. Use commas and short sentences instead.",
      "file": "relative/path/to/file",
      "line": 42,
      "suggested_fix": "Concrete code showing the fix. No backtick fences, no markdown — just the raw code. Show only the changed lines or a minimal complete snippet."
    }
  ],
  "summary": "Overall assessment of security posture"
}
```
```

- [ ] **Step 2: Extract style agent prompt**

Write to `skills/code-review/agents/style.md`:

```markdown
# Code Style Review Agent

**CRITICAL: You MUST respond ONLY with valid JSON. Do not include any text before or after the JSON. Your entire response must be parseable as JSON.**

You are an expert code style reviewer specializing in coding standards and best practices.

## Your Role

Analyze the provided code diff for style issues, focusing on:

### Coding Standards
- **Naming conventions**: Follow the language's idiomatic naming conventions (e.g., camelCase for JS/TS, snake_case for Python/Rust, PascalCase for exported in Go). Use meaningful, intent-revealing names
- **Error handling**: Proper error wrapping, checking all error returns, consistent error types
- **Code formatting**: Consistent indentation, line length, spacing per project style
- **Comments**: Doc comments or JSDoc/docstrings for public functions, types, and constants
- **Imports**: Grouped and organized, no unused imports

### Code Quality
- **Function length**: Functions should be focused and under 50 lines when possible
- **Cyclomatic complexity**: Avoid deeply nested logic
- **Code duplication**: Identify repeated patterns that should be extracted
- **Magic numbers**: Hardcoded values should be named constants
- **Variable scope**: Variables should have minimal scope
- **Early returns**: Prefer early returns over deep nesting

### Idiomatic Patterns (adapt to the language in the diff)
- **Error types**: Use language-appropriate error types and propagation (Result/Option in Rust, errors.go in Go, exceptions in JS/Python)
- **Interface design**: Small, focused interfaces
- **Resource management**: Proper cleanup of files, connections, goroutines/threads
- **Concurrency patterns**: Language-appropriate concurrency idioms
- **Testing conventions**: Follow language-specific testing patterns visible in the repo

## Do NOT Report

- Observations about what the diff does or how it works
- Summaries of changes ("this renames X", "these methods were added")
- Preferences or suggestions the author could reasonably disagree with
- Issues that only apply to code not touched by this diff
- Findings where you cannot state a specific required change
- Anything at the level of "consider" or "might want to"

If you have no actionable findings, return an empty findings array and status "passed".

## Output Format

**IMPORTANT: Your response must be ONLY valid JSON. No markdown code blocks, no explanatory text, no preamble. Just the raw JSON object.**

Your response must match this EXACT schema:

```json
{
  "status": "passed" | "warning" | "failed",
  "findings": [
    {
      "severity": "critical" | "high" | "medium" | "low",
      "title": "Brief title for the issue (one sentence, no period)",
      "description": "Do NOT describe what the diff does or summarize the change. Explain why this specific style issue causes a concrete problem — how it harms readability, creates confusion, or violates a convention with real consequences. Write plainly: no em-dashes, no 'it's worth noting', no 'leverage', no 'ensure', no 'utilize'. Use commas and short sentences instead.",
      "file": "relative/path/to/file",
      "line": 42,
      "suggested_fix": "Concrete code showing the fix. No backtick fences, no markdown — just the raw code. Show only the changed lines or a minimal complete snippet."
    }
  ],
  "summary": "Overall assessment of code style quality"
}
```
```

- [ ] **Step 3: Extract logic agent prompt**

Write to `skills/code-review/agents/logic.md`:

```markdown
# Logic Review Agent

**CRITICAL: You MUST respond ONLY with valid JSON. Do not include any text before or after the JSON. Your entire response must be parseable as JSON.**

You are an expert code reviewer specializing in identifying logical errors, bugs, and correctness issues.

## Your Role

Analyze the provided code diff for logic issues, focusing on:

### Correctness Issues
- **Null/nil/undefined dereferences**: Accessing nil pointers, null references, or undefined values
- **Array/slice bounds**: Index out of bounds errors
- **Off-by-one errors**: Loop boundaries, array indexing
- **Type errors**: Incorrect type assertions, casts, or conversions
- **Logic errors**: Incorrect conditional logic, wrong operators
- **State management**: Race conditions, inconsistent state updates
- **Resource leaks**: Unclosed files, connections, threads/goroutines

### Error Handling
- **Unchecked errors**: Error returns that are ignored
- **Error wrapping**: Errors should provide context
- **Error recovery**: Proper use of panic/recover or try/catch
- **Silent failures**: Errors that are swallowed without logging

### Edge Cases
- **Empty collections**: Handling of empty arrays, maps, objects, strings
- **Boundary conditions**: Min/max values, overflow/underflow
- **Null/nil handling**: Proper null checks before access
- **Concurrent access**: Race conditions in shared data
- **Timeout handling**: Missing or incorrect timeout logic

### Business Logic
- **Algorithm correctness**: Does the code do what it claims?
- **Data validation**: Input validation and sanitization
- **State transitions**: Valid state machine transitions
- **Transaction integrity**: ACID properties maintained
- **Idempotency**: Operations that should be idempotent

### Performance Issues
- **Inefficient algorithms**: O(n²) where O(n) is possible
- **Memory leaks**: Growing collections without cleanup
- **Unnecessary allocations**: Repeated allocations in loops
- **Database N+1 queries**: Multiple queries where one would suffice
- **Missing caching**: Repeated expensive computations

## Do NOT Report

- Observations about what the diff does or how it works
- Summaries of changes ("this method was renamed", "this refactors X")
- Findings where you cannot state a specific action the author must take
- Style preferences or suggestions that don't affect correctness
- Low-confidence suspicions ("this might be an issue if...")
- Anything you would not block a PR over

If you have no actionable findings, return an empty findings array and status "passed".

## Output Format

**IMPORTANT: Your response must be ONLY valid JSON. No markdown code blocks, no explanatory text, no preamble. Just the raw JSON object.**

Your response must match this EXACT schema:

```json
{
  "status": "passed" | "warning" | "failed",
  "findings": [
    {
      "severity": "critical" | "high" | "medium" | "low",
      "title": "Brief title for the issue (one sentence, no period)",
      "description": "Do NOT describe what the diff does or summarize the change. Explain the specific problem: what can go wrong, under what circumstances, and what the consequence is. Walk through the execution path that leads to the bug. Write plainly: no em-dashes, no 'it's worth noting', no 'leverage', no 'ensure', no 'utilize'. Use commas and short sentences instead.",
      "file": "relative/path/to/file",
      "line": 42,
      "suggested_fix": "Concrete code showing the fix. No backtick fences, no markdown — just the raw code. Show only the changed lines or a minimal complete snippet."
    }
  ],
  "summary": "Overall assessment of code correctness"
}
```
```

- [ ] **Step 4: Extract documentation agent prompt**

Write to `skills/code-review/agents/docs.md`:

```markdown
# Documentation Review Agent

**CRITICAL: You MUST respond ONLY with valid JSON. Do not include any text before or after the JSON. Your entire response must be parseable as JSON.**

You are an expert documentation reviewer specializing in code documentation, comments, and developer experience.

## Your Role

Analyze the provided code diff for documentation quality, focusing on:

### Code Documentation
- **Doc comments**: All exported/public functions, types, constants should have documentation
- **Comment quality**: Comments explain "why" not "what"
- **Comment accuracy**: Comments match the code behavior
- **Package/module documentation**: Package-level or module-level documentation
- **Example code**: Complex functions should have usage examples
- **Deprecated markers**: Deprecated code should be marked

### Function Documentation
- **Purpose**: What does the function do?
- **Parameters**: What do parameters represent?
- **Return values**: What is returned and under what conditions?
- **Errors**: What errors can be returned and why?
- **Side effects**: Any side effects or state changes?

### Missing Documentation
- **Undocumented exports**: Public API without documentation
- **Complex logic**: Tricky code without explanatory comments
- **Magic values**: Unexplained constants or configurations
- **Architecture decisions**: Missing design rationale

## Do NOT Report

- Observations about what the diff does or how it works
- Summaries of changes ("this adds a new method", "these are updated tests")
- Suggestions for documentation that would be purely nice-to-have
- Documentation gaps in code not touched by this diff
- Findings where you cannot provide the exact documentation text that is missing
- Comments on internal/private symbols unless the logic is genuinely complex

If you have no actionable findings, return an empty findings array and status "passed".

## Output Format

**IMPORTANT: Your response must be ONLY valid JSON. No markdown code blocks, no explanatory text, no preamble. Just the raw JSON object.**

Your response must match this EXACT schema:

```json
{
  "status": "passed" | "warning" | "failed",
  "findings": [
    {
      "severity": "critical" | "high" | "medium" | "low",
      "title": "Brief title for the issue (one sentence, no period)",
      "description": "Do NOT describe what the issue is in plain language. Do NOT describe what the diff does or summarize the change. Explain specifically what documentation is missing and what confusion or mistake it would prevent. Think about the developer calling this for the first time — what would they get wrong without this comment? Write plainly: no em-dashes, no 'it's worth noting', no 'leverage', no 'ensure', no 'utilize'. Use commas and short sentences instead.",
      "file": "relative/path/to/file",
      "line": 42,
      "suggested_fix": "The concrete documentation text to add — for doc comments, the full comment. No markdown backtick fences around the code examples in comments."
    }
  ],
  "summary": "Overall assessment of documentation quality"
}
```
```

- [ ] **Step 5: Remove old agent-prompts.md**

```bash
rm skills/code-review/agent-prompts.md
```

- [ ] **Step 6: Verify all agent files exist**

```bash
ls -la skills/code-review/agents/
```

Expected: security.md, style.md, logic.md, docs.md

- [ ] **Step 7: Commit**

```bash
git add skills/code-review/agents/ skills/code-review/agent-prompts.md
git commit -m "refactor: extract agent prompts to individual files in agents/"
```

---

## Task 3: Create Synthesis Agent Prompt

**Files:**
- Create: `skills/code-review/agents/synthesis.md`

- [ ] **Step 1: Write synthesis agent prompt**

Write to `skills/code-review/agents/synthesis.md`:

```markdown
# Synthesis Agent

**CRITICAL: You MUST respond ONLY with valid JSON. Do not include any text before or after the JSON. Your entire response must be parseable as JSON.**

You are a synthesis agent that merges findings from multiple code review agents into a single coherent assessment.

## Your Role

Receive findings from security, style, logic, and documentation review agents. Merge, deduplicate, and rank them to produce a final recommendation.

## Input Schema

```json
{
  "agent_results": [
    {
      "agent": "security",
      "status": "passed" | "warning" | "failed",
      "findings": [...],
      "summary": "..."
    },
    ...
  ]
}
```

## Deduplication Rules

Apply these rules to merge findings:

1. **Same file + line + title** → Keep highest severity, merge descriptions.
2. **Similar titles within 3 lines** → Likely same issue, merge into single finding.
3. **Same severity + same root cause** → Merge even if line numbers differ slightly.

## Severity Ranking

Rank findings by severity:
1. `critical` — Must be fixed before merge
2. `high` — Should be fixed before merge
3. `medium` — Address if time permits
4. `low` — Nice to have

## Recommendation Rules

Determine the overall recommendation:

- **`blocked`** — Any `critical` finding exists
- **`needs_changes`** — Any `high` finding exists, OR 2+ `medium` findings, OR any agent status is `failed`
- **`approved`** — No `critical` or `high` findings, all agents `passed` or `warning`

## Output Format

**IMPORTANT: Your response must be ONLY valid JSON.**

```json
{
  "recommendation": "approved" | "needs_changes" | "blocked",
  "findings": [
    {
      "severity": "critical" | "high" | "medium" | "low",
      "title": "Brief title (one sentence, no period)",
      "description": "Clear explanation of the issue and its impact.",
      "file": "relative/path/to/file",
      "line": 42,
      "suggested_fix": "The fix to apply.",
      "source_agents": ["security", "logic"]
    }
  ],
  "summary": "Overall assessment: key issues found, their severity, and recommendation. One paragraph."
}
```
```

- [ ] **Step 2: Verify file exists**

```bash
ls -la skills/code-review/agents/synthesis.md
```

- [ ] **Step 3: Commit**

```bash
git add skills/code-review/agents/synthesis.md
git commit -m "feat: add synthesis agent prompt for merging review findings"
```

---

## Task 4: Create Platform Files

**Files:**
- Create: `skills/code-review/platforms/forgejo.md`
- Create: `skills/code-review/platforms/github.md`
- Create: `skills/code-review/platforms/local.md`

- [ ] **Step 1: Write Forgejo platform file**

Write to `skills/code-review/platforms/forgejo.md`:

```markdown
# Forgejo Platform

## Detection

Detect Forgejo when `git remote get-url origin` contains:
- `forgejo`
- `gitea`
- `codeberg` (runs Forgejo)
- Port `:3000` (common Forgejo default)

## Diff Acquisition

For Forgejo, diffs are always acquired locally via `git diff`. No Forgejo API calls needed for fetching.

## Posting Reviews (Optional)

If the user explicitly asks to post the review to Forgejo:

### Prerequisites
- `FORGEJO_TOKEN` environment variable set with API token
- Token must have `repo` scope

### Posting Steps

1. **Get the PR number** from context or ask user.

2. **Post review summary**:
   ```bash
   curl -X POST \
     -H "Authorization: token $FORGEJO_TOKEN" \
     -H "Content-Type: application/json" \
     "https://forgejo.example.com/api/v1/repos/{owner}/{repo}/pulls/{index}/reviews" \
     -d '{
       "body": "Review summary here",
       "event": "COMMENT" | "APPROVE" | "REQUEST_CHANGES"
     }'
   ```

3. **Post individual comments** (if findings have specific lines):
   ```bash
   curl -X POST \
     -H "Authorization: token $FORGEJO_TOKEN" \
     -H "Content-Type: application/json" \
     "https://forgejo.example.com/api/v1/repos/{owner}/{repo}/pulls/{index}/reviews/{id}/comments" \
     -d '{
       "body": "Finding description",
       "path": "file/path",
       "line": 42
     }'
   ```

### Important
- Only post if user explicitly asks. Default is local report only.
- Never log the token.
- Respect rate limits (Forgejo may be self-hosted with lower limits).
```

- [ ] **Step 2: Write GitHub platform file**

Write to `skills/code-review/platforms/github.md`:

```markdown
# GitHub Platform

## Detection

Detect GitHub when `git remote get-url origin` contains:
- `github.com`
- `github:`

## Diff Acquisition

For GitHub, diffs are always acquired locally via `git diff`. No `gh pr diff` needed for fetching.

## Posting Reviews (Optional)

If the user explicitly asks to post the review to GitHub:

### Prerequisites
- `gh` CLI installed and authenticated (`gh auth status`)

### Posting Steps

1. **Post summary comment**:
   ```bash
   gh pr comment <PR_NUMBER> --body "Review summary here"
   ```

2. **Post inline review comments** (if specific lines):
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/reviews \
     -X POST \
     -f body="Review summary" \
     -f event="COMMENT" \
     -f comments[0][path]=file/path \
     -f comments[0][line]=42 \
     -f comments[0][body]="Finding description"
   ```

### Important
- Only post if user explicitly asks. Default is local report only.
- The `gh` CLI must be authenticated.
```

- [ ] **Step 3: Write local platform file**

Write to `skills/code-review/platforms/local.md`:

```markdown
# Local Platform

## Detection

Detect local when:
- No git remote exists (`git remote` returns empty)
- Remote URL does not match any known forge patterns

## Diff Acquisition

For local-only repos, diffs are acquired via `git diff` commands.

## Posting Reviews

No posting available for local-only mode. Reviews are always written to local files only.

Report location: `~/Downloads/code-review-{timestamp}.md`
```

- [ ] **Step 4: Verify platform files exist**

```bash
ls -la skills/code-review/platforms/
```

Expected: forgejo.md, github.md, local.md

- [ ] **Step 5: Commit**

```bash
git add skills/code-review/platforms/
git commit -m "feat: add platform detection and posting instructions for Forgejo, GitHub, and local"
```

---

## Task 5: Create Diff Method Files

**Files:**
- Create: `skills/code-review/diff-methods/git-ref-diff.md`

- [ ] **Step 1: Write git-ref-diff method file**

Write to `skills/code-review/diff-methods/git-ref-diff.md`:

```markdown
# Git Ref Diff Method

## Purpose

Review changes between two git refs using `git diff`.

## Argument Resolution

The SKILL.md orchestration layer resolves user arguments to actual refs:

| User Input | Resolved Refs |
|------------|--------------|
| (no args) + staged changes | `--cached` |
| (no args) + no staged changes | `main...HEAD` or `trunk...HEAD` |
| `staged` | `--cached` |
| `unstaged` | (working tree changes) |
| `REF` | `REF...HEAD` |
| `REF1 REF2` | `REF1...REF2` |
| `REF1...REF2` | `REF1...REF2` |

## Diff Acquisition Commands

### Staged changes
```bash
git diff --cached
```

### Unstaged changes
```bash
git diff
```

### Two refs
```bash
git diff REF1...REF2
```

### Check if staged changes exist
```bash
git diff --cached --quiet
# Exit code 0 = no staged changes
# Exit code 1 = staged changes exist
```

### Detect default trunk branch
```bash
# Check for main first, then trunk, then master
git rev-parse --verify main 2>/dev/null || \
git rev-parse --verify trunk 2>/dev/null || \
git rev-parse --verify master 2>/dev/null
```

## Diff Size Check

Before sending to agents, check diff size:

```bash
wc -l /tmp/codereview_diff.txt
```

If > 3000 lines:
1. Split into chunks of ~2500 lines
2. Run each agent on each chunk
3. Merge findings before synthesis

## Chunking Command

```bash
split -l 2500 /tmp/codereview_diff.txt /tmp/codereview_chunk_
```

## Output

The diff content should be read via the Read tool (not Bash) to enter agent context.
```

- [ ] **Step 2: Verify diff method file exists**

```bash
ls -la skills/code-review/diff-methods/
```

Expected: git-ref-diff.md

- [ ] **Step 3: Commit**

```bash
git add skills/code-review/diff-methods/
git commit -m "feat: add git-ref-diff method with staged/unstaged/ref-range support"
```

---

## Task 6: Create Router Script

**Files:**
- Create: `skills/code-review/scripts/route.sh`

- [ ] **Step 1: Write route.sh with jq support**

Write to `skills/code-review/scripts/route.sh`:

```bash
#!/bin/bash
# code-review skill router
# JSON-in, JSON-out
# Assembles relevant skill content based on platform, diff-method, and agents

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Read JSON from stdin
INPUT=$(cat)

# Validate JSON
if ! echo "$INPUT" | jq -e . >/devdev/null 2>&1; then
    echo '{"error": "Invalid JSON input", "details": "Input could not be parsed as JSON"}'
    exit 1
fi

# Extract fields
PLATFORM=$(echo "$INPUT" | jq -r '.platform // empty')
DIFF_METHOD=$(echo "$INPUT" | jq -r '.diff_method // empty')
AGENTS=$(echo "$INPUT" | jq -r '.agents // [] | .[]' 2>/dev/null || true)

# Validate required fields
if [[ -z "$PLATFORM" ]]; then
    echo '{"error": "Missing required field", "details": "platform is required"}'
    exit 1
fi

if [[ -z "$DIFF_METHOD" ]]; then
    echo '{"error": "Missing required field", "details": "diff_method is required"}'
    exit 1
fi

if [[ -z "$AGENTS" ]]; then
    echo '{"error": "Missing required field", "details": "agents array is required"}'
    exit 1
fi

# Auto-add synthesis if 2+ agents
AGENT_COUNT=$(echo "$INPUT" | jq '.agents | length')
if [[ "$AGENT_COUNT" -ge 2 ]]; then
    # Check if synthesis already in list
    if ! echo "$INPUT" | jq -e '.agents | contains(["synthesis"])' >/dev/null 2>&1; then
        AGENTS="$AGENTS synthesis"
    fi
fi

# Validate platform file exists
PLATFORM_FILE="$SKILL_DIR/platforms/$PLATFORM.md"
if [[ ! -f "$PLATFORM_FILE" ]]; then
    echo "{\"error\": \"Invalid platform\", \"details\": \"Platform file not found: $PLATFORM.md\"}"
    exit 1
fi

# Validate diff method file exists
DIFF_FILE="$SKILL_DIR/diff-methods/$DIFF_METHOD.md"
if [[ ! -f "$DIFF_FILE" ]]; then
    echo "{\"error\": \"Invalid diff_method\", \"details\": \"Diff method file not found: $DIFF_METHOD.md\"}"
    exit 1
fi

# Validate agent files exist
for agent in $AGENTS; do
    AGENT_FILE="$SKILL_DIR/agents/$agent.md"
    if [[ ! -f "$AGENT_FILE" ]]; then
        echo "{\"error\": \"Invalid agent\", \"details\": \"Agent file not found: $agent.md\"}"
        exit 1
    fi
done

# Read content
ORCHESTRATION=$(cat "$SKILL_DIR/SKILL.md")
PLATFORM_CONTENT=$(cat "$PLATFORM_FILE")
DIFF_CONTENT=$(cat "$DIFF_FILE")

# Build agent prompts JSON
AGENT_JSON="{"
FIRST=true
for agent in $AGENTS; do
    if [[ "$FIRST" == "true" ]]; then
        FIRST=false
    else
        AGENT_JSON="$AGENT_JSON,"
    fi
    CONTENT=$(cat "$SKILL_DIR/agents/$agent.md" | jq -Rs '.')
    AGENT_JSON="$AGENT_JSON\"$agent\": $CONTENT"
done
AGENT_JSON="$AGENT_JSON}"

# Escape content for JSON
ORCHESTRATION_ESCAPED=$(echo "$ORCHESTRATION" | jq -Rs '.')
PLATFORM_ESCAPED=$(echo "$PLATFORM_CONTENT" | jq -Rs '.')
DIFF_ESCAPED=$(echo "$DIFF_CONTENT" | jq -Rs '.')

# Build agent list array
AGENT_ARRAY=$(echo "$AGENTS" | jq -R -s 'split("\n") | map(select(length > 0))')

# Output JSON
cat <<EOF
{
  "orchestration": $ORCHESTRATION_ESCAPED,
  "diff_acquisition": $DIFF_ESCAPED,
  "platform": $PLATFORM_ESCAPED,
  "agent_prompts": $AGENT_JSON,
  "meta": {
    "platform": "$PLATFORM",
    "diff_method": "$DIFF_METHOD",
    "agents": $AGENT_ARRAY
  }
}
EOF
```

- [ ] **Step 2: Make route.sh executable**

```bash
chmod +x skills/code-review/scripts/route.sh
```

- [ ] **Step 3: Commit**

```bash
git add skills/code-review/scripts/route.sh
git commit -m "feat: add route.sh router script with jq support and auto-synthesis"
```

---

## Task 7: Create Router Unit Tests

**Files:**
- Create: `skills/code-review/scripts/test_route.sh`

- [ ] **Step 1: Write test script**

Write to `skills/code-review/scripts/test_route.sh`:

```bash
#!/bin/bash
# Unit tests for route.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROUTE_SH="$SCRIPT_DIR/route.sh"

FAILED=0
PASSED=0

run_test() {
    local name="$1"
    local input="$2"
    local expected="$3"
    
    echo -n "Test: $name... "
    
    if result=$(echo "$input" | "$ROUTE_SH" 2>&1); then
        if echo "$result" | jq -e "$expected" >/dev/null 2>&1; then
            echo "PASS"
            ((PASSED++))
        else
            echo "FAIL: Output did not match expected"
            echo "  Result: $result"
            ((FAILED++))
        fi
    else
        if echo "$result" | jq -e "$expected" >/dev/null 2>&1; then
            echo "PASS (error case)"
            ((PASSED++))
        else
            echo "FAIL: Error case did not match expected"
            echo "  Result: $result"
            ((FAILED++))
        fi
    fi
}

# Test 1: Valid input produces valid JSON
run_test "Valid input produces valid JSON" \
    '{"platform": "local", "diff_method": "git-ref-diff", "agents": ["security", "style"]}' \
    '.orchestration != null and .diff_acquisition != null and .platform != null and .agent_prompts.security != null and .agent_prompts.style != null'

# Test 2: Missing platform returns error
run_test "Missing platform returns error" \
    '{"diff_method": "git-ref-diff", "agents": ["security"]}' \
    '.error == "Missing required field"'

# Test 3: Missing diff_method returns error
run_test "Missing diff_method returns error" \
    '{"platform": "local", "agents": ["security"]}' \
    '.error == "Missing required field"'

# Test 4: Missing agents returns error
run_test "Missing agents returns error" \
    '{"platform": "local", "diff_method": "git-ref-diff"}' \
    '.error == "Missing required field"'

# Test 5: Invalid agent name returns error
run_test "Invalid agent name returns error" \
    '{"platform": "local", "diff_method": "git-ref-diff", "agents": ["invalid-agent"]}' \
    '.error == "Invalid agent"'

# Test 6: Invalid platform returns error
run_test "Invalid platform returns error" \
    '{"platform": "invalid", "diff_method": "git-ref-diff", "agents": ["security"]}' \
    '.error == "Invalid platform"'

# Test 7: Invalid diff_method returns error
run_test "Invalid diff_method returns error" \
    '{"platform": "local", "diff_method": "invalid", "agents": ["security"]}' \
    '.error == "Invalid diff_method"'

# Test 8: Synthesis auto-added when 2+ agents
run_test "Synthesis auto-added when 2+ agents" \
    '{"platform": "local", "diff_method": "git-ref-diff", "agents": ["security", "style"]}' \
    '.meta.agents | contains(["synthesis"])'

# Test 9: Synthesis NOT added when only 1 agent
run_test "Synthesis NOT added when only 1 agent" \
    '{"platform": "local", "diff_method": "git-ref-diff", "agents": ["security"]}' \
    '(.meta.agents | contains(["synthesis"])) == false'

# Test 10: Invalid JSON input returns error
run_test "Invalid JSON input returns error" \
    'not valid json' \
    '.error == "Invalid JSON input"'

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ "$FAILED" -eq 0 ]]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed!"
    exit 1
fi
```

- [ ] **Step 2: Make test script executable**

```bash
chmod +x skills/code-review/scripts/test_route.sh
```

- [ ] **Step 3: Run tests to verify they work**

```bash
cd skills/code-review && ./scripts/test_route.sh
```

Expected: All 10 tests pass (once the files exist).

- [ ] **Step 4: Commit**

```bash
git add skills/code-review/scripts/test_route.sh
git commit -m "test: add unit tests for route.sh router script"
```

---

## Task 8: Rewrite SKILL.md Orchestration

**Files:**
- Modify: `skills/code-review/SKILL.md` (replace entire content)

- [ ] **Step 1: Write new SKILL.md**

Write to `skills/code-review/SKILL.md`:

```markdown
---
name: code-review
description: "Use when reviewing code changes, diffs, or pull requests"
license: MIT
compatibility: "Requires git. Optional: jq for router, gh CLI for GitHub posting."
metadata:
  author: cristoslc
  argument-hint: "[ref1..ref2] [--agents security,style,logic,docs]"
  user-invocable: true
  allowed-tools:
    - Bash
    - Read
    - Write
    - Edit
    - Grep
    - Glob
---

Review code changes using parallel specialized agents. $ARGUMENTS

## Overview

Runs specialized review agents (security, style, logic, documentation) on a git diff, then synthesizes findings into a recommendation.

## When to Use

- User asks to review code changes
- User mentions "code review" or "review this"
- Checking changes before merge
- Reviewing staged or unstaged changes

## When NOT to Use

- General code exploration (not a review)
- Linting or formatting (use language-specific tools)
- Reviews of diffs larger than ~10K lines (agents will miss things)

## Step 0 — Detect Platform and Parse Arguments

### Parse Arguments

1. Extract `--agents` flag if present: `--agents security,style`
2. Remaining arguments are refs for diff:
   - No args: auto-detect (staged if any, else main...HEAD)
   - `staged`: review staged changes
   - `unstaged`: review unstaged changes
   - `REF`: review REF...HEAD
   - `REF1 REF2`: review REF1...REF2
   - `REF1...REF2`: review REF1...REF2

### Detect Platform

```bash
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
```

Platform detection:
- Contains `github.com` or `github:` → `github`
- Contains `forgejo`, `gitea`, or `codeberg` → `forgejo`
- No remote or no match → `local`

Store: `PLATFORM`, `REFS` (array), `AGENTS` (array)

### Detect Default Agents

If `--agents` not specified, default to: `security`, `style`, `logic`, `docs`

## Step 1 — Build Router Payload

Create JSON payload for router:

```json
{
  "platform": "local",
  "diff_method": "git-ref-diff",
  "agents": ["security", "style", "logic"]
}
```

## Step 2 — Invoke Router

```bash
cat payload.json | ./scripts/route.sh > /tmp/router_output.json
```

Parse router output. If error, show error and exit.

## Step 3 — Acquire Diff

Follow `diff_acquisition` instructions from router output.

### Get staged changes

```bash
git diff --cached > /tmp/codereview_diff.txt
```

### Get unstaged changes

```bash
git diff > /tmp/codereview_diff.txt
```

### Get two refs

```bash
git diff REF1...REF2 > /tmp/codereview_diff.txt
```

### Detect trunk branch

```bash
git rev-parse --verify main 2>/dev/null || \
git rev-parse --verify trunk 2>/dev/null || \
git rev-parse --verify master 2>/dev/null
```

### Check diff size

```bash
wc -l /tmp/codereview_diff.txt
```

If > 3000 lines, split into chunks:

```bash
split -l 2500 /tmp/codereview_diff.txt /tmp/codereview_chunk_
```

## Step 4 — Run Review Agents

For each agent in `agent_prompts` (excluding synthesis):

1. Load agent prompt from router output
2. Load diff content via Read tool
3. Dispatch sub-agent with prompt + diff
4. Collect JSON result

Apply JSON parsing fallback:
- Layer 1: Parse as-is
- Layer 2: Strip markdown fences, retry
- Layer 3: Wrap raw output as single `low` finding

Store results in `/tmp/codereview_<agent>_result.json`

## Step 5 — Synthesize

Load all agent results, pass to synthesis agent with `agent_prompts.synthesis` prompt.

Synthesis agent returns:
- `recommendation`: `approved`, `needs_changes`, or `blocked`
- `findings`: merged and deduplicated list
- `summary`: narrative summary

## Step 6 — Write Report

Write markdown report to `~/Downloads/code-review-<timestamp>.md`:

```markdown
# Code Review: REF1...REF2

**Refs:** REF1...REF2
**Platform:** local
**Date:** YYYY-MM-DD

---

## Recommendation: blocked

Summary of findings...

---

### Security — failed

Security findings...

### Style — warning

Style findings...

---

## Finding Counts

| Agent | Critical | High | Medium | Low | Total |
|-------|----------|------|--------|-----|-------|
| security | 1 | 2 | 0 | 1 | 4 |

---

*Generated by code-review — multi-agent code review system*
```

## Step 7 — Optional Posting

If user explicitly asks to post to forge:

Follow `platform` instructions from router output for posting via API.

## Agent Prompts

Agent prompts are loaded dynamically from `agents/*.md` via the router. The router returns only the relevant prompts based on requested agents.

## Common Mistakes

- **Posting without being asked** — Only post if user explicitly asks
- **Running agents sequentially** — Run all agents concurrently
- **Reading diff via Bash** — Use Read tool so diff enters context
- **Accepting non-JSON** — Always apply three-layer parsing fallback
- **Forgetting to split large diffs** — Diffs over 3000 lines must be chunked

## Quick Reference

| Step | Action |
|------|--------|
| 0 | Parse args, detect platform, build router payload |
| 1 | Invoke router: `cat payload | ./scripts/route.sh` |
| 2 | Acquire diff via git commands |
| 3 | Run review agents concurrently |
| 4 | Synthesize findings |
| 5 | Write report to `~/Downloads/` |
| 6 | Optional: post to forge if asked |
```

- [ ] **Step 2: Verify SKILL.md exists**

```bash
ls -la skills/code-review/SKILL.md
```

- [ ] **Step 3: Run router tests to verify end-to-end**

```bash
cd skills/code-review && ./scripts/test_route.sh
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add skills/code-review/SKILL.md
git commit -m "feat: rewrite SKILL.md for multi-target architecture with router"
```

---

## Task 9: Verify Complete Implementation

- [ ] **Step 1: List all files in skill directory**

```bash
find skills/code-review -type f | sort
```

Expected output:
```
skills/code-review/SKILL.md
skills/code-review/agents/docs.md
skills/code-review/agents/logic.md
skills/code-review/agents/security.md
skills/code-review/agents/style.md
skills/code-review/agents/synthesis.md
skills/code-review/diff-methods/git-ref-diff.md
skills/code-review/platforms/forgejo.md
skills/code-review/platforms/github.md
skills/code-review/platforms/local.md
skills/code-review/scripts/route.sh
skills/code-review/scripts/test_route.sh
```

- [ ] **Step 2: Run all router tests**

```bash
cd skills/code-review && ./scripts/test_route.sh
```

Expected: All 10 tests pass.

- [ ] **Step 3: Test router manually**

```bash
echo '{"platform": "local", "diff_method": "git-ref-diff", "agents": ["security", "style"]}' | \
  ./skills/code-review/scripts/route.sh | jq '.meta'
```

Expected output:
```json
{
  "platform": "local",
  "diff_method": "git-ref-diff",
  "agents": ["security", "style", "synthesis"]
}
```

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete multi-target code review skill with router architecture

- JSON-in/JSON-out router (scripts/route.sh)
- 4 review agents + auto-added synthesis agent
- Platform support: Forgejo, GitHub, local
- Diff method: git-ref-diff (staged, unstaged, ref ranges)
- Unit tests for router validation"
```

---

## Success Criteria Verification

- [ ] `route.sh` returns valid JSON for all valid inputs
- [ ] `test_route.sh` passes all 10 test cases
- [ ] All agent prompts exist in `agents/`
- [ ] All platform files exist in `platforms/`
- [ ] Diff method file exists in `diff-methods/`
- [ ] Synthesis agent auto-added when 2+ agents selected
- [ ] SKILL.md references router and new file structure
- [ ] Old `agent-prompts.md` removed
- [ ] No `gh` CLI dependency for diff acquisition
- [ ] Git-based diff acquisition only

## Spec Coverage Check

| Spec Requirement | Plan Task |
|------------------|-----------|
| JSON-in/JSON-out router | Task 6 |
| Auto-add synthesis when 2+ agents | Task 6 (route.sh logic) |
| Platform detection (Forgejo/GitHub/local) | Task 4 |
| Diff method: git-ref-diff | Task 5 |
| Staged/unstaged/ref range support | Task 5 |
| Unit tests for router | Task 7 |
| Remove gh CLI dependency | Task 8 |
| Extract agent prompts to files | Task 2 |
| Create synthesis agent | Task 3 |
| SKILL.md orchestration rewrite | Task 8 |

**All requirements covered.**
