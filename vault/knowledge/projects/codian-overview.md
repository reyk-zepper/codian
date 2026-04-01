---
title: "Codian Project Overview"
category: projects
tags:
  - project/codian
  - architecture
  - active
created: 2026-04-01
updated: 2026-04-01
status: current
confidence: high
source: codex
decay_rate: stable
---

# Codian Project Overview

Codex' persistentes Gedaechtnis-System basierend auf einem Obsidian-Vault. Dient als bidirektionale Schnittstelle zwischen User und Codex - Codex organisiert Wissen selbststaendig, der User kann lesen, kommentieren und korrigieren.

## Architektur

- **Zugriff**: Hybrid - File-Tools (Read/Write/Edit) + Obsidian CLI (move, property:set, tags)
- **Scope**: Global - Codex hat von jedem Projekt aus Zugriff via `~/AGENTS.md`
- **Vault-Pfad**: `/Users/reykz/codexVault/vault/`
- **Tooling**: Shell-Scripts (`rebuild-index.sh`, `check-integrity.sh`) + Obsidian CLI (1.12+)

## Kernkonzepte

- **Index-First Read**: Codex liest INDEX.md bei Session-Start
- **Write-then-Index**: Jeder Note-Write aktualisiert sofort den Index
- **User Notes Protection**: `## User Notes` Sections werden nie ueberschrieben
- **Staleness Tracking**: Frontmatter `status` + `decay_rate` fuer Content-Rot-Praevention

## Status

- Vault-Struktur: Komplett
- Index-System: Funktional
- Shell-Tooling: Funktional
- Erster Live-Test: 2026-04-01

## Related

- [[preferences]]

## User Notes
