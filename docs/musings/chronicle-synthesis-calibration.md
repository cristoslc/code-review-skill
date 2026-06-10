# Chronicle: Synthesis Agent Calibration Fix

**Date:** 2026-06-10
**Issue:** https://github.com/cristoslc/code-review-skill/issues/2
**PR:** https://github.com/cristoslc/code-review-skill/pull/3

## Summary

Fixed the synthesis agent prompt to require `needs_changes` on any single actionable `medium` finding instead of requiring 2+ medium findings.

## What Happened

1. Issue #2 reported that the synthesis agent returned `APPROVE WITH MINOR FIXES` despite actionable medium-severity findings.
2. The root cause was in `skills/code-review/agents/synthesis.md` — the `needs_changes` rule required 2+ medium findings, and `approved` only checked for critical/high.
3. A sashay was executed: branch `fix/synthesis-calibration`, worktree, subagent dispatch.
4. Subagent applied two targeted edits: severity description updated, recommendation rules tightened.
5. Draft PR #3 created with the fix.

## Changes

- **`medium` severity:** "Address if time permits" → "Should be fixed — actionable and meaningful"
- **`needs_changes`:** triggers on any single `medium` finding (was 2+)
- **`approved`:** requires no critical, high, or medium findings (was only critical/high)