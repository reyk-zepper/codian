---
title: "Obsidian CLI Integration in Codian"
category: decisions
tags:
  - decision
  - architecture
  - project/codian
  - domain/obsidian
created: 2026-04-01
updated: 2026-04-01
status: current
confidence: high
source: user
decay_rate: stable
---

# Obsidian CLI Integration in Codian

Entscheidung vom 2026-04-01: Der Codian-Vault wird hybrid verwaltet - Codex nutzt sowohl File-Tools (Read/Edit/Write) als auch die offizielle Obsidian CLI, je nach Operation.

## Kontext

Obsidian hat seit v1.12.0 eine offizielle CLI, die als Remote-Control fuer die laufende Obsidian-App fungiert. Alle Operationen laufen ueber Obsidians interne API und gewaehrleisten Datenintegritaet.

## Entscheidung

**Selektive Integration** - nicht alles umstellen, sondern die CLI dort einsetzen, wo sie klar ueberlegen ist:

### CLI verwenden (Pflicht)

- **`obsidian move`** / **`obsidian rename`** - Automatisches Wikilink-Rewriting beim Verschieben/Umbenennen
- **`obsidian property:set/remove`** - Sicheres Frontmatter-Management ohne YAML-Parsing-Risiko
- **`obsidian unresolved`** - Broken-Link-Detection
- **`obsidian orphans`** / **`obsidian deadends`** - Graph-Gesundheit pruefen
- **`obsidian backlinks`** - Link-Analyse vor Refactoring

### File-Tools beibehalten

- **Read** - Notes lesen (schneller, kein Obsidian-Roundtrip)
- **Edit** - Feinkoernige Inhalts-Edits (praeziser als append/prepend)
- **Write** - Neue Notes mit komplexem Content erstellen
- **INDEX.md** - Weiterhin manuell gepflegt (Codex-eigenes Konzept)

## Begruendung

- `obsidian move` loest das groesste Pain-Point: manuelles Wikilink-Fixen nach Verschiebungen
- `property:set` eliminiert YAML-Parsing-Fehler bei Frontmatter-Aenderungen
- Die CLI erfordert ein laufendes Obsidian - fuer reine Lese-Operationen ist das unnoetiger Overhead
- INDEX.md ist ein Codex-Konzept, das Obsidian nicht kennt - hier bleiben File-Tools richtig

## Related

- [[codian-overview]]
