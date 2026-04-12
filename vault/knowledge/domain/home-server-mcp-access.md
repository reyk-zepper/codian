---
title: "Homeserver: MCP-Zugriffsgrenzen"
category: domain
tags:
  - domain/home-server
  - reference
  - workflow
  - active
created: 2026-04-01
updated: 2026-04-11
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

Am 2026-04-07 wurden erneut ausstehende Host-Updates eingespielt:

- `docker-ce` auf `29.4.0`
- `docker-ce-cli` auf `29.4.0`
- `docker-ce-rootless-extras` auf `29.4.0`
- `tzdata` auf `2026a`

Nachkontrolle:

- `apt list --upgradable` war danach leer
- kein `reboot-required` gesetzt
- keine fehlgeschlagenen `systemd`-Units
- Docker lief danach auf `Client 29.4.0 / Server 29.4.0`

Beobachteter Nebeneffekt:

- der Docker-Upgrade-Zyklus startete die Container neu
- Netdata war dabei kurz spaeter verfuegbar als Home Assistant
- deshalb wurden die Netdata-basierten REST-Sensoren in Home Assistant anschliessend gegen leere/fehlende Antworten gehaertet, damit beim Host-Neustart keine Template-Fehler mehr entstehen

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

## Bekannter Sonderfall

Die Sonos-Warnung gilt im aktuellen Setup als bekannter, nicht-blockierender Sonderfall. Laut Nutzer ist sie vermutlich auf die aussergewoehnliche Netzwerkkonstruktion mit Starlink und FRITZ!Box zurueckzufuehren. Sonos funktioniert im Alltag einwandfrei und die Warnung verursacht derzeit keine praktische Einschraenkung.

## Cloudflare Access

Am 2026-04-01 wurde die Cloudflare-Absicherung fuer `home.zepper.me` untersucht und korrigiert.

Root Cause:

- Ein Cloudflare Tunnel war vorhanden, aber die Access-App `homeassistant` schuetzte nur Teilpfade:
  - `home.zepper.me/auth/*`
  - `home.zepper.me/lovelace/*`
  - `home.zepper.me/config/*`
- Der Tunnel selbst hatte fuer `home.zepper.me` kein `originRequest.access.required: true`.
- Dadurch war die Root-Seite `https://home.zepper.me` direkt bis zur Home-Assistant-HTML erreichbar.

Umgesetzter Fix:

- Access-App `homeassistant` auf `home.zepper.me/*` erweitert
- Tunnel-Konfiguration fuer `home.zepper.me` auf Access-Zwang umgestellt:
  - `required: true`
  - `teamName: zepper`
  - `audTag: 9e1e526abcfa96d95d99af246f8b92a9e4dbf4770e5f05887a994845de3fff3a`

Verifikation:

- `https://home.zepper.me` lieferte danach nicht mehr die Home-Assistant-HTML direkt
- ein Aufruf geschuetzter Pfade redirectete auf `zepper.cloudflareaccess.com`

Offener Aufraeumpunkt:

- `netdata.zepper.me` nutzt aktuell denselben `audTag` wie die Home-Assistant-App. Das funktioniert, ist aber konzeptionell unsauber und sollte spaeter auf eine eigene Access-App umgestellt oder bewusst dokumentiert werden.

## Cloudflare Access: Netdata

Am 2026-04-01 wurde auch `netdata.zepper.me` in Cloudflare sauber getrennt.

Ausgangslage:

- `netdata.zepper.me` war bereits per Access geschuetzt
- der Tunnel nutzte aber noch die `audTag` der Home-Assistant-App

Umgesetzter Fix:

- eigene Access-App `netdata` angelegt
- eigene Allow-Policy fuer `reyk.zepper@proton.me` erstellt
- Tunnel fuer `netdata.zepper.me` auf die neue `audTag` umgestellt:
  - `271d545647b1df21aea2d43f0c87d5fe859449be6d2ca278bb1ea67f6fcd38ac`

Verifikation:

- `https://netdata.zepper.me` redirectete danach auf `zepper.cloudflareaccess.com`
- `kid`/`aud` in der Redirect-URL entsprachen der neuen Netdata-App statt der Home-Assistant-App

## Home Assistant Companion App

Am 2026-04-01 wurde fuer die Android-Companion-App ein separater externer Hostname eingerichtet.

Root Cause:

- Die Android-App lief ueber `home.zepper.me` in einen Login-Loop.
- Ursache war nicht Home Assistant selbst, sondern Cloudflare Access vor dem kompletten OAuth-/Login-Flow der Companion-App.

Umgesetzter Fix:

- `home.zepper.me` bleibt fuer Browser/Admin-Zugriff weiter hinter Cloudflare Access
- zusaetzlicher Hostname `ha-mobile.zepper.me` wurde auf denselben Home-Assistant-Origin gelegt
- fuer `ha-mobile.zepper.me` ist kein Cloudflare Access vorgeschaltet

Verifikation:

- `ha-mobile.zepper.me` liefert direkt die Home-Assistant-HTML mit `HTTP 200`
- `home.zepper.me` bleibt weiter per Cloudflare Access geschuetzt

## Home Assistant: Homeserver-Monitoring

Am 2026-04-07 wurde im `Ops`-Dashboard von Home Assistant ein dedizierter Homeserver-Block ergaenzt.

Umgesetzter Ansatz:

- Datenquelle ist nicht der Home-Assistant-Container selbst, sondern der bereits laufende Host-Monitor `netdata`
- Home Assistant laeuft auf `remotebase` im `host`-Netzwerk und liest Netdata lokal ueber `http://127.0.0.1:8787`
- die Sensoren wurden als `rest`-Sensoren direkt in `configuration.yaml` angelegt

Aktive Sensoren:

- `sensor.homeserver_cpu`
- `sensor.homeserver_ram_used`
- `sensor.homeserver_root_disk_used`
- `sensor.homeserver_uptime_hours`
- `sensor.homeserver_alarm_warnings`
- `sensor.homeserver_alarm_critical`
- `sensor.homeserver_docker_running_containers`
- `sensor.homeserver_docker_stopped_containers`
- `sensor.homeserver_docker_unhealthy_containers`
- `sensor.homeserver_docker_health_status`

Dashboard-Anpassung:

- neue Sektion `Homeserver` im Dashboard `Ops`
- zeigt CPU, RAM, Root-Disk, Uptime sowie Warning-/Critical-Alarme aus Netdata
- zeigt zusaetzlich Docker-Status ueber den lokalen Docker-Socket-Proxy auf `127.0.0.1:2375`

Docker-Logik:

- `running`: Anzahl aller Container mit `State == running`
- `stopped`: Anzahl aller Container mit anderem State wie `created` oder `exited`
- `unhealthy`: Anzahl laufender Container mit Docker-Health-Status `unhealthy`
- `health_status`: `healthy`, solange kein laufender Container `unhealthy` ist, sonst `unhealthy`

## Lokaler Backup-Plan

Am 2026-04-07 wurde ein lokaler App-Backup-Plan auf dem Host eingerichtet.

Ablageort:

- Restic-Repository unter `/srv/docker/backups/restic`

Mechanik:

- Root-Wrapper `/usr/local/sbin/codex-maintenance`
- Backup-Script `/usr/local/bin/local-app-backup.sh`
- systemd-Unit `local-app-backup.service`
- systemd-Timer `local-app-backup.timer`
- taegliche Ausfuehrung um `03:30` Uhr lokaler Zeit

Gesicherter Umfang:

- `/srv/stack/compose`
- `/opt/homeassistant/config`
- Docker-Volume-Daten fuer:
  - `homeassistant_data`
  - `matter_data`
  - `nextcloud_nextcloud_db`
  - `nextcloud_nextcloud_redis`
  - `paperless_pgdata`
  - `paperless_redisdata`
  - `portainer_data`
- zusaetzlich temporaere Metadaten:
  - laufende Containerliste
  - Docker-Volumeliste
  - komprimiertes Archiv relevanter Compose- und HA-Konfigurationsdateien
  - PostgreSQL-Dumps fuer `nextcloud-db` und `paperless-db`, sofern die Container laufen

Retention:

- `7` taegliche Snapshots
- `4` woechentliche Snapshots
- `3` monatliche Snapshots

Erstverifikation:

- erster Lauf am 2026-04-07 erfolgreich
- systemd-Service endete mit `status=0/SUCCESS`
- Timer aktiv mit naechstem Lauf am `2026-04-08 03:30 CEST`

Wichtige Grenze:

- Das Backup ist bewusst lokal auf demselben Host gespeichert.
- Es schuetzt gegen Fehlkonfiguration, versehentliches Loeschen und viele Wartungsfehler.
- Es schuetzt nicht gegen kompletten Host- oder Datentraegerausfall.

## Root-Disk-Aufraeumen

Am 2026-04-07 wurde die Root-Partition gezielt aufgeraeumt.

Massnahmen:

- ungenutzte Docker-Images entfernt
- gestoppte Container entfernt
- `journalctl --vacuum-size=500M` ausgefuehrt

Ergebnis:

- freier Platz auf `/` von ca. `43G` auf ca. `63G` erhoeht
- `docker image prune -a -f` reclamte ca. `4.9G`
- Journalgroesse auf ca. `521M` reduziert

Einordnung:

- Hauptverbraucher der Root-Partition war `/var/lib`, insbesondere `containerd`
- ext4-Reserved-Blocks belegen zusaetzlich rund `5G` nur fuer `root`

Verifikation:

- `python -m homeassistant --script check_config -c /config` lief mit Exit-Code `0`
- Home Assistant wurde danach neu gestartet
- `http://127.0.0.1:8123` antwortete anschliessend wieder mit `HTTP 200`

Wichtige Beobachtung zum Buero-Licht:

- Die aktuelle Home-Assistant-Entity-Registry kennt fuer den Bereich `buero` nur drei Licht-Entities:
  - `light.tv`
  - `light.schreibtisch_strip`
  - `light.eckelicht`
- Falls im Buero gefuehlt eine vierte Lampe fehlt, liegt das derzeit nicht am Dashboard-JSON allein, sondern daran, dass in HA momentan keine vierte Buero-`light.*`-Entity registriert ist.

## Nextcloud

Am 2026-04-01 wurde Nextcloud auf dem Host `remotebase` aktualisiert.

Ausgangslage:

- laufender Container `nextcloud-app` auf `31.0.12`
- Image-Tag `nextcloud:stable-apache`
- Container-Stack:
  - `nextcloud-app`
  - `nextcloud-db`
  - `nextcloud-redis`

Sicherung vor dem Update:

- Compose-Backup unter `/tmp/nextcloud-backups/20260401-173222/docker-compose.yml`
- PostgreSQL-Dump unter `/tmp/nextcloud-backups/20260401-173222/db.sql`
- App-Volume-Backup unter `/tmp/nextcloud-backups/20260401-173222/html-volume.tgz`

Umsetzung:

- neues `nextcloud:stable-apache`-Image gepullt
- `nextcloud-app` mit identischer Laufzeitkonfiguration auf dem neuen Image neu erstellt

Nachkontrolle:

- `occ status` meldet `32.0.7`
- `maintenance: false`
- `needsDbUpgrade: false`
- lokaler HTTP-Check auf `127.0.0.1:8081/status.php` antwortet mit `200`
- `nextcloud-app`, `nextcloud-db` und `nextcloud-redis` laufen

## Paperless-NGX

Am 2026-04-06 wurde Paperless-NGX auf `remotebase` als eigener Stack eingerichtet.

Architektur:

- Compose-Stack unter `/srv/stack/compose/paperless`
- Dienste:
  - `paperless-webserver`
  - `paperless-db`
  - `paperless-broker`
  - `paperless-tika`
  - `paperless-gotenberg`
- lokaler Web-Bind nur auf `127.0.0.1:8015`

Speicherlayout:

- Dokumente und Austauschpfade auf `/mnt/media/paperless`
  - `consume`
  - `media`
  - `media/trash`
  - `export`
- interne App-/DB-/Redis-Daten in Docker-Volumes

Konfiguration:

- offizielles Image `ghcr.io/paperless-ngx/paperless-ngx:2.20.4`
- PostgreSQL `18`
- Redis `8-alpine`
- Gotenberg `8`
- Apache Tika `latest`
- OCR-Sprachen `deu+eng`
- `PAPERLESS_URL=https://paperless.zepper.me`
- lokaler Port fuer den Tunnel/Reverse-Proxy: `127.0.0.1:8015`

Wichtige Implementierungsdetails:

- PostgreSQL-Volume musste fuer `postgres:18` auf `/var/lib/postgresql` statt `/var/lib/postgresql/data` gemountet werden
- `PAPERLESS_DBPASS` musste explizit an den Webserver uebergeben werden
- `PAPERLESS_EMPTY_TRASH_DIR` erforderte den Host-Ordner `/mnt/media/paperless/media/trash`

Verifikation:

- Containerstatus:
  - `paperless-webserver` healthy
  - `paperless-db` running
  - `paperless-broker` running
  - `paperless-tika` running
  - `paperless-gotenberg` running
- lokaler HTTP-Test auf `127.0.0.1:8015` liefert `302` auf `/accounts/login/?next=/`
- Tika und Gotenberg sind aus dem Webserver-Container intern erreichbar

Cloudflare-Zugriff:

- `paperless.zepper.me` ist per eigener Cloudflare-Access-App `paperless` geschuetzt
- `paperless-mobile.zepper.me` zeigt ohne Access direkt auf denselben Origin und ist fuer die Mobile-App gedacht

Mobile-/UX-Basis:

- Browser/Admin-Zugriff: `https://paperless.zepper.me`
- Mobile-App-Zugriff: `https://paperless-mobile.zepper.me`
- Benutzer `reyk` verwendet als sichtbaren Namen `reyk` statt der Mailadresse
- angelegte Dokumenttypen:
  - `Rechnung`
  - `Vertrag`
  - `Versicherung`
  - `Steuer`
  - `Gesundheit`
  - `Sonstiges`
- angelegte Tags:
  - `privat`
  - `wichtig`
  - `bank`
  - `haus`
  - `arbeit`
  - `steuer`
- angelegte Ablagepfade:
  - `Eingang`
  - `Rechnungen`
  - `Vertraege`
  - `Steuern`
  - `Gesundheit`
- angelegte Ansichten:
  - `Alle Dokumente`
  - `Inbox`
  - `Wichtig`
  - `Privat`
  - `Rechnungen`
  - `Steuern`
- erste automatische Regex-Zuordnung fuer Dokumenttypen, Korrespondenten und Speicherpfade ist aktiv

## Host-Status 2026-04-11

Direktpruefung per SSH auf `remotebase`, weil der MCP-Zugang weiterhin nur die eingeschraenkte Container-Sicht bietet.

Aktueller Zustand:

- keine fehlgeschlagenen `systemd`-Units
- kein `reboot-required` gesetzt
- Docker aktiv, `Client 29.4.0 / Server 29.4.0`
- Kern-Services `docker`, `ssh` und `cloudflared` sind `active`
- keine Docker-Container in `unhealthy`, `exited` oder `restarting`

Laufende Container bei der Pruefung:

- `paperless-webserver` auf `2.20.4` und `healthy`
- `homeassistant` auf `2026.4.0`
- `netdata_stable` auf `edge` und `healthy`
- weitere Produktiv-Container fuer Nextcloud, Plex, Matter, Portainer und Hilfsdienste liefen stabil seit 4 Tagen

Speicherbelegung:

- `/` bei 32%
- `/srv/docker` bei 1%
- `/mnt/media` bei 18%

Ausstehende Host-Updates am 2026-04-11:

- `docker-compose-plugin` `5.1.2-1~ubuntu.22.04~jammy`
- mehrere `systemd`-/`udev`-Pakete auf `249.11-0ubuntu3.20`
- `linux-firmware` auf `20220329.git681281e4-0ubuntu3.42`

Einordnung:

- Der Host ist aktuell gesund und betriebsbereit.
- Er ist aber nicht vollstaendig up to date, weil noch regulare Paketupdates offen sind.
- Die MCP-Health-Check-Fehler fuer Backup-/Audit-Pfade bleiben bekannte Berechtigungsgrenzen der MCP-Umgebung und sind kein neuer Host-Defekt.

## Related

- [[codian-overview]]
