#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="$SCRIPT_DIR/../vault"
KNOWLEDGE_DIR="$VAULT_DIR/knowledge"
INDEX_FILE="$VAULT_DIR/INDEX.md"
TODAY="$(date +%Y-%m-%d)"

TMP_DIR="$(mktemp -d)"
TMP_PROJECTS="$TMP_DIR/projects"
TMP_DECISIONS="$TMP_DIR/decisions"
TMP_USER_PROFILE="$TMP_DIR/user-profile"
TMP_DOMAIN="$TMP_DIR/domain"

touch "$TMP_PROJECTS" "$TMP_DECISIONS" "$TMP_USER_PROFILE" "$TMP_DOMAIN"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

extract_field() {
    local file="$1"
    local field="$2"
    awk -v field="$field" '
        /^---/ { count++; if (count == 2) exit; next }
        count == 1 {
            if (match($0, "^" field ":[ \t]*(.+)$")) {
                val = substr($0, RSTART + length(field) + 1)
                gsub(/^[ \t]+/, "", val)
                gsub(/^"/, "", val)
                gsub(/"$/, "", val)
                print val
                exit
            }
        }
    ' "$file"
}

ERRORS=0

while IFS= read -r -d '' filepath; do
    basename_file="$(basename "$filepath")"

    if [ "$basename_file" = "_overview.md" ]; then
        continue
    fi

    if ! grep -q '^---' "$filepath"; then
        echo "WARNING: $filepath has no frontmatter - skipping" >&2
        ERRORS=$((ERRORS + 1))
        continue
    fi

    title="$(extract_field "$filepath" "title")"
    category="$(extract_field "$filepath" "category")"
    status="$(extract_field "$filepath" "status")"
    updated="$(extract_field "$filepath" "updated")"

    if [ -z "$title" ] || [ -z "$category" ] || [ -z "$updated" ] || [ -z "$status" ]; then
        echo "WARNING: $filepath is missing required frontmatter fields - skipping" >&2
        ERRORS=$((ERRORS + 1))
        continue
    fi

    wikilink="${basename_file%.md}"
    entry="- [[$wikilink]] - $title (updated: $updated, status: $status)"

    case "$category" in
        projects) echo "$entry" >> "$TMP_PROJECTS" ;;
        decisions) echo "$entry" >> "$TMP_DECISIONS" ;;
        user-profile) echo "$entry" >> "$TMP_USER_PROFILE" ;;
        domain) echo "$entry" >> "$TMP_DOMAIN" ;;
        *)
            echo "WARNING: $filepath has unknown category '$category' - skipping" >&2
            ERRORS=$((ERRORS + 1))
            ;;
    esac
done < <(find "$KNOWLEDGE_DIR" -name "*.md" -print0 | sort -z)

write_section() {
    local bucket="$1"
    if [ -s "$bucket" ]; then
        cat "$bucket"
    else
        echo "_Noch keine Eintraege._"
    fi
}

{
    printf '%s\n' '---'
    printf 'title: "Codian Index"\n'
    printf 'updated: %s\n' "$TODAY"
    printf '%s\n' '---'
    printf '\n'
    printf '# Index\n\n'
    printf 'Zentraler Einstiegspunkt fuer Codex'\'' Wissens-Vault. Bei jedem Session-Start lesen.\n\n'
    printf '## Projects\n\n'
    write_section "$TMP_PROJECTS"
    printf '\n\n## Decisions\n\n'
    write_section "$TMP_DECISIONS"
    printf '\n\n## User Profile\n\n'
    write_section "$TMP_USER_PROFILE"
    printf '\n\n## Domain\n\n'
    write_section "$TMP_DOMAIN"
    printf '\n'
} > "$INDEX_FILE"

echo "INDEX.md rebuilt at $INDEX_FILE"

if [ "$ERRORS" -gt 0 ]; then
    echo "$ERRORS file(s) skipped due to warnings" >&2
fi
