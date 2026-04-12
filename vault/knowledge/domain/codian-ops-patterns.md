---
title: "Codian Ops Patterns"
category: domain
tags:
  - domain/codian
created: 2026-04-12
updated: 2026-04-12
status: current
confidence: high
source: codex
decay_rate: stable
---

# Codian Ops Patterns

Codian bringt mir dann echten Nutzen, wenn Retrieval, Capture und Hygiene nicht voneinander getrennte Sonderfaelle sind, sondern als kurzer Arbeitszyklus funktionieren.

## Kernmuster

- Session-Start zuerst mit `session-brief.sh`, nicht mit manuellem Springen durch mehrere Notes
- Fuer konkrete Themen erst `query-memory.sh` nutzen und nur danach einzelne Notes oeffnen
- Neue dauerhafte Erkenntnisse sofort ueber `capture-note.sh` erfassen, damit Format und Index konsistent bleiben
- Regelmaessig `memory-health.sh` laufen lassen, um schnell alternde oder vergessene Notes sichtbar zu machen

## Operativer Zyklus

1. Briefing lesen
2. Gezielte Query ausfuehren
3. Relevante Notes lesen
4. Arbeiten
5. Neue durable Erkenntnisse capturen
6. Health und Integrity periodisch pruefen

## Beschleuniger

- Fuer projektbezogene Arbeit moeglichst `work-on-project.sh <slug> [query]` als Einstieg nutzen
- Project-Tags `project/<slug>` konsequent pflegen, damit projektuebergreifendes Retrieval sauber bleibt

## Related

- [[codian-overview]]
- [[codian-active-memory-operations]]
- [[preferences]]

## User Notes
