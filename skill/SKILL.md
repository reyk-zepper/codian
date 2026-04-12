---
name: codian-brain
description: >
  Codex's persistent memory system powered by the Codian vault.
  This skill is the operational reminder that Codian is the working brain:
  read INDEX.md first, retrieve narrowly, capture durable knowledge during work,
  and keep the index current after every meaningful write.
---

# Codian Brain

Codian is not passive documentation. It is the persistence layer that keeps work from resetting to zero.

Use this skill whenever:
- a session starts
- project work, architecture, review, planning, or implementation is happening
- the user reveals reusable preferences, constraints, or personal context
- new domain knowledge or durable patterns emerge
- the user asks to remember, document, structure, or improve the vault

## Session Start

Before the first substantive response:

1. Read `/Users/reykz/codexVault/vault/INDEX.md`
2. Load only the notes relevant to the task
3. Internalize project state, user preferences, prior decisions, and reusable domain knowledge
4. Do not load the entire vault

## During Work

Capture durable knowledge as it appears.

Write when:
- a project becomes important across sessions
- a decision affects future work
- a reusable pattern is discovered
- the user makes preferences or working style explicit
- a correction should change future behavior

Do not write:
- transient debugging noise
- raw execution logs
- one-off questions with no durable reuse
- information already obvious in project files without cross-session value

## Write Pattern

Every durable write must follow this order:

1. Create or update the note in `vault/knowledge/`
2. Update `vault/INDEX.md` immediately
3. Refresh the note's `updated:` field

An unindexed note is effectively lost.

## Categories

- `projects`: project state, scope, stack, next steps
- `decisions`: architectural or workflow decisions with rationale
- `user-profile`: user preferences, identity, working style
- `domain`: transferable knowledge and proven patterns

See `skill/references/vault-categories.md` for the quick decision guide.

## Tooling

Use direct file reads and edits for normal content work.

Use Obsidian CLI when link-aware operations matter:

```bash
obsidian move path="knowledge/old/note.md" to="knowledge/new/" vault="codexVault"
obsidian rename file="note" name="new-name" vault="codexVault"
obsidian unresolved vault="codexVault"
obsidian orphans vault="codexVault"
obsidian deadends vault="codexVault"
```

Maintenance:

```bash
bash /Users/reykz/codexVault/scripts/rebuild-index.sh
bash /Users/reykz/codexVault/scripts/check-integrity.sh
```

## Mindset

Codian should reduce re-explanation, re-discovery, and context loss.
If a future session would benefit from knowing something, capture it now.
