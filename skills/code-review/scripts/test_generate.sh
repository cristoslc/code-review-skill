#!/bin/bash
# Unit tests for generate.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATE_SH="$SCRIPT_DIR/generate.sh"

FAILED=0
PASSED=0

run_test() {
    local name="$1"
    local input="$2"
    local phase="$3"
    local expected="$4"
    shift 4
    local env_prefix=""

    echo -n "Test: $name... "

    # Build env prefix if extra args are env vars
    local env_args=""
    while [[ $# -gt 0 ]]; do
        env_args="$env_args $1"
        shift
    done

    if result=$(echo "$input" | env $env_args "$GENERATE_SH" --phase "$phase" 2>&1); then
        if echo "$result" | jq -e "$expected" >/dev/null 2>&1; then
            echo "PASS"
            ((PASSED++))
        else
            echo "FAIL: Output did not match expected"
            echo "  Result: $(echo "$result" | head -c 200)"
            ((FAILED++))
        fi
    else
        if echo "$result" | jq -e "$expected" >/dev/null 2>&1; then
            echo "PASS (error case)"
            ((PASSED++))
        else
            echo "FAIL: Error case did not match expected"
            echo "  Result: $(echo "$result" | head -c 200)"
            ((FAILED++))
        fi
    fi
}

PAYLOAD='{"platform": "local", "diff_method": "git-ref-diff", "agents": ["security", "style"]}'
SINGLE_PAYLOAD='{"platform": "local", "diff_method": "git-ref-diff", "agents": ["security"]}'

# ─── Phase validation ─────────────────────────────────────────────────

run_test "Missing --phase returns error" \
    "$PAYLOAD" \
    "" \
    '.error == "Missing --phase argument"'

run_test "Invalid phase returns error" \
    "$PAYLOAD" \
    "nonexistent" \
    '.error == "Invalid phase"'

# ─── Init phase ────────────────────────────────────────────────────────

run_test "Init returns phases array" \
    "$PAYLOAD" \
    "init" \
    '.phases | length == 7'

run_test "Init returns model with maker field" \
    "$PAYLOAD" \
    "init" \
    '.model.maker != null'

run_test "Init returns model with competitor field" \
    "$PAYLOAD" \
    "init" \
    '.model.competitor != null'

run_test "Init returns next_phase as setup" \
    "$PAYLOAD" \
    "init" \
    '.next_phase == "setup"'

run_test "Init competitor differs from maker" \
    "$PAYLOAD" \
    "init" \
    '.model.maker != .model.competitor'

# ─── Model-maker detection ────────────────────────────────────────────

run_test "MODEL_MAKER env var overrides detection" \
    "$PAYLOAD" \
    "init" \
    '.model.maker == "anthropic"' \
    "MODEL_MAKER=anthropic"

run_test "MODEL_IDENTITY heuristic detects openai" \
    "$PAYLOAD" \
    "init" \
    '.model.maker == "openai"' \
    "MODEL_IDENTITY=gpt-4o"

# ─── Setup phase ──────────────────────────────────────────────────────

run_test "Setup returns prompt and diff_acquisition" \
    "$PAYLOAD" \
    "setup" \
    '.prompt != null and .diff_acquisition != null'

run_test "Setup returns platform content" \
    "$PAYLOAD" \
    "setup" \
    '.platform != null'

run_test "Setup returns next_phase as agents" \
    "$PAYLOAD" \
    "setup" \
    '.next_phase == "agents"'

run_test "Setup returns meta with agents" \
    "$PAYLOAD" \
    "setup" \
    '.meta.agents | length > 0'

# ─── Agents phase ─────────────────────────────────────────────────────

run_test "Agents returns agent prompts" \
    "$PAYLOAD" \
    "agents" \
    '.agent_prompts.security != null and .agent_prompts.style != null'

run_test "Agents does not include synthesis in agent_prompts" \
    "$PAYLOAD" \
    "agents" \
    '(.agent_prompts.synthesis // null) == null'

run_test "Agents returns experimental_model" \
    "$PAYLOAD" \
    "agents" \
    '.experimental_model.maker != null and .experimental_model.maker_display != null'

run_test "Agents returns next_phase as synthesize" \
    "$PAYLOAD" \
    "agents" \
    '.next_phase == "synthesize"'

run_test "Agent prompts contain experimental model framing" \
    "$PAYLOAD" \
    "agents" \
    '.agent_prompts.security | test("Experimental Model Context")'

run_test "Agent prompts contain competitor name" \
    "$PAYLOAD" \
    "agents" \
    '.agent_prompts.security | test("experimental language model")'

# ─── Synthesize phase ────────────────────────────────────────────────

run_test "Synthesize returns synthesis prompt" \
    "$PAYLOAD" \
    "synthesize" \
    '.synthesis_prompt != null'

run_test "Synthesize returns next_phase as report" \
    "$PAYLOAD" \
    "synthesize" \
    '.next_phase == "report"'

run_test "Synthesize prompt contains experimental model framing" \
    "$PAYLOAD" \
    "synthesize" \
    '.synthesis_prompt | test("Experimental Model Context")'

run_test "Synthesize returns experimental_model" \
    "$PAYLOAD" \
    "synthesize" \
    '.experimental_model.maker != null'

# ─── Report phase ─────────────────────────────────────────────────────

run_test "Report returns prompt" \
    "$PAYLOAD" \
    "report" \
    '.prompt != null'

run_test "Report returns next_phase as null" \
    "$PAYLOAD" \
    "report" \
    '.next_phase == null'

run_test "Report returns platform content" \
    "$PAYLOAD" \
    "report" \
    '.platform != null'

# ─── Route phase (backward compat) ───────────────────────────────────

run_test "Route returns orchestration and agent_prompts" \
    "$PAYLOAD" \
    "route" \
    '.orchestration != null and .agent_prompts.security != null'

run_test "Route auto-adds synthesis with 2+ agents" \
    "$PAYLOAD" \
    "route" \
    '(.meta.agents | contains(["synthesis"]))'

run_test "Route has diff_acquisition and platform" \
    "$PAYLOAD" \
    "route" \
    '.diff_acquisition != null and .platform != null'

# ─── Validation ──────────────────────────────────────────────────────

run_test "Missing platform returns error on setup" \
    '{"diff_method": "git-ref-diff", "agents": ["security"]}' \
    "setup" \
    '.error == "Missing required field"'

run_test "Missing agents returns error on agents" \
    '{"platform": "local", "diff_method": "git-ref-diff"}' \
    "agents" \
    '.error == "Missing required field"'

run_test "Invalid agent returns error" \
    '{"platform": "local", "diff_method": "git-ref-diff", "agents": ["nonexistent"]}' \
    "agents" \
    '.error == "Invalid agent"'

run_test "Invalid platform returns error" \
    '{"platform": "invalid", "diff_method": "git-ref-diff", "agents": ["security"]}' \
    "agents" \
    '.error == "Invalid platform"'

run_test "Invalid diff_method returns error" \
    '{"platform": "local", "diff_method": "invalid", "agents": ["security"]}' \
    "agents" \
    '.error == "Invalid diff_method"'

# ─── Invalid JSON ────────────────────────────────────────────────────

run_test "Invalid JSON returns error on setup" \
    'not valid json' \
    "setup" \
    '.error == "Invalid JSON input"'

# ─── Auto-synthesis ───────────────────────────────────────────────────

run_test "Synthesis auto-added when 2+ agents" \
    "$PAYLOAD" \
    "agents" \
    '(.meta.agents | contains(["synthesis"]))'

run_test "Single agent does not auto-add synthesis" \
    "$SINGLE_PAYLOAD" \
    "agents" \
    '(.meta.agents | contains(["synthesis"])) == false'

# ─── Phase sequencing ─────────────────────────────────────────────────

run_test "Init next_phase is setup" \
    "$PAYLOAD" \
    "init" \
    '.next_phase == "setup"'

run_test "Setup next_phase is agents" \
    "$PAYLOAD" \
    "setup" \
    '.next_phase == "agents"'

run_test "Agents next_phase is synthesize" \
    "$PAYLOAD" \
    "agents" \
    '.next_phase == "synthesize"'

run_test "Synthesize next_phase is report" \
    "$PAYLOAD" \
    "synthesize" \
    '.next_phase == "report"'

run_test "Report next_phase is null" \
    "$PAYLOAD" \
    "report" \
    '.next_phase == null'

# ─── Full-codebase diff method ─────────────────────────────────────────

FULL_CODEBASE_PAYLOAD='{"platform": "local", "diff_method": "full-codebase", "agents": ["security", "style"]}'

run_test "Full-codebase setup mentions files not diff" \
    "$FULL_CODEBASE_PAYLOAD" \
    "setup" \
    '.prompt | test("files")'

run_test "Full-codebase setup returns diff_acquisition" \
    "$FULL_CODEBASE_PAYLOAD" \
    "setup" \
    '.diff_acquisition != null'

run_test "Full-codebase agents contain full-review framing" \
    "$FULL_CODEBASE_PAYLOAD" \
    "agents" \
    '.agent_prompts.security | test("Full Codebase Review Mode")'

run_test "Full-codebase agents still have experimental model framing" \
    "$FULL_CODEBASE_PAYLOAD" \
    "agents" \
    '.agent_prompts.security | test("Experimental Model Context")'

run_test "Full-codebase agents dispatch mentions source files" \
    "$FULL_CODEBASE_PAYLOAD" \
    "agents" \
    '.prompt | test("source files")'

run_test "Full-codebase route returns diff_acquisition" \
    "$FULL_CODEBASE_PAYLOAD" \
    "route" \
    '.diff_acquisition != null'

run_test "Full-codebase synthesize works" \
    "$FULL_CODEBASE_PAYLOAD" \
    "synthesize" \
    '.synthesis_prompt != null and .next_phase == "report"'

run_test "Full-codebase report works" \
    "$FULL_CODEBASE_PAYLOAD" \
    "report" \
    '.prompt != null and .next_phase == null'

# ─── Dispatch modes ────────────────────────────────────────────────────

SEGMENT_PAYLOAD='{"platform": "local", "diff_method": "full-codebase", "dispatch": "segment", "agents": ["security", "style"]}'

run_test "Segment setup mentions dispatch mode" \
    "$SEGMENT_PAYLOAD" \
    "setup" \
    '.prompt | test("segment")'

run_test "Segment setup meta contains dispatch" \
    "$SEGMENT_PAYLOAD" \
    "setup" \
    '.meta.dispatch == "segment"'

run_test "Segment agents prompt mentions segment-dispatch" \
    "$SEGMENT_PAYLOAD" \
    "agents" \
    '.prompt | test("segment")'

run_test "Segment agents meta contains dispatch" \
    "$SEGMENT_PAYLOAD" \
    "agents" \
    '.meta.dispatch == "segment"'

run_test "Segment synthesize prompt mentions segment" \
    "$SEGMENT_PAYLOAD" \
    "synthesize" \
    '.prompt | test("segment")'

run_test "Segment report meta contains dispatch" \
    "$SEGMENT_PAYLOAD" \
    "report" \
    '.meta.dispatch == "segment"'

run_test "Invalid dispatch returns error" \
    '{"platform": "local", "diff_method": "full-codebase", "dispatch": "invalid", "agents": ["security"]}' \
    "setup" \
    '.error == "Invalid dispatch"'

# ─── Segment-review phase ──────────────────────────────────────────────

SEGMENT_REVIEW_PAYLOAD='{"platform": "local", "diff_method": "full-codebase", "dispatch": "segment", "agents": ["security", "style"], "segment_id": "001"}'

run_test "Segment-review returns prompt" \
    "$SEGMENT_REVIEW_PAYLOAD" \
    "segment-review" \
    '.prompt != null'

run_test "Segment-review contains all specialist rubrics" \
    "$SEGMENT_REVIEW_PAYLOAD" \
    "segment-review" \
    '.prompt | test("Lens: security") and test("Lens: style")'

run_test "Segment-review contains experimental model framing" \
    "$SEGMENT_REVIEW_PAYLOAD" \
    "segment-review" \
    '.prompt | test("Experimental Model Context")'

run_test "Segment-review returns segment_id" \
    "$SEGMENT_REVIEW_PAYLOAD" \
    "segment-review" \
    '.segment_id == "001"'

run_test "Segment-review prompt mentions segment" \
    "$SEGMENT_REVIEW_PAYLOAD" \
    "segment-review" \
    '.prompt | test("Segment Review: 001")'

run_test "Segment-review returns experimental_model" \
    "$SEGMENT_REVIEW_PAYLOAD" \
    "segment-review" \
    '.experimental_model.maker != null'

# ─── Specialist dispatch (default) ──────────────────────────────────────

SPECIALIST_PAYLOAD='{"platform": "local", "diff_method": "full-codebase", "dispatch": "specialist", "agents": ["security", "style"]}'

run_test "Specialist setup meta contains dispatch" \
    "$SPECIALIST_PAYLOAD" \
    "setup" \
    '.meta.dispatch == "specialist"'

run_test "Specialist agents prompt mentions specialist" \
    "$SPECIALIST_PAYLOAD" \
    "agents" \
    '.prompt | test("specialist")'

run_test "Default dispatch is specialist" \
    '{"platform": "local", "diff_method": "full-codebase", "agents": ["security"]}' \
    "setup" \
    '.meta.dispatch == "specialist"'

# ─── Summary ────────────────────────────────────────────────────────

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