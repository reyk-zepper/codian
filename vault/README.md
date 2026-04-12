# Codian

Codex' persistentes Gedaechtnis-Vault. Dieses Vault wird von Codex (der Notes schreibt und organisiert) und dir (der lesen, kommentieren und eigene Inhalte hinzufuegen kann) gemeinsam genutzt.

## Wie es funktioniert

- Codex liest `INDEX.md` bei jedem Session-Start
- `INDEX.md` zeigt auch die zuletzt geaenderten Notes fuer einen schnelleren Warm-Start
- Notes leben in `knowledge/` organisiert nach Kategorie
- Du kannst zu jeder Note unter `## User Notes` eigene Kommentare hinzufuegen - Codex ueberschreibt diese nie
- Alle Formatierungsregeln stehen in `_meta/conventions.md`

## Operative Scripts

- `bash ../scripts/query-memory.sh <query>` fuer gezielte Retrieval-Suchen
- `bash ../scripts/session-brief.sh [query]` fuer einen kompakten Session-Start

## Ordnerstruktur

    vault/
      INDEX.md          - Codex' Einstiegspunkt
      _meta/            - System-Konventionen
      knowledge/
        projects/       - Projekt-spezifische Notes
        decisions/      - Entscheidungsprotokolle
        user-profile/   - Deine Praeferenzen und Arbeitsweise
        domain/         - Langlebiges Fachwissen
