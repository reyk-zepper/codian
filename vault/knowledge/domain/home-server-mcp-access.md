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

## Direkter Host-Zugriff

Direkter SSH-Zugriff auf den echten Host `remotebase` ist verfuegbar und deutlich hilfreicher als der MCP-Zugang allein. Ueber SSH sind belastbar pruefbar:

- `systemctl`-Status des Hosts
- Docker-Container und ihre Logs
- echte Host-Mounts wie `/srv/docker` und `/mnt/media`
- ausstehende Host-Paketupdates

## Aktueller Arbeitsstand

Am 2026-04-01 wurden auf dem echten Host mehrere ausstehende Paketupdates gefunden, darunter:

- Docker-Pakete (`docker-ce`, `docker-ce-cli`, `docker-compose-plugin`, `containerd.io`)
- Kernel-Metakete (`linux-generic`, `linux-image-generic`, `linux-headers-generic`)
- `cloudflared`
- weitere Ubuntu-Pakete wie `coreutils`, `apparmor`, `nftables`

Speicherbelegung war unkritisch:

- `/` bei ca. 40%
- `/srv/docker` bei ca. 1%
- `/mnt/media` bei ca. 18%

Spaeter am 2026-04-01 wurde ein `apt-get full-upgrade` erfolgreich eingespielt. Danach waren keine weiteren Pakete mehr upgrade-faehig.

Wichtiger Nachzustand:

- `cloudflared` aktualisiert auf `2026.3.0`
- Docker-Client aktualisiert auf `29.3.1`
- Docker-Daemon laeuft bis zum naechsten Neustart noch auf der vorherigen Version
- neuer Kernel `5.15.0-174-generic` ist installiert, aber noch nicht aktiv
- `REBOOT_REQUIRED` ist gesetzt

Nach dem Upgrade waren weiterhin keine fehlgeschlagenen `systemd`-Units sichtbar und alle laufenden Docker-Container blieben verfuegbar.

## Behobenes Problem

Am 2026-04-01 wurde der Restart-Loop von `docker-socket-proxy` behoben.

Root Cause:

- Die Compose-Konfiguration setzte `read_only: true`, stellte aber keine beschreibbaren Laufzeitpfade fuer HAProxy bereit.
- Das Image benoetigt schreibbaren Zugriff auf `/tmp` und `/run`.

Umgesetzte Korrektur in `/opt/claude-home-server/system/docker-socket-proxy/docker-compose.yaml`:

- `tmpfs:`
- `- /run`
- `- /tmp`

Danach lief `docker-socket-proxy` wieder stabil im Status `Up`.

## Home Assistant

Am 2026-04-01 wurde Home Assistant auf dem Host `remotebase` sicher aktualisiert.

Ausgangslage:

- laufender Container auf `2025.12.1`
- Compose-Stack unter `/srv/stack/compose/homeassistant/docker-compose.yml`
- Config-Volume `homeassistant_data` unter `/srv/docker/docker-data/volumes/homeassistant_data/_data`
- keine `custom_components` vorhanden

Sicherheitsmassnahmen vor dem Update:

- Compose-Backup unter `/srv/stack/backups/homeassistant/docker-compose.yml.20260401-151530`
- Config-Backup unter `/srv/stack/backups/homeassistant/config-20260401-151530.tgz`

Umsetzung:

- Compose-Image von `ghcr.io/home-assistant/home-assistant:stable` auf `ghcr.io/home-assistant/home-assistant:2026.4.0` gepinnt
- Stack anschliessend gezielt fuer den Dienst `homeassistant` neu erstellt

Nachkontrolle:

- laufender Container auf `2026.4.0`
- HTTP-Endpunkt auf `127.0.0.1:8123` antwortete mit `200`
- kein Container-Restart-Loop

Beobachtete Warnungen direkt nach dem Start:

- SQLite-Recorder meldete unsauberen Shutdown-Check der Datenbank
- Sonos meldete eine fehlgeschlagene Subscription an `192.168.178.23` und fiel auf Polling zurueck

## Related

- [[codian-overview]]
