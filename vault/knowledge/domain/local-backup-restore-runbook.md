---
title: "Lokales Backup: Restore Runbook"
category: domain
tags:
  - domain/home-server
  - reference
  - workflow
  - active
created: 2026-04-07
updated: 2026-04-07
status: current
confidence: high
source: codex
decay_rate: slow
---

# Lokales Backup: Restore Runbook

Dieses Runbook beschreibt die wichtigsten Restore-Schritte fuer das lokale Restic-Backup auf `remotebase`.

## Voraussetzungen

- Host: `remotebase`
- Repository: `/srv/docker/backups/restic`
- Passwortdatei: `/etc/restic-local-backup.password`
- Root-Wrapper: `/usr/local/sbin/codex-maintenance`

## Snapshot-Liste anzeigen

```bash
sudo /usr/local/sbin/codex-maintenance snapshots
```

## Restore-Test ausfuehren

```bash
sudo /usr/local/sbin/codex-maintenance restore-test
```

Erwartung:

- Ausgabe enthaelt `RESTORE_OK`
- Testziel ist temporaer unter `/tmp/restic-restore-test`

## Einzelne Konfigurationsdatei wiederherstellen

Beispiel: Home-Assistant-Compose-Datei in temporaires Ziel restaurieren.

```bash
sudo mkdir -p /tmp/manual-restore
sudo RESTIC_PASSWORD_FILE=/etc/restic-local-backup.password \
  restic -r /srv/docker/backups/restic restore latest \
  --target /tmp/manual-restore \
  --include /srv/stack/compose/homeassistant/docker-compose.yml
```

Danach liegt die Datei unter:

```text
/tmp/manual-restore/srv/stack/compose/homeassistant/docker-compose.yml
```

## Ganze Home-Assistant-Konfiguration in temporaires Ziel restaurieren

```bash
sudo mkdir -p /tmp/manual-restore
sudo RESTIC_PASSWORD_FILE=/etc/restic-local-backup.password \
  restic -r /srv/docker/backups/restic restore latest \
  --target /tmp/manual-restore \
  --include /opt/homeassistant/config
```

Danach liegt die Konfiguration unter:

```text
/tmp/manual-restore/opt/homeassistant/config
```

## Sichere Restore-Reihenfolge

1. Nie direkt ueber Live-Dateien restaurieren.
2. Immer zuerst nach `/tmp/manual-restore` restaurieren.
3. Inhalt pruefen.
4. Erst dann gezielt nach produktiv kopieren.
5. Betroffenen Dienst anschliessend neu starten.

## Typische Produktionsschritte

Home Assistant:

```bash
sudo cp /tmp/manual-restore/opt/homeassistant/config/configuration.yaml /opt/homeassistant/config/configuration.yaml
sudo docker restart homeassistant
```

Compose-Datei:

```bash
sudo cp /tmp/manual-restore/srv/stack/compose/homeassistant/docker-compose.yml /srv/stack/compose/homeassistant/docker-compose.yml
```

## Wichtige Grenze

Dieses Backup ist lokal auf demselben Host gespeichert. Es hilft bei Fehlkonfiguration, versehentlichem Loeschen und vielen Wartungsfehlern, aber nicht bei komplettem Host- oder Datentraegerausfall.

## Related

- [[home-server-mcp-access]]
