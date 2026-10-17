# Domain Docs

How the engineering skills should use this repo's domain documentation. Layout: **single-context**.

## Before exploring, read these

- **`GLOSSARY.md`** at the repo root.
- **`docs/adr/`**: ADRs that touch the area you're about to work in. Newer ADRs win over older text.
- **`docs/scope.md`**: what is in v1 and what is Later.
- For design detail, the files under `docs/design/` (map in `CLAUDE.md`).

Do not read `archive/`; it holds the old BMAD-era files and is not a source.

## Use the glossary's vocabulary

When your output names a domain concept (an issue title, a test name, a scene or script name), use the term as defined in `GLOSSARY.md`. Don't drift to synonyms the glossary lists under _Avoid_. If the concept isn't in the glossary yet, either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR or `docs/scope.md`, say so explicitly rather than silently overriding:

> _Contradicts ADR-0003 (fixed viewpoints), but worth reopening because…_
