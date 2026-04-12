#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="${CODIAN_VAULT_DIR:-$SCRIPT_DIR/../vault}"
KNOWLEDGE_DIR="$VAULT_DIR/knowledge"
LIMIT=8
CATEGORY=""
SEARCH_SCOPE="all"

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

usage() {
    cat <<'EOF'
Usage: query-memory.sh [options] <query>

Options:
  --category <name>   Restrict to projects|decisions|user-profile|domain
  --scope <name>      all|title|tags|content
  --limit <n>         Maximum results (default: 8)
EOF
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

extract_tags() {
    local file="$1"
    awk '
        /^---/ { count++; if (count == 2) exit; next }
        count == 1 && /^tags:/ { in_tags=1; next }
        count == 1 && in_tags && /^[[:space:]]*-[[:space:]]*/ {
            line=$0
            sub(/^[[:space:]]*-[[:space:]]*/, "", line)
            print line
            next
        }
        count == 1 && in_tags && $0 !~ /^[[:space:]]/ { in_tags=0 }
    ' "$file" | paste -sd ',' -
}

note_body() {
    local file="$1"
    awk '
        /^---/ { count++; next }
        count >= 2 { print }
    ' "$file"
}

extract_content_excerpt() {
    local file="$1"
    local query="$2"
    note_body "$file" | rg -i -n -m 2 --no-heading "$query" 2>/dev/null \
        | head -n 2 \
        | sed 's/^/    /'
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --scope)
            SEARCH_SCOPE="$2"
            shift 2
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [ "$#" -eq 0 ]; then
    echo "query-memory.sh requires a search query" >&2
    usage >&2
    exit 1
fi

QUERY="$*"
TMP_RESULTS="$(mktemp)"
trap 'rm -f "$TMP_RESULTS"' EXIT

while IFS= read -r file; do
    category="$(extract_field "$file" "category")"
    [ -n "$CATEGORY" ] && [ "$category" != "$CATEGORY" ] && continue

    title="$(extract_field "$file" "title")"
    updated="$(extract_field "$file" "updated")"
    status="$(extract_field "$file" "status")"
    tags="$(extract_tags "$file")"
    stem="$(basename "$file" .md)"
    score=0

    if [[ "$SEARCH_SCOPE" = "all" || "$SEARCH_SCOPE" = "title" ]]; then
        if printf '%s\n%s\n' "$stem" "$title" | rg -qi "$QUERY"; then
            score=$((score + 5))
        fi
    fi

    if [[ "$SEARCH_SCOPE" = "all" || "$SEARCH_SCOPE" = "tags" ]]; then
        if [ -n "$tags" ] && printf '%s\n' "$tags" | rg -qi "$QUERY"; then
            score=$((score + 3))
        fi
    fi

    if [[ "$SEARCH_SCOPE" = "all" || "$SEARCH_SCOPE" = "content" ]]; then
        if note_body "$file" | rg -qi "$QUERY"; then
            score=$((score + 1))
        fi
    fi

    if [ "$score" -gt 0 ]; then
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$score" "$updated" "$stem" "$category" "$status" "$title" "$file" >> "$TMP_RESULTS"
    fi
done < <(list_markdown_files "$KNOWLEDGE_DIR" | grep -v '/_overview\.md$')

if [ ! -s "$TMP_RESULTS" ]; then
    echo "No memory hits for query: $QUERY"
    exit 0
fi

LC_ALL=C sort -t $'\t' -k1,1nr -k2,2r "$TMP_RESULTS" | head -n "$LIMIT" | while IFS=$'\t' read -r score updated stem category status title file; do
    echo "- [[$stem]] | category=$category | status=$status | updated=$updated | score=$score"
    echo "  $title"
    excerpt="$(extract_content_excerpt "$file" "$QUERY" || true)"
    if [ -n "$excerpt" ]; then
        printf '%s\n' "$excerpt"
    fi
done
