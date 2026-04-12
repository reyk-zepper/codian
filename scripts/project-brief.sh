#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="${CODIAN_VAULT_DIR:-$SCRIPT_DIR/../vault}"
KNOWLEDGE_DIR="$VAULT_DIR/knowledge"
PROJECT_SLUG="${1:-}"

usage() {
    echo "Usage: project-brief.sh <project-slug>" >&2
}

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

note_body_excerpt() {
    local file="$1"
    awk '
        /^---/ { count++; next }
        count >= 2 && /^## / { exit }
        count >= 2 { print }
    ' "$file" | sed '/^[[:space:]]*$/d' | head -n 3 | sed 's/^/    /'
}

if [ -z "$PROJECT_SLUG" ]; then
    usage
    exit 1
fi

TMP_RESULTS="$(mktemp)"
trap 'rm -f "$TMP_RESULTS"' EXIT

while IFS= read -r file; do
    if awk '
        /^---/ { count++; if (count == 2) exit; next }
        count == 1 && /^[[:space:]]*-[[:space:]]*project\// {
            line=$0
            sub(/^[[:space:]]*-[[:space:]]*/, "", line)
            print line
        }
    ' "$file" | grep -qx "project/$PROJECT_SLUG"; then
        updated="$(extract_field "$file" "updated")"
        title="$(extract_field "$file" "title")"
        category="$(extract_field "$file" "category")"
        status="$(extract_field "$file" "status")"
        stem="$(basename "$file" .md)"
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$updated" "$stem" "$category" "$status" "$title" "$file" >> "$TMP_RESULTS"
    fi
done < <(list_markdown_files "$KNOWLEDGE_DIR" | grep -v '/_overview\.md$')

echo "# Project Brief: $PROJECT_SLUG"

if [ ! -s "$TMP_RESULTS" ]; then
    echo
    echo "_No notes found for project/$PROJECT_SLUG._"
    exit 0
fi

echo
echo "## Notes"
LC_ALL=C sort -r "$TMP_RESULTS" | while IFS=$'\t' read -r updated stem category status title file; do
    echo "- [[$stem]] | category=$category | status=$status | updated=$updated"
    echo "  $title"
    excerpt="$(note_body_excerpt "$file" || true)"
    [ -n "$excerpt" ] && printf '%s\n' "$excerpt"
done
