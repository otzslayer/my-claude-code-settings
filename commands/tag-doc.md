---
description: Add English technical tags to a markdown document's frontmatter in place (pre-step to /translate-doc)
argument-hint: <input_file>
allowed-tools: Read, Write, Edit
---

# tag-doc

Add technical tags to an English markdown document's YAML frontmatter, **in place**. Tag
generation is performed by **you (Claude)** in this session — no external API call, no
database, no Obsidian vault access. This is the pre-step to `/translate-doc`: tags written
here are preserved verbatim by translate-doc and inherited by the Korean output.

## Arguments

User input: `$ARGUMENTS`

Parse:
- First positional arg = **input file path** (required).

If no input file is provided or the path does not exist, stop and tell the user what was missing.

## Assets

- Tag rules: `~/.claude/tag-doc-assets/tag-rules.md`

## Workflow

### Step 1 — Load
1. `Read` the input file.
2. `Read` the tag rules file (`~/.claude/tag-doc-assets/tag-rules.md`) and internalize every section.

### Step 2 — Resolve the title signal
The title is the strongest tag signal. Resolve it in this order:
1. Frontmatter `title` field, if present.
2. Otherwise, derive from the filename (strip extension, separators → spaces).
3. Otherwise, the first H1 (`# `) heading in the body.

### Step 3 — Generate tags
Apply every rule in `tag-rules.md`:
- Extract title entities first, then named entities/techniques, tools, disciplines.
- English lowercase-hyphen tags.
- **No fixed count cap** — include every concept that genuinely represents the document.
- Apply the exclusion rules and the generic-tag filter. No-redundancy and compound rules are
  what keep the set tight now that there is no numeric cap: never emit both a parent and a
  close child, never combine adjective+noun.

### Step 4 — Merge into frontmatter
Determine the frontmatter case and act:
- **Has frontmatter, has `tags`:** merge new tags into the existing list. Preserve existing
  tags and their order; append only genuinely new tags; dedupe. If the existing `tags` is a
  flow array (`tags: [a, b]`), normalize it to a block sequence before appending.
- **Has frontmatter, no `tags`:** add a `tags` field.
- **No frontmatter:** create a minimal frontmatter block containing ONLY `tags` and the
  `auto_tagged` marker (see below). Do NOT fabricate a `title` or any other field. (A
  fabricated English title would be preserved verbatim by translate-doc and leave an English
  title on the Korean output.)
- In all cases, preserve every other frontmatter field byte-for-byte.

Write tags as a YAML block sequence:

```yaml
tags:
  - tag-one
  - tag-two
```

After the `tags` field is in place, stamp the run marker into the same frontmatter:

```yaml
auto_tagged: true
```

- If `auto_tagged` is absent, add it. If it already exists (any value), set it to `true`.
- This is the only non-`tags` field this command may write.

### Step 5 — Write in place
Use `Edit` (or `Write` only when creating a new frontmatter block) to modify the **input file
itself**. Do not create a copy. Do not create a backup — the user controls the source via git.

### Step 6 — Report
Print one concise block:

```
✓ Tagged → <input_path>
  · Title signal: <frontmatter|filename|body-h1>
  · Tags added: <new_count> (<comma-separated new tags>)
  · Tags total: <total_count>
  · Frontmatter: <created|extended|tags-field-added>
  · auto_tagged: true
```

Do not print the document contents.

## Hard rules
- Tag generation is in-session. Never call an external API, a database, or scan an Obsidian vault.
- Edit the input file **in place**. Never write a `_tagged` copy.
- Never fabricate a `title`; the only frontmatter fields this command writes are `tags` and `auto_tagged`.
- Preserve every existing frontmatter field and every existing tag verbatim.
- Always stamp `auto_tagged: true` on completion; do not add any other field beyond `tags`.
- Do not modify the document body — only the frontmatter `tags` field and the `auto_tagged` marker.
- Tags are English lowercase-hyphen, even though the document will be translated to Korean.
- No fixed cap on tag count; the exclusion + no-redundancy + generic filter bound the set.
