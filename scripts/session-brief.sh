#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="${CODIAN_VAULT_DIR:-$SCRIPT_DIR/../vault}"
INDEX_FILE="$VAULT_DIR/INDEX.md"
PREFS_FILE="$VAULT_DIR/knowledge/user-profile/preferences.md"
ROLE_FILE="$VAULT_DIR/knowledge/user-profile/role-and-identity.md"
QUERY="${*:-}"

print_section() {
    local title="$1"
    echo
    echo "## $title"
}

summarize_bullets() {
    local file="$1"
    awk '
        /^## / { section=$0 }
        /^- / { print }
    ' "$file" | head -n 8
}

echo "# Codian Session Brief"
echo
echo "Vault: $VAULT_DIR"
echo
awk '
    /^## Recent Updates/ { show=1; count=0; print; next }
    /^## / && show { exit }
    show && count < 6 { print; count++ }
' "$INDEX_FILE"

print_section "User Preferences"
summarize_bullets "$PREFS_FILE"

print_section "User Identity"
summarize_bullets "$ROLE_FILE"

if [ -n "$QUERY" ]; then
    print_section "Query Matches"
    bash "$SCRIPT_DIR/query-memory.sh" --limit 5 "$QUERY"
fi
