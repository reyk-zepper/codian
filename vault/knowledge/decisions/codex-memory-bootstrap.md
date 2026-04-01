---
title: "Codex Memory Bootstrap"
category: decisions
tags:
  - decision
  - architecture
  - project/codexvault
created: 2026-04-01
updated: 2026-04-01
status: current
confidence: high
source: codex
decay_rate: stable
---

# Codex Memory Bootstrap

On 2026-04-01, a dedicated Codex memory system was created beside the existing Claude vault.

Codex should use `~/AGENTS.md` as the operational entrypoint and `~/codexVault/vault/` as the persistent knowledge store.

The write model is:

1. Read [[INDEX]] at session start.
2. Read only relevant notes.
3. Write durable knowledge only.
4. Update [[INDEX]] after each note change.

## Related

- [[codexvault-overview]]
- [[conventions]]
