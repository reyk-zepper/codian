# Vault Conventions

This document defines the operating rules for CodexVault.

## Structure

```text
vault/
|- INDEX.md
|- README.md
|- _meta/
`- knowledge/
   |- projects/
   |- decisions/
   |- user-profile/
   `- domain/
```

Maximum depth is 3 levels below `vault/`.

## Filenames

- Use English ASCII slugs only.
- Allowed characters: `[a-z0-9-]`
- Transliterate German umlauts to ASCII.
- Keep filenames unique across the vault.

## Frontmatter

Every knowledge note must contain:

```yaml
---
title: "Quoted title"
category: projects|decisions|user-profile|domain
tags:
  - tag-name
created: 2026-04-01
updated: 2026-04-01
status: current|stale|archived
confidence: high|medium|low
source: codex|user
decay_rate: fast|slow|stable
---
```

## Links

- Use Obsidian wikilinks for internal links: `[[note-name]]`
- End notes with a `## Related` section when useful
- Never use folder paths inside wikilinks

## User Notes

Never overwrite content under a `## User Notes` heading.

## Language

- Write notes in the language of the active conversation.
- Keep filenames and frontmatter keys in English ASCII.

## Categories

- `projects` for cross-session project knowledge
- `decisions` for explicit decisions and rationale
- `user-profile` for durable user preferences
- `domain` for reusable domain knowledge

## Operations

- Read `INDEX.md` first
- Write narrowly
- Update `INDEX.md` immediately after each write
- Prefer precise edits over full rewrites
