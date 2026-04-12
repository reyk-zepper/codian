#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_SLUG="${1:-}"
QUERY="${2:-}"

usage() {
    echo "Usage: work-on-project.sh <project-slug> [query]" >&2
}

strip_leading_title() {
    awk 'BEGIN { skipped=0 }
        !skipped && /^# / { skipped=1; next }
        { print }'
}

if [ -z "$PROJECT_SLUG" ]; then
    usage
    exit 1
fi

echo "# Project Workbench: $PROJECT_SLUG"
echo

echo "## Session Brief"
if [ -n "$QUERY" ]; then
    bash "$SCRIPT_DIR/session-brief.sh" "$QUERY" | strip_leading_title
else
    bash "$SCRIPT_DIR/session-brief.sh" | strip_leading_title
fi

echo
echo "## Project Brief"
bash "$SCRIPT_DIR/project-brief.sh" "$PROJECT_SLUG" | strip_leading_title

echo
echo "## Suggested Next Commands"
echo "- Targeted search: \`bash scripts/query-memory.sh --category domain \"$PROJECT_SLUG\"\`"
echo "- Capture new note: \`bash scripts/capture-note.sh --category decisions --slug <slug> --title \"<title>\"\`"
echo "- Close session: \`bash scripts/close-session.sh\`"
