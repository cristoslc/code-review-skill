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
if ! echo "$INPUT" | jq -e . >/dev/null 2>&1; then
    echo '{"error": "Invalid JSON input", "details": "Input could not be parsed as JSON"}'
    exit 1
fi

# Extract fields
PLATFORM=$(echo "$INPUT" | jq -r '.platform // empty')
DIFF_METHOD=$(echo "$INPUT" | jq -r '.diff_method // empty')

# Validate required fields
if [[ -z "$PLATFORM" ]]; then
    echo '{"error": "Missing required field", "details": "platform is required"}'
    exit 1
fi

if [[ -z "$DIFF_METHOD" ]]; then
    echo '{"error": "Missing required field", "details": "diff_method is required"}'
    exit 1
fi

# Get agent count and validate agents exist
AGENT_COUNT=$(echo "$INPUT" | jq '.agents | length')
if [[ "$AGENT_COUNT" -eq 0 ]]; then
    echo '{"error": "Missing required field", "details": "agents array is required"}'
    exit 1
fi

# Build agent list as newline-separated string (for iteration)
AGENTS=$(echo "$INPUT" | jq -r '.agents // [] | .[]' 2>/dev/null || true)

# Auto-add synthesis if 2+ agents
if [[ "$AGENT_COUNT" -ge 2 ]]; then
    # Check if synthesis already in list
    if ! echo "$INPUT" | jq -e '.agents | contains(["synthesis"])' >/dev/null 2>&1; then
        AGENTS="$AGENTS
synthesis"
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
