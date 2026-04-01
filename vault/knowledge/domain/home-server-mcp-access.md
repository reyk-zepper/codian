---
title: "Homeserver: MCP-Zugriffsgrenzen"
category: domain
tags:
  - domain/home-server
  - reference
  - workflow
  - active
created: 2026-04-01
updated: 2026-04-01
status: current
confidence: high
source: codex
decay_rate: slow
---

# Homeserver: MCP-Zugriffsgrenzen

Der aktuelle Homeserver-Zugriff erfolgt ueber die `claude-home-server`-MCP-Umgebung und zeigt derzeit keine vollwertige Host-Sicht, sondern eine eingeschraenkte Linux-/SSH-Containerumgebung.

## Beobachtungen

- Hostname erscheint als Container-ID (`93671b3cb5b6`).
- `systemd`-basierte Abfragen schlagen fehl mit `System has not been booted with systemd as init system`.
- Docker-Abfragen melden `Docker is not enabled in the server configuration`.
- Health Check meldet Berechtigungsfehler fuer Backup- und Audit-Pfade:
  - `/var/backups/claude-home-server`
  - `/var/log/claude-home-server`

## Konsequenz

Zustaende wie fehlgeschlagene Services, aktive Sessions, UFW-Regeln und Docker-Container sind ueber diesen Zugang aktuell nicht als vollstaendige Host-Aussage belastbar. Belastbar sichtbar sind vor allem:

- Basis-Systeminfo der Umgebung
- Paket-Update-Stand innerhalb der sichtbaren Ubuntu-Umgebung
- allgemeine Prozessliste innerhalb der MCP-Umgebung
- Speicherbelegung der sichtbaren Mounts

## Aktueller Arbeitsstand

Am 2026-04-01 wurden innerhalb der sichtbaren Ubuntu-22.04.5-Umgebung mehrere ausstehende Paketupdates gefunden, waehrend keine unmittelbare Speicherknappheit sichtbar war.

## Related

- [[codian-overview]]
