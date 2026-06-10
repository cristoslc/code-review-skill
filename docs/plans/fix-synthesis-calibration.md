# Fix Synthesis Agent Calibration

**Issue:** https://github.com/cristoslc/code-review-skill/issues/2

## Problem

The synthesis agent prompt in `agents/synthesis.md` lets a single `medium` actionable finding slip through to `approved` instead of triggering `needs_changes`. The rubric requires "2+ medium" for `needs_changes`, but any actionable medium finding should block approval.

## Fix

Two changes to `skills/code-review/agents/synthesis.md`:

1. **Recommendation rules** — Change `needs_changes` to trigger on **any** `medium`+ finding (not 2+):
   - `blocked` — Any `critical` finding
   - `needs_changes` — Any `high` **OR any `medium`** finding, OR any agent status is `failed`
   - `approved` — No `critical`, `high`, or `medium` findings (only `low`/`info`)

2. **Severity ranking** — Update `medium` description from "Address if time permits" to "Should be fixed — actionable and meaningful" to match the stricter threshold.

## Files

- `skills/code-review/agents/synthesis.md` — update severity ranking + recommendation rules