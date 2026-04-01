#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="$SCRIPT_DIR/../vault"
KNOWLEDGE_DIR="$VAULT_DIR/knowledge"

TOTAL_CHECKS=6
PASSED=0
TOTAL_ISSUES=0

ALL_NOTES=()
while IFS= read -r -d '' f; do
    ALL_NOTES+=("$f")
done < <(find "$KNOWLEDGE_DIR" -name "*.md" -not -name "_overview.md" -print0 | sort -z)

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

has_frontmatter() {
    local count
    count=$(grep -c '^---' "$1" 2>/dev/null || true)
    [ "$count" -ge 2 ]
}

rel_path() {
    echo "${1#"$VAULT_DIR/"}"
}

extract_wikilinks() {
    local file="$1"
    awk '/^---/{c++;if(c==2){found=1;next}} found{print}' "$file" \
        | perl -nle 'while (/\[\[([^\]]+)\]\]/g) { print $1 }'
}

check_filename_rules() {
    local issues=()
    while IFS= read -r -d '' filepath; do
        local bn
        bn="$(basename "$filepath")"
        [ "$bn" = "_overview.md" ] && continue
        if ! [[ "$bn" =~ ^[a-z0-9-]+\.md$ ]]; then
            issues+=("  - $(rel_path "$filepath"): invalid filename '$bn'")
        fi
    done < <(find "$KNOWLEDGE_DIR" -name "*.md" -print0 | sort -z)

    if [ "${#issues[@]}" -eq 0 ]; then
        echo "[PASS] Filename rules"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] Filename rules"
        for line in "${issues[@]}"; do echo "$line"; done
        TOTAL_ISSUES=$((TOTAL_ISSUES + ${#issues[@]}))
    fi
}

check_frontmatter_presence() {
    local issues=()
    for filepath in "${ALL_NOTES[@]+"${ALL_NOTES[@]}"}"; do
        if ! has_frontmatter "$filepath"; then
            issues+=("  - $(rel_path "$filepath"): missing frontmatter")
        fi
    done

    if [ "${#issues[@]}" -eq 0 ]; then
        echo "[PASS] Frontmatter presence"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] Frontmatter presence"
        for line in "${issues[@]}"; do echo "$line"; done
        TOTAL_ISSUES=$((TOTAL_ISSUES + ${#issues[@]}))
    fi
}

check_required_fields() {
    local required_fields=(title category tags created updated status confidence source decay_rate)
    local issues=()

    for filepath in "${ALL_NOTES[@]+"${ALL_NOTES[@]}"}"; do
        has_frontmatter "$filepath" || continue
        for field in "${required_fields[@]}"; do
            local val
            val="$(extract_field "$filepath" "$field")"
            if [ -z "$val" ]; then
                if ! awk '/^---/{c++;if(c==2)exit;next} c==1 && /^'"$field"':/' "$filepath" | grep -q .; then
                    issues+=("  - $(rel_path "$filepath"): missing field '$field'")
                fi
            fi
        done
    done

    if [ "${#issues[@]}" -eq 0 ]; then
        echo "[PASS] Required fields"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] Required fields"
        for line in "${issues[@]}"; do echo "$line"; done
        TOTAL_ISSUES=$((TOTAL_ISSUES + ${#issues[@]}))
    fi
}

check_category_match() {
    local issues=()
    for filepath in "${ALL_NOTES[@]+"${ALL_NOTES[@]}"}"; do
        has_frontmatter "$filepath" || continue
        local category category_folder rel_to_knowledge
        category="$(extract_field "$filepath" "category")"
        rel_to_knowledge="${filepath#"$KNOWLEDGE_DIR/"}"
        category_folder="${rel_to_knowledge%%/*}"
        if [ -n "$category" ] && [ "$category" != "$category_folder" ]; then
            issues+=("  - $(rel_path "$filepath"): category '$category' does not match folder '$category_folder'")
        fi
    done

    if [ "${#issues[@]}" -eq 0 ]; then
        echo "[PASS] Category match"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] Category match"
        for line in "${issues[@]}"; do echo "$line"; done
        TOTAL_ISSUES=$((TOTAL_ISSUES + ${#issues[@]}))
    fi
}

check_broken_wikilinks() {
    local issues=()
    local known_stems_file
    known_stems_file="$(mktemp)"

    find "$VAULT_DIR" -name "*.md" -print0 \
        | while IFS= read -r -d '' f; do basename "$f" .md; done \
        > "$known_stems_file"

    for filepath in "${ALL_NOTES[@]+"${ALL_NOTES[@]}"}"; do
        while IFS= read -r link; do
            local target="${link%%|*}"
            target="${target#"${target%%[![:space:]]*}"}"
            target="${target%"${target##*[![:space:]]}"}"
            [ -z "$target" ] && continue
            if ! grep -qxF "$target" "$known_stems_file"; then
                issues+=("  - $(rel_path "$filepath"): broken wikilink [[$target]]")
            fi
        done < <(extract_wikilinks "$filepath")
    done

    rm -f "$known_stems_file"

    if [ "${#issues[@]}" -eq 0 ]; then
        echo "[PASS] Broken wikilinks"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] Broken wikilinks"
        for line in "${issues[@]}"; do echo "$line"; done
        TOTAL_ISSUES=$((TOTAL_ISSUES + ${#issues[@]}))
    fi
}

check_depth() {
    local issues=()
    while IFS= read -r -d '' filepath; do
        local rel depth
        rel="${filepath#"$VAULT_DIR/"}"
        depth=$(printf '%s' "$rel" | tr -cd '/' | wc -c | tr -d ' ')
        if [ "$depth" -gt 3 ]; then
            issues+=("  - $(rel_path "$filepath"): path is too deep")
        fi
    done < <(find "$KNOWLEDGE_DIR" -name "*.md" -not -name "_overview.md" -print0 | sort -z)

    if [ "${#issues[@]}" -eq 0 ]; then
        echo "[PASS] Depth check"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] Depth check"
        for line in "${issues[@]}"; do echo "$line"; done
        TOTAL_ISSUES=$((TOTAL_ISSUES + ${#issues[@]}))
    fi
}

check_filename_rules
check_frontmatter_presence
check_required_fields
check_category_match
check_broken_wikilinks
check_depth

echo
echo "Passed $PASSED/$TOTAL_CHECKS checks"

if [ "$TOTAL_ISSUES" -gt 0 ]; then
    echo "Found $TOTAL_ISSUES issue(s)"
    exit 1
fi
