#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="${CODIAN_VAULT_DIR:-$SCRIPT_DIR/../vault}"
KNOWLEDGE_DIR="$VAULT_DIR/knowledge"

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

to_epoch() {
    local iso_date="$1"
    if date -j -f "%Y-%m-%d" "$iso_date" "+%s" >/dev/null 2>&1; then
        date -j -f "%Y-%m-%d" "$iso_date" "+%s"
    else
        date -d "$iso_date" "+%s"
    fi
}

threshold_days() {
    case "$1" in
        fast) echo 14 ;;
        slow) echo 60 ;;
        stable) echo 180 ;;
        *) echo 30 ;;
    esac
}

format_age() {
    local age="$1"
    age=$((10#$age))
    printf '%s' "$age"
}

TODAY="$(date +%Y-%m-%d)"
TODAY_EPOCH="$(to_epoch "$TODAY")"
TMP_STALE="$(mktemp)"
TMP_PRIORITY="$(mktemp)"
trap 'rm -f "$TMP_STALE" "$TMP_PRIORITY"' EXIT

TOTAL_NOTES=0
while IFS= read -r file; do
    TOTAL_NOTES=$((TOTAL_NOTES + 1))
    title="$(extract_field "$file" "title")"
    updated="$(extract_field "$file" "updated")"
    decay_rate="$(extract_field "$file" "decay_rate")"
    category="$(extract_field "$file" "category")"
    status="$(extract_field "$file" "status")"
    stem="$(basename "$file" .md)"

    [ -n "$updated" ] || continue
    age_days=$(( (TODAY_EPOCH - $(to_epoch "$updated")) / 86400 ))
    threshold="$(threshold_days "$decay_rate")"

    printf '%04d\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$age_days" "$updated" "$stem" "$category" "$status" "$decay_rate" "$title" >> "$TMP_PRIORITY"

    if [ "$status" != "archived" ] && [ "$age_days" -gt "$threshold" ]; then
        printf '%04d\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$age_days" "$updated" "$stem" "$category" "$status" "$decay_rate" "$title" >> "$TMP_STALE"
    fi
done < <(list_markdown_files "$KNOWLEDGE_DIR" | grep -v '/_overview\.md$')

echo "# Codian Memory Health"
echo
echo "Date: $TODAY"
echo "Total notes: $TOTAL_NOTES"

echo
echo "## Priority Review Notes"
if [ -s "$TMP_PRIORITY" ]; then
    LC_ALL=C sort -r "$TMP_PRIORITY" | head -n 8 | while IFS=$'\t' read -r age updated stem category status decay_rate title; do
        echo "- $title | [[$stem]] | age=$(format_age "$age")d | decay=$decay_rate | category=$category | status=$status | updated=$updated"
    done
else
    echo "_No notes found._"
fi

echo
echo "## Stale Candidates"
if [ -s "$TMP_STALE" ]; then
    LC_ALL=C sort -r "$TMP_STALE" | while IFS=$'\t' read -r age updated stem category status decay_rate title; do
        echo "- $title | [[$stem]] | age=$(format_age "$age")d | decay=$decay_rate | category=$category | updated=$updated"
    done
else
    echo "_No stale candidates._"
fi
