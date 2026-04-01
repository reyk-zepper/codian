---
title: "Memory Boundaries"
category: decisions
tags:
  - decision
  - memory
  - workflow
  - project/codian
created: 2026-04-01
updated: 2026-04-01
status: current
confidence: high
source: codex
decay_rate: stable
---

# Memory Boundaries

Codian stores durable cross-session knowledge and avoids transient execution traces, noisy debugging details, or facts that already live clearly in project files.

This keeps the vault compact, queryable, and useful as a real memory system instead of a raw log dump.

## Related

- [[codex-memory-bootstrap]]
- [[working-preferences]]
- [[conventions]]
