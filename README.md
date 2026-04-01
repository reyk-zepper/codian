# Codian

Codian is Codex's persistent brain on this Mac.

It is a local Obsidian-first memory system for long-term knowledge across sessions and projects. The repository is called `codian`, while the live vault path stays `/Users/reykz/codexVault/vault/` so it can coexist cleanly beside the existing Claude setup.

## English

Codian gives Codex a self-organized long-term memory with transparent markdown notes, a durable index, and maintenance scripts for consistency. It follows the same operating model as the Claude vault on this Mac, but it is deliberately separated by ownership, instructions, and note history.

### Features

- Persistent cross-session memory for Codex
- Just-in-time retrieval via `INDEX.md` instead of loading everything
- Obsidian-compatible vault structure
- Explicit conventions for filenames, frontmatter, tags, and links
- Integrity checks for filenames, metadata, links, index completeness, orphans, and dead-ends
- Rebuildable index from note metadata
- Separate brain from Claude while preserving the same workflow shape

### Local Paths

- Repo root: `/Users/reykz/codexVault/`
- Vault root: `/Users/reykz/codexVault/vault/`
- Global instructions: `/Users/reykz/AGENTS.md`

### Structure

```text
codexVault/
|- docs/
|- scripts/
`- vault/
   |- INDEX.md
   |- README.md
   |- _meta/
   `- knowledge/
      |- projects/
      |- decisions/
      |- user-profile/
      `- domain/
```

### How It Works

1. Codex reads `INDEX.md` at session start.
2. Codex loads only relevant notes for the current task.
3. Durable knowledge is written back as structured notes.
4. `INDEX.md` is updated immediately after each durable write.

### Installation

1. Clone the repository.
2. Keep the live vault at `/Users/reykz/codexVault/vault/`.
3. Install the global instructions from `docs/AGENTS.md.example` into `/Users/reykz/AGENTS.md` if needed.
4. Open `vault/` as an Obsidian vault.
5. Make the maintenance scripts executable if required.

### Verification

```bash
bash scripts/check-integrity.sh
bash scripts/rebuild-index.sh
```

### Tooling

- `bash scripts/rebuild-index.sh` rebuilds `vault/INDEX.md`
- `bash scripts/check-integrity.sh` validates vault health
- If Obsidian CLI is available, use `vault="codexVault"` for move, rename, delete, property, backlink, unresolved, orphan, and dead-end operations

## Deutsch

Codian gibt Codex auf diesem Mac ein eigenes, persistentes Langzeitgedaechtnis. Das System ist Obsidian-kompatibel, transparent fuer den User und bewusst getrennt vom Claude-Vault, damit beide Assistenten parallel mit derselben Denkform, aber ohne vermischte Historie arbeiten koennen.

### Leitidee

- eigener Vault neben Claude
- klare Schreibregeln statt unkontrollierter Session-Historie
- gezieltes Retrieval statt Full-Vault-Laden
- sichtbare Notes als gemeinsame Mensch-KI-Schnittstelle

### Pflege

- `INDEX.md` ist der Einstiegspunkt
- `_meta/conventions.md` ist das Regelwerk
- `knowledge/` enthaelt das eigentliche Wissen

## Status

The repository is live at `https://github.com/reyk-zepper/codian` and tracks the local working copy in `/Users/reykz/codexVault/`.
