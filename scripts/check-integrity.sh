#!/bin/bash
# check-integrity.sh
# Validates the vault's integrity: filenames, frontmatter, links, depth, index, and graph.
# Exit 0 if all checks pass, exit 1 if any issues are found.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="${CODIAN_VAULT_DIR:-$SCRIPT_DIR/../vault}"
KNOWLEDGE_DIR="$VAULT_DIR/knowledge"
INDEX_FILE="$VAULT_DIR/INDEX.md"

TOTAL_CHECKS=9
PASSED=0
TOTAL_ISSUES=0

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

ALL_NOTES=()
while IFS= read -r f; do
    ALL_NOTES+=("$f")
done < <(list_markdown_files "$KNOWLEDGE_DIR" | grep -v '/_overview\.md$')

ALL_MARKDOWN=()
while IFS= read -r f; do
    ALL_MARKDOWN+=("$f")
done < <(list_markdown_files "$VAULT_DIR")

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
    for filepath in "${ALL_MARKDOWN[@]+"${ALL_MARKDOWN[@]}"}"; do
        local bn
        bn="$(basename "$filepath")"
        [ "$bn" = "_overview.md" ] && continue
        [[ "$filepath" != "$KNOWLEDGE_DIR/"* ]] && continue
        if ! [[ "$bn" =~ ^[a-z0-9-]+\.md$ ]]; then
            issues+=("  - $(rel_path "$filepath"): filename '$bn' does not match ^[a-z0-9-]+\\.md$")
        fi
    done

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

    for f in "${ALL_MARKDOWN[@]+"${ALL_MARKDOWN[@]}"}"; do
        basename "$f" .md
    done > "$known_stems_file"

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
    for filepath in "${ALL_NOTES[@]+"${ALL_NOTES[@]}"}"; do
        local rel depth
        rel="${filepath#"$VAULT_DIR/"}"
        depth=$(printf '%s' "$rel" | tr -cd '/' | wc -c | tr -d ' ')
        if [ "$depth" -gt 3 ]; then
            issues+=("  - $(rel_path "$filepath"): path is $((depth + 1)) levels deep (max 4 components)")
        fi
    done

    if [ "${#issues[@]}" -eq 0 ]; then
        echo "[PASS] Depth check"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] Depth check"
        for line in "${issues[@]}"; do echo "$line"; done
        TOTAL_ISSUES=$((TOTAL_ISSUES + ${#issues[@]}))
    fi
}

check_index_completeness() {
    local issues=()

    if [ ! -f "$INDEX_FILE" ]; then
        echo "[FAIL] Index completeness"
        echo "  - INDEX.md not found at $INDEX_FILE"
        TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
        return
    fi

    for filepath in "${ALL_NOTES[@]+"${ALL_NOTES[@]}"}"; do
        local bn
        bn="$(basename "$filepath" .md)"
        if ! grep -qF "[[$bn]]" "$INDEX_FILE"; then
            issues+=("  - $(rel_path "$filepath"): [[$bn]] not found in INDEX.md")
        fi
    done

    if [ "${#issues[@]}" -eq 0 ]; then
        echo "[PASS] Index completeness"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] Index completeness"
        for line in "${issues[@]}"; do echo "$line"; done
        TOTAL_ISSUES=$((TOTAL_ISSUES + ${#issues[@]}))
    fi
}

check_orphans() {
    local issues=()
    local skip_names="INDEX.md README.md _overview.md conventions.md"
    local all_targets
    all_targets="$(mktemp)"

    for filepath in "${ALL_NOTES[@]+"${ALL_NOTES[@]}"}"; do
        extract_wikilinks "$filepath"
    done > "$all_targets"
    [ -f "$INDEX_FILE" ] && extract_wikilinks "$INDEX_FILE" >> "$all_targets"

    for filepath in "${ALL_NOTES[@]+"${ALL_NOTES[@]}"}"; do
        local bn stem
        bn="$(basename "$filepath")"
        stem="$(basename "$filepath" .md)"

        local skip=false
        for sf in $skip_names; do
            [ "$bn" = "$sf" ] && { skip=true; break; }
        done
        [ "$skip" = true ] && continue

        if ! grep -qE "^${stem}(\|.*)?$" "$all_targets"; then
            issues+=("  - $(rel_path "$filepath"): orphan (no incoming links)")
        fi
    done

    rm -f "$all_targets"

    if [ "${#issues[@]}" -eq 0 ]; then
        echo "[PASS] Orphan notes"
        PASSED=$((PASSED + 1))
    else
        echo "[WARN] Orphan notes"
        for line in "${issues[@]}"; do echo "$line"; done
        PASSED=$((PASSED + 1))
    fi
}

check_deadends() {
    local issues=()

    for filepath in "${ALL_NOTES[@]+"${ALL_NOTES[@]}"}"; do
        local bn
        bn="$(basename "$filepath")"
        [ "$bn" = "_overview.md" ] && continue

        local link_count
        link_count=$(extract_wikilinks "$filepath" | wc -l | tr -d ' ')
        if [ "$link_count" -eq 0 ]; then
            issues+=("  - $(rel_path "$filepath"): dead-end (no outgoing links)")
        fi
    done

    if [ "${#issues[@]}" -eq 0 ]; then
        echo "[PASS] Dead-end notes"
        PASSED=$((PASSED + 1))
    else
        echo "[WARN] Dead-end notes"
        for line in "${issues[@]}"; do echo "$line"; done
        PASSED=$((PASSED + 1))
    fi
}

check_filename_rules
check_frontmatter_presence
check_required_fields
check_category_match
check_broken_wikilinks
check_depth
check_index_completeness
check_orphans
check_deadends

echo
echo "Summary: $PASSED/$TOTAL_CHECKS checks passed, $TOTAL_ISSUES issues found"

if [ "$TOTAL_ISSUES" -eq 0 ]; then
    exit 0
else
    exit 1
fi
