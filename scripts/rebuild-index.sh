#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="${CODIAN_VAULT_DIR:-$SCRIPT_DIR/../vault}"
KNOWLEDGE_DIR="$VAULT_DIR/knowledge"
INDEX_FILE="$VAULT_DIR/INDEX.md"
TODAY="$(date +%Y-%m-%d)"

TMP_DIR="$(mktemp -d)"
TMP_PROJECTS="$TMP_DIR/projects"
TMP_DECISIONS="$TMP_DIR/decisions"
TMP_USER_PROFILE="$TMP_DIR/user-profile"
TMP_DOMAIN="$TMP_DIR/domain"
TMP_RECENT="$TMP_DIR/recent"

touch "$TMP_PROJECTS" "$TMP_DECISIONS" "$TMP_USER_PROFILE" "$TMP_DOMAIN" "$TMP_RECENT"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

list_markdown_files() {
    local root="$1"

    if command -v rg >/dev/null 2>&1; then
        (
            cd "$root"
            rg --files -g '*.md' . | LC_ALL=C sort
        ) | sed -e 's#^\./##' -e "s#^#$root/#"
    else
        find "$root" -name "*.md" -print0 | LC_ALL=C sort -z | tr '\0' '\n'
    fi
}

has_frontmatter() {
    local count
    count=$(grep -c '^---' "$1" 2>/dev/null || true)
    [ "$count" -ge 2 ]
}

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

    if ! has_frontmatter "$filepath"; then
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
    printf '%s\t%s\n' "$updated" "$entry" >> "$TMP_RECENT"

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
done < <(list_markdown_files "$KNOWLEDGE_DIR" | tr '\n' '\0')

write_section() {
    local bucket="$1"
    if [ -s "$bucket" ]; then
        cat "$bucket"
    else
        echo "_Noch keine Eintraege._"
    fi
}

write_recent_section() {
    if [ -s "$TMP_RECENT" ]; then
        LC_ALL=C sort -r "$TMP_RECENT" | head -n 5 | cut -f2-
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
    printf '## Recent Updates\n\n'
    write_recent_section
    printf '\n\n'
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
