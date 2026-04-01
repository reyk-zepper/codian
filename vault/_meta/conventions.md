# Vault Conventions

This document is the operating contract for Codian.
It applies to Codex as a writing system and to the user as a reference.

---

## Structure

```text
vault/
|- INDEX.md
|- README.md
|- _meta/
`- knowledge/
   |- projects/
   |- decisions/
   |- user-profile/
   `- domain/
```

Maximum depth is 3 levels below the vault root.

- Allowed: `knowledge/projects/codian/architecture.md`
- Not allowed: `knowledge/projects/codian/decisions/2026/arch.md`

---

## Filenames

Only English ASCII slugs are allowed: `[a-z0-9-]`

Rules:
- transliterate German umlauts to ASCII
- replace spaces and special characters with `-`
- collapse repeated dashes
- keep filenames unique across the vault

Examples:
- `Benutzer Praeferenzen 2026` -> `user-preferences-2026`
- `Obsidian CLI Integration` -> `obsidian-cli-integration`
- `TypeScript Best Practices` -> `typescript-best-practices`

ASCII filenames are required for path safety and cross-tool consistency.

---

## Frontmatter

Every knowledge note created by Codex starts with this exact schema:

```yaml
---
title: "Always quoted"
category: projects|decisions|user-profile|domain
tags:
  - tag-name
created: 2026-04-01
updated: 2026-04-01
status: current|stale|archived
confidence: high|medium|low
source: codex|user
decay_rate: fast|slow|stable
---
```

Field rules:
- `title`: always quoted
- `category`: must match the top-level folder name
- `tags`: YAML block list without `#`
- `created`: ISO date, never changed later
- `updated`: ISO date, updated on each content edit
- `status`: `current`, `stale`, or `archived`
- `confidence`: confidence in the note content
- `source`: `codex` or `user`
- `decay_rate`: `fast`, `slow`, or `stable`

---

## Tag Taxonomy

Hierarchical tags:

```text
project/[slug]
domain/[topic]
```

Flat tags:

```text
decision
preference
architecture
workflow
reference
active
memory
```

Tags support navigation. Status and confidence belong in frontmatter, not tags.

---

## Wikilinks

Internal links use Obsidian wikilinks only.

Forms:

```markdown
[[conventions]]
[[working-preferences|Working Preferences]]
```

Rules:
- link to the filename without `.md`
- do not include folder paths in wikilinks
- link liberally when a known note is referenced
- end notes with `## Related` when useful

---

## Language

Codex writes notes in the language of the active conversation.

- German conversation -> German note content
- English conversation -> English note content
- frontmatter keys stay English
- filenames stay English ASCII

Mixed-language vaults are acceptable. Internal consistency per note matters more than global uniformity.

---

## User Notes

Content under `## User Notes` belongs to the user and must never be overwritten by Codex.

---

## Obsidian CLI Integration

The vault is managed in a hybrid way: direct file edits plus Obsidian CLI when that is safer or more useful.

CLI path on this Mac:

```text
/Applications/Obsidian.app/Contents/MacOS/obsidian
```

Vault parameter:

```text
vault="codexVault"
```

Use Obsidian CLI when possible for:
- moving notes
- renaming notes
- deleting notes
- setting frontmatter properties
- removing frontmatter properties
- checking unresolved links
- checking orphans
- checking dead-ends
- inspecting backlinks

Useful commands:

```bash
obsidian move path="knowledge/old/note.md" to="knowledge/new/" vault="codexVault"
obsidian rename file="note" name="new-name" vault="codexVault"
obsidian delete file="note" vault="codexVault"
obsidian property:set file="note" name="status" value="stale" vault="codexVault"
obsidian property:remove file="note" name="old-field" vault="codexVault"
obsidian unresolved vault="codexVault"
obsidian orphans vault="codexVault"
obsidian deadends vault="codexVault"
obsidian backlinks file="note" vault="codexVault"
obsidian search:context query="..." vault="codexVault"
```

Prefer direct file tools for:
- reading notes
- precise content edits
- writing new notes with complex content
- maintaining `INDEX.md`

---

## Self-Organization

- each note belongs to exactly one category
- Codex decides when additional subfolders are useful
- after each durable write, `INDEX.md` must be updated immediately
- the depth rule always applies

---

## Example Note

```markdown
---
title: "Codian: Memory Boundaries"
category: decisions
tags:
  - decision
  - architecture
  - project/codian
created: 2026-04-01
updated: 2026-04-01
status: current
confidence: high
source: codex
decay_rate: stable
---

# Codian: Memory Boundaries

Codian stores durable cross-session knowledge and avoids transient execution noise.

See [[conventions]] for all writing rules and [[working-preferences]] for user-facing operating preferences.

## Related

- [[conventions]]
- [[working-preferences]]
```
