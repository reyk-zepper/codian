#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

VAULT_DIR="$TMP_DIR/vault"
mkdir -p \
    "$VAULT_DIR/knowledge/projects" \
    "$VAULT_DIR/knowledge/decisions" \
    "$VAULT_DIR/knowledge/user-profile" \
    "$VAULT_DIR/knowledge/domain" \
    "$VAULT_DIR/_meta"

cat > "$VAULT_DIR/knowledge/projects/project-alpha.md" <<'EOF'
---
title: "Project Alpha"
category: projects
tags:
  - project/alpha
  - active
created: 2026-04-01
updated: 2026-04-12
status: current
confidence: high
source: codex
decay_rate: fast
---

# Project Alpha

Alpha depends on [[decision-beta]] and uses the retrieval pattern.

## User Notes
EOF

cat > "$VAULT_DIR/knowledge/decisions/decision-beta.md" <<'EOF'
---
title: "Decision Beta"
category: decisions
tags:
  - decision
  - architecture
  - project/alpha
created: 2026-04-02
updated: 2026-04-11
status: current
confidence: high
source: codex
decay_rate: slow
---

# Decision Beta

The chosen retrieval pattern favors targeted memory reads.

## User Notes
EOF

cat > "$VAULT_DIR/knowledge/user-profile/preferences.md" <<'EOF'
---
title: "Preferences"
category: user-profile
tags:
  - preference
created: 2026-04-03
updated: 2026-04-10
status: current
confidence: high
source: codex
decay_rate: fast
---

# Preferences

- Prefer pragmatic solutions
- Wants active memory usage

## User Notes
EOF

cat > "$VAULT_DIR/knowledge/user-profile/role-and-identity.md" <<'EOF'
---
title: "Role and Identity"
category: user-profile
tags:
  - identity
created: 2026-04-03
updated: 2026-04-09
status: current
confidence: high
source: user
decay_rate: slow
---

# Role and Identity

- AI Adoption Manager
- Strong tech identity

## User Notes
EOF

cat > "$VAULT_DIR/knowledge/domain/retrieval-patterns.md" <<'EOF'
---
title: "Retrieval Patterns"
category: domain
tags:
  - domain/retrieval
  - workflow
created: 2026-04-04
updated: 2026-04-08
status: current
confidence: high
source: codex
decay_rate: stable
---

# Retrieval Patterns

Use targeted retrieval and avoid loading the entire vault.

## User Notes
EOF

CODIAN_VAULT_DIR="$VAULT_DIR" bash "$ROOT_DIR/scripts/rebuild-index.sh"
CODIAN_VAULT_DIR="$VAULT_DIR" bash "$ROOT_DIR/scripts/check-integrity.sh"

grep -q '^## Recent Updates' "$VAULT_DIR/INDEX.md"
grep -q '\[\[project-alpha\]\]' "$VAULT_DIR/INDEX.md"
grep -q '\[\[decision-beta\]\]' "$VAULT_DIR/INDEX.md"

QUERY_OUTPUT="$(CODIAN_VAULT_DIR="$VAULT_DIR" bash "$ROOT_DIR/scripts/query-memory.sh" alpha)"
printf '%s\n' "$QUERY_OUTPUT" | grep -q '\[\[project-alpha\]\]'

BRIEF_OUTPUT="$(CODIAN_VAULT_DIR="$VAULT_DIR" bash "$ROOT_DIR/scripts/session-brief.sh" retrieval)"
printf '%s\n' "$BRIEF_OUTPUT" | grep -q '## User Preferences'
printf '%s\n' "$BRIEF_OUTPUT" | grep -q '\[\[retrieval-patterns\]\]'

CAPTURE_OUTPUT="$(CODIAN_VAULT_DIR="$VAULT_DIR" bash "$ROOT_DIR/scripts/capture-note.sh" \
    --category domain \
    --slug testing-patterns \
    --title "Testing Patterns" \
    --tags "domain/testing,workflow" \
    --related "project-alpha,decision-beta" \
    --body "Capture durable testing knowledge for future sessions.")"
printf '%s\n' "$CAPTURE_OUTPUT" | grep -q 'testing-patterns.md'
test -f "$VAULT_DIR/knowledge/domain/testing-patterns.md"
grep -q '\[\[testing-patterns\]\]' "$VAULT_DIR/INDEX.md"
grep -q '\[\[project-alpha\]\]' "$VAULT_DIR/knowledge/domain/testing-patterns.md"
grep -q '\[\[decision-beta\]\]' "$VAULT_DIR/knowledge/domain/testing-patterns.md"

HEALTH_OUTPUT="$(CODIAN_VAULT_DIR="$VAULT_DIR" bash "$ROOT_DIR/scripts/memory-health.sh")"
printf '%s\n' "$HEALTH_OUTPUT" | grep -q 'Stale Candidates'
printf '%s\n' "$HEALTH_OUTPUT" | grep -q 'Preferences'

PROJECT_OUTPUT="$(CODIAN_VAULT_DIR="$VAULT_DIR" bash "$ROOT_DIR/scripts/project-brief.sh" alpha)"
printf '%s\n' "$PROJECT_OUTPUT" | grep -q 'Project Alpha'
printf '%s\n' "$PROJECT_OUTPUT" | grep -q '\[\[decision-beta\]\]'
printf '%s\n' "$PROJECT_OUTPUT" | grep -q '\[\[project-alpha\]\]'

CLOSE_OUTPUT="$(CODIAN_VAULT_DIR="$VAULT_DIR" bash "$ROOT_DIR/scripts/close-session.sh")"
printf '%s\n' "$CLOSE_OUTPUT" | grep -q 'Updated Today'
printf '%s\n' "$CLOSE_OUTPUT" | grep -q '\[\[testing-patterns\]\]'
printf '%s\n' "$CLOSE_OUTPUT" | grep -q 'Run integrity check'

WORK_OUTPUT="$(CODIAN_VAULT_DIR="$VAULT_DIR" bash "$ROOT_DIR/scripts/work-on-project.sh" alpha retrieval)"
printf '%s\n' "$WORK_OUTPUT" | grep -q 'Project Workbench: alpha'
printf '%s\n' "$WORK_OUTPUT" | grep -q 'Session Brief'
printf '%s\n' "$WORK_OUTPUT" | grep -q 'Project Brief'
printf '%s\n' "$WORK_OUTPUT" | grep -q '\[\[project-alpha\]\]'

echo "All Codian tool tests passed"
