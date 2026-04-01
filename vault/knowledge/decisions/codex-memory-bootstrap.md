---
title: "Codian Memory Bootstrap"
category: decisions
tags:
  - decision
  - architecture
  - project/codian
created: 2026-04-01
updated: 2026-04-01
status: current
confidence: high
source: codex
decay_rate: stable
---

# Codian Memory Bootstrap

Am 2026-04-01 wurde neben dem bestehenden Claude-Vault ein eigenes Codex-Gedaechtnis-System angelegt.

Codex nutzt `~/AGENTS.md` als operativen Einstiegspunkt und `~/codexVault/vault/` als persistentes Wissensspeicher-System.

Das Schreibmodell ist:

1. [[INDEX]] bei Session-Start lesen
2. Nur relevante Notes laden
3. Nur dauerhaftes Wissen schreiben
4. [[INDEX]] nach jeder Note-Aenderung aktualisieren

## Related

- [[codian-overview]]
- [[conventions]]
