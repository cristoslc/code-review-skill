#!/bin/bash
# Unit tests for route.sh

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
