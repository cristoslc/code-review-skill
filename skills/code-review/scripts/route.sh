#!/bin/bash
# route.sh — backward-compatible wrapper
# Delegates to generate.sh --phase route, which produces the same
# JSON output as the original route.sh.
# New consumers should call generate.sh directly with the appropriate phase.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec "$SCRIPT_DIR/generate.sh" --phase route