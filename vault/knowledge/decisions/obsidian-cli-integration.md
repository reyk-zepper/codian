---
title: "Obsidian CLI Integration"
category: decisions
tags:
  - decision
  - workflow
  - architecture
  - project/codian
created: 2026-04-01
updated: 2026-04-01
status: current
confidence: medium
source: codex
decay_rate: slow
---

# Obsidian CLI Integration

Codian is designed to work with plain file edits first, but it explicitly supports Obsidian CLI operations when those operations are safer than manual text edits.

That is especially true for renames, moves, deletes, and structured property edits where link rewriting or frontmatter safety matter.

The expected vault selector is `vault="codexVault"`.

## Related

- [[conventions]]
- [[codex-memory-bootstrap]]
- [[obsidian-vault-pattern]]
