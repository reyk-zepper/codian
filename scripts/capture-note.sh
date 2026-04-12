#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VAULT_DIR="${CODIAN_VAULT_DIR:-$REPO_DIR/vault}"
TODAY="$(date +%Y-%m-%d)"

CATEGORY=""
SLUG=""
TITLE=""
TAGS=""
BODY=""
RELATED=""
STATUS="current"
CONFIDENCE="high"
SOURCE="codex"
DECAY_RATE=""

usage() {
    cat <<'EOF'
Usage: capture-note.sh --category <name> --slug <slug> --title <title> [options]

Options:
  --tags <csv>          Comma-separated tags
  --body <text>         Body text to write or append
  --related <csv>       Comma-separated wikilink stems for the Related section
  --status <value>      current|stale|archived
  --confidence <value>  high|medium|low
  --source <value>      codex|user
  --decay-rate <value>  fast|slow|stable
EOF
}

default_decay_rate() {
    case "$1" in
        projects) echo "fast" ;;
        decisions) echo "slow" ;;
        user-profile) echo "fast" ;;
        domain) echo "stable" ;;
        *) echo "slow" ;;
    esac
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

tags_block() {
    local csv="$1"
    if [ -z "$csv" ]; then
        printf 'tags:\n  - memory\n'
        return
    fi

    printf 'tags:\n'
    printf '%s\n' "$csv" | tr ',' '\n' | while IFS= read -r tag; do
        trimmed="$(printf '%s' "$tag" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
        [ -n "$trimmed" ] && printf '  - %s\n' "$trimmed"
    done
}

related_block() {
    local csv="$1"
    [ -n "$csv" ] || return 0

    printf '## Related\n\n'
    printf '%s\n' "$csv" | tr ',' '\n' | while IFS= read -r link; do
        trimmed="$(printf '%s' "$link" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
        [ -n "$trimmed" ] && printf -- '- [[%s]]\n' "$trimmed"
    done
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --category) CATEGORY="$2"; shift 2 ;;
        --slug) SLUG="$2"; shift 2 ;;
        --title) TITLE="$2"; shift 2 ;;
        --tags) TAGS="$2"; shift 2 ;;
        --body) BODY="$2"; shift 2 ;;
        --related) RELATED="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --confidence) CONFIDENCE="$2"; shift 2 ;;
        --source) SOURCE="$2"; shift 2 ;;
        --decay-rate) DECAY_RATE="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

if [ -z "$CATEGORY" ] || [ -z "$SLUG" ] || [ -z "$TITLE" ]; then
    usage >&2
    exit 1
fi

case "$CATEGORY" in
    projects|decisions|user-profile|domain) ;;
    *) echo "Invalid category: $CATEGORY" >&2; exit 1 ;;
esac

if ! [[ "$SLUG" =~ ^[a-z0-9-]+$ ]]; then
    echo "Slug must match [a-z0-9-]+" >&2
    exit 1
fi

[ -n "$DECAY_RATE" ] || DECAY_RATE="$(default_decay_rate "$CATEGORY")"

NOTE_DIR="$VAULT_DIR/knowledge/$CATEGORY"
NOTE_PATH="$NOTE_DIR/$SLUG.md"
mkdir -p "$NOTE_DIR"

if [ -f "$NOTE_PATH" ]; then
    CREATED="$(extract_field "$NOTE_PATH" "created")"
    [ -n "$CREATED" ] || CREATED="$TODAY"
    EXISTING_BODY="$(awk '
        /^## User Notes/ { exit }
        /^---/ { count++; next }
        count >= 2 { print }
    ' "$NOTE_PATH")"
    USER_NOTES="$(awk 'found { print } /^## User Notes/ { found=1; print }' "$NOTE_PATH")"
    [ -n "$USER_NOTES" ] || USER_NOTES="## User Notes"

    UPDATED_BODY="$EXISTING_BODY"
    if [ -n "$BODY" ]; then
        UPDATED_BODY="${UPDATED_BODY}"$'\n\n'"## Update $TODAY"$'\n\n'"$BODY"
    fi
    if [ -n "$RELATED" ] && ! printf '%s\n' "$UPDATED_BODY" | grep -q '^## Related$'; then
        UPDATED_BODY="${UPDATED_BODY}"$'\n\n'"$(related_block "$RELATED")"
    fi
else
    CREATED="$TODAY"
    UPDATED_BODY="# $TITLE"
    if [ -n "$BODY" ]; then
        UPDATED_BODY="$UPDATED_BODY"$'\n\n'"$BODY"
    fi
    if [ -n "$RELATED" ]; then
        UPDATED_BODY="$UPDATED_BODY"$'\n\n'"$(related_block "$RELATED")"
    fi
    USER_NOTES="## User Notes"
fi

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

{
    printf '%s\n' '---'
    printf 'title: "%s"\n' "$TITLE"
    printf 'category: %s\n' "$CATEGORY"
    tags_block "$TAGS"
    printf 'created: %s\n' "$CREATED"
    printf 'updated: %s\n' "$TODAY"
    printf 'status: %s\n' "$STATUS"
    printf 'confidence: %s\n' "$CONFIDENCE"
    printf 'source: %s\n' "$SOURCE"
    printf 'decay_rate: %s\n' "$DECAY_RATE"
    printf '%s\n\n' '---'
    printf '%s\n\n' "$UPDATED_BODY"
    printf '%s\n' "$USER_NOTES"
} > "$TMP_FILE"

mv "$TMP_FILE" "$NOTE_PATH"
trap - EXIT

bash "$REPO_DIR/scripts/rebuild-index.sh" >/dev/null

printf 'Captured note: %s\n' "$NOTE_PATH"
