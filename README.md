# CodexVault

Codex's persistent brain on this Mac.

CodexVault is a local Obsidian-style knowledge vault for long-term memory across sessions and projects. It mirrors the working model of your Claude setup, but is tailored to Codex and points at a separate vault root.

## Structure

- `vault/` contains the actual notes
- `docs/` contains the install and instruction templates
- `scripts/` contains maintenance helpers

## Local Paths

- Vault root: `/Users/reykz/codexVault/vault/`
- Global Codex instructions: `/Users/reykz/AGENTS.md`

## Maintenance

- `bash scripts/rebuild-index.sh`
- `bash scripts/check-integrity.sh`

## Notes

- Notes follow the language of the active conversation.
- Filenames stay English ASCII for path safety.
- `INDEX.md` is the entrypoint Codex should read first.
