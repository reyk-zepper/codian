#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="${CODIAN_VAULT_DIR:-$SCRIPT_DIR/../vault}"
KNOWLEDGE_DIR="$VAULT_DIR/knowledge"
TODAY="$(date +%Y-%m-%d)"

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

echo "# Codian Session Close"
echo
echo "Date: $TODAY"

TMP_TODAY="$(mktemp)"
trap 'rm -f "$TMP_TODAY"' EXIT

while IFS= read -r file; do
    updated="$(extract_field "$file" "updated")"
    [ "$updated" = "$TODAY" ] || continue
    stem="$(basename "$file" .md)"
    title="$(extract_field "$file" "title")"
    category="$(extract_field "$file" "category")"
    printf '%s\t%s\t%s\n' "$category" "$stem" "$title" >> "$TMP_TODAY"
done < <(list_markdown_files "$KNOWLEDGE_DIR" | grep -v '/_overview\.md$')

echo
echo "## Updated Today"
if [ -s "$TMP_TODAY" ]; then
    LC_ALL=C sort "$TMP_TODAY" | while IFS=$'\t' read -r category stem title; do
        echo "- [[$stem]] | category=$category"
        echo "  $title"
    done
else
    echo "_No notes updated today._"
fi

echo
echo "## Next Checks"
echo "- Run integrity check: \`bash scripts/check-integrity.sh\`"
echo "- Review memory health: \`bash scripts/memory-health.sh\`"
echo "- If project work changed materially, run: \`bash scripts/project-brief.sh <slug>\`"
