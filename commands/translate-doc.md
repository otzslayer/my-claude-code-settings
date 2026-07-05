---
description: Translate English markdown to natural Korean using the project's translation prompt and accumulated glossary
argument-hint: <input_file> [--output <path>]
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# translate-doc

Translate an English markdown/text document to natural Korean. The actual translation is performed by **you (Claude)** in this session — no external API call. You operate as a bilingual translator following the project's curated prompt and accumulated glossary.

**Tone target.** GPT-5.1-level rhythmic and metaphorical fluency, with Claude's accuracy and consistency intact. The output should read as if originally written in Korean by a skilled essayist — not translated.

## Arguments

User input: `$ARGUMENTS`

Parse:
- First positional arg = **input file path** (required).
- `--output <path>` / `-o <path>` = output file path (optional).
- If `--output` is omitted, **overwrite the input file in place** — the translated Korean replaces the original English at the same path. No backup is created, so the source English is not retained unless the file is under version control. Pass `--output <path>` to write the translation to a separate file and leave the input untouched.

If no input file is provided or the path does not exist, stop and tell the user what was missing.

## Assets (absolute paths — all managed under `~/.claude/translate-doc-assets/`)

- System prompt: `~/.claude/translate-doc-assets/system_prompt.md`
- Glossary: `~/.claude/translate-doc-assets/glossary.json`
  - This is a **symlink** to `/Users/jayhan/workspaces/translate-with-gpt/data/glossary.json`. Reads and writes flow through to the original file, so the glossary stays shared with the `translate-doc` CLI in that repo. Treat the symlink path as the canonical access path.
- Translationese patterns: `~/.claude/translate-doc-assets/translationese-patterns.md`
  - Absorbed translationese rules (from `im-not-ai` taxonomy) with definitions, prescriptions, and `영어 원문 → BAD → GOOD` examples. The command references these rules; the rule text lives only in this file.

## Workflow

### Step 1 — Load assets

1. `Read` the input file.
2. `Read` the system prompt. The prompt is XML-tagged. **Internalize every section EXCEPT `<output_format>`** — you will write to a file directly instead of emitting JSON.
3. `Read` the glossary JSON. It is a flat map `{ "English Term": "한국어(원문)" }`.
4. `Read` the translationese patterns file (`translationese-patterns.md`). Internalize the absorbed patterns and their `영어 원문 → BAD → GOOD` examples — you will apply them in Step 4 (sentence-level) and Step 5 (density). Skip the YAML header (it is a machine-readable ledger for the resync script, not a translation rule).

### Step 2 — Filter glossary by what actually appears in the input

The full glossary has ~2,500 entries. Do **not** inject all of it. Instead, build a **filtered subset** containing only keys whose English term appears in the input text.

Matching rules:
- Case-insensitive.
- **Word boundary** match — `agent` should not match `agentic` unless `agentic` is also a glossary key on its own.
- Multi-word keys (e.g. `Large Language Model (LLM)`, `prompt chaining`) match as substrings on word boundaries.

If the filtered set is empty, that is fine — proceed with no glossary terms (rare for technical docs).

### Step 3 — Decide whether to chunk

- **Single pass** if the input is under ~50,000 characters (≈ 25K English tokens).
- **Chunk** otherwise: split on `##` (H2) headings. The preamble before the first H2 is one chunk; each H2 block is a chunk. Keep each H2 heading attached to its body.
- Never split inside a code block, table, list, or callout block. Adjust the boundary outward if a naive H2 split would break one of these.

### Step 4 — Translate

For each chunk (or the whole document if single-pass), translate to natural Korean applying **every rule** from the system prompt's `<role>`, `<core_principles>`, `<cultural_adaptation>`, `<natural_korean_writing>`, `<terminology>`, `<preservation_rules>`, `<heading_translation>` sections.

#### Comprehend the whole source before translating

Before producing any Korean text, read the entire input once (or the entire chunk, when chunking) and form a working mental model of:

- **Argument** — what is the author trying to claim, convince me of, or change my mind about?
- **Tone** — essay, technical reference, business memo, polemic, personal blog? How formal? How playful? How urgent?
- **Audience** — who is the author writing for? What do they already know?
- **Emotional undertone** — confident, doubtful, excited, cautious, frustrated, wry?
- **Recurring images and motifs** — which figures does the author return to? An essay about AI may keep circling back to "teammate", "apprentice", "infrastructure", "memory"; a piece about distributed systems may keep returning to "pressure", "blast radius", "fragility". Note these as a cluster — you will render them consistently in Korean.

The translation must carry all five layers, not just the surface meaning. Skipping this comprehension pass is the single most common reason a translation reads correct sentence-by-sentence yet hollow as a whole.

When chunking long documents, do this comprehension pass on the **whole document** during Step 1, before translating any chunk. Each chunk is then translated *with the global model in mind*, not as an isolated fragment.

##### Confirm two parameters with the user (MANDATORY)

After forming the mental model, **before producing any Korean text**, confirm two key translation parameters with the user via the `AskUserQuestion` tool (number-picker UI, not free-form). Ask both questions in a **single** tool call. Mark your comprehension-pass best guess as `(Recommended)` on the appropriate option, with a one-line rationale tied to what you observed in the source.

**Question 1 — 글의 카테고리와 톤** (header: `글 톤`, 4 options, mutually exclusive)

1. 격식 있는 기술/비즈니스 문서 — formal third-person, terminology-heavy, neutral voice
2. 균형 있는 에세이 / 장문 블로그 — first-person OK, analytic + narrative mix, columnist voice
3. 캐주얼한 개인 노트 / 짧은 글 — informal, conversational, close to spoken Korean
4. 비판적 / 논객 글 — opinionated, persuasive, rhetorical edge

**Question 2 — 번역 의역 강도** (header: `의역 강도`, 4 options, mutually exclusive — 4단계 슬라이더; AskUserQuestion의 옵션 상한이 4개라 정확히 한 화면에 맞는다. 보수→균형→적극→과감 순으로 단조 증가)

1. 보수 — 원문 구조 유지, 정확성 우선. 한국어 자연스러움보다 원문 충실. (≤30% 문장 재구성)
2. 균형 — Korean rhythm으로 재구성하되 원문 의미와 구조에 충실. (~50–65% 문장 재구성) `(Recommended)` by default unless the document obviously calls for another level.
3. 적극 — 균형보다 더 과감하게 Korean rhythm으로 재구성하되, 문장 전면 재창작까지는 가지 않는다. 균형과 과감의 중간 지점. (~65–80% 문장 재구성)
4. 과감 — 한국어 에세이체로 자유롭게 재작성. 논증·비유·tone만 유지하고 문장 구조는 한국어식으로 전면 재구성. (GPT-5.1-style fluency)

Use the user's answers to tune translation:
- **글 톤** → register, vocabulary formality, idiom range, sentence ending texture
- **의역 강도** → how far you deviate from source sentence structure (보수: minimal restructuring ≤30%; 균형: 50–65%; 적극: 65–80%, 균형보다 과감하되 문장 전면 재창작은 아님; 과감: full Korean essayistic flow). 4단계는 단조 증가하는 슬라이더이며, "균형과 과감 중간"이 적극(레벨 3)이다.

If the user selects `Other` (free-form) for either question, parse the answer and apply your best interpretation.

The other three layers (argument, audience, recurring motifs) you derive automatically from the source — do **not** ask the user about them. The two questions above are the only user-facing checkpoint in this command.

#### Non-negotiable baseline

- Body text endings: declarative (`~한다`, `~이다`, `~였다`). Polite endings (`~합니다`, `~죠`) **only** inside direct quotation marks.
- All headings (levels 1–6) MUST be translated. Replace, do not append. Preserve `#` markers and bold formatting.
- **YAML frontmatter: preserve every field verbatim, including `title`.** Frontmatter is metadata consumed by tools (Obsidian, static site generators, etc.). The `title` field often serves as a stable identifier or matches an external source URL — translating it breaks those linkages. Body-text H1, if present in the source, is the right place for a translated title. If the source has no body H1 and only a frontmatter title, do not add a translated H1 — that would modify markdown structure not in the source.
- Markdown structure, code blocks (translate only comments inside), inline code, URLs, file paths: preserve verbatim. **Do not add or remove horizontal rules (`---`), blockquotes, or other structural markers that are not in the source.**
- Apply the **filtered glossary** with highest priority. Every glossary key that appears in source must be rendered using the glossary's Korean form — subject to the **glossary-vs-generic-noun rule** below.

#### Em dash handling (refined priority order)

Em dashes (—) in source: never copy into Korean prose. Apply this priority order:

1. **Collapse to parenthetical** `( )` — when the dash-flanked phrase lists or restates the preceding noun.
   - English: `Every finished artifact—code, docs, analysis—becomes context.`
   - GOOD: `완성된 아티팩트(코드, 문서, 분석)는 컨텍스트가 된다.`
2. **Absorb into a comma-connected clause** — when the aside is short and tight.
3. **Split into separate sentences** — only when the dash carries a strong pivot or contrast that would feel cramped in one sentence.

**Default to collapse first.** Splitting fragments the rhythm and often produces awkward repeats. Watch for the failure mode where splitting forces you to repeat a word like `무엇이든 ... 무엇이든 마찬가지다` — that is the symptom of having split when you should have collapsed.

Exception: em dashes inside code, inline code, or URLs are preserved verbatim.

#### Metaphor and figurative language

Every vivid metaphor and figurative verb in the source is doing work — carrying an argument, setting a mood, anchoring an image the author wants the reader to feel. A translation that flattens these to plain verbs is technically correct and rhetorically dead.

Your job is **not** to look up fixed mappings. Your job is to read the figurative phrase in its full context and generate a Korean rendering that does the same job for a Korean reader. Apply the following process to every figurative phrase you encounter:

1. **Identify** that a phrase is functioning figuratively. Test: would dropping the imagery leave the sentence duller, less specific, or less persuasive than the original? If yes, it is load-bearing and must be preserved. If the imagery is a dead metaphor with no rhetorical weight, plain rendering is fine.
2. **Trace** what the image is doing inside the larger argument you mapped in the comprehension pass. Is the figure pointing to growth? Distance? Pressure? Fragility? Speed? Inheritance? Compounding return? The same English word can call for very different Korean images depending on the argument it serves. `compound` in a finance-flavored essay points toward `복리처럼`; `compound` in a personal-growth essay might point toward `켜켜이 쌓이다` or `차곡차곡 누적되다`. **The right Korean image depends on what the surrounding argument is doing, not on a dictionary equivalence.**
3. **Render** with a Korean image that produces the same effect on a Korean reader as the source did on an English reader. The Korean image does not need to be the same image — it needs to do the same job. If the original figure has no natural Korean equivalent, restructure the sentence around a different Korean image that carries the same argumentative weight.
4. **Calibrate intensity.** If the source uses a quiet, almost-dead metaphor, your Korean should also be quiet. Do not over-poeticize a workaday turn of phrase — that swings to the opposite failure mode of stilted "translation literature." Match the source's register, not your own taste for vivid language.
5. **Stay consistent within the document.** If the author returns to the same metaphor cluster — e.g. an essay repeatedly framing AI as a "teammate", "new hire", "collaborator" — your Korean renderings of those related figures must stay inside one coherent Korean cluster. Don't randomly switch between `팀원`, `동료`, `협업자`, `신입` when the author was consistent. Pick the cluster on first occurrence and hold it.

The system prompt's `<cultural_adaptation>` section lists a handful of well-known idiom pairs. Treat that list as **examples of the principle**, not as a lookup table you must hit. When the source uses a figurative expression that is not in the list, you generate the Korean rendering from scratch using steps 1–5 above. When the source uses an expression that *is* in the list but the surrounding argument calls for a different image, **override the list — the surrounding argument always wins**.

**Sanity check.** After translating, re-read your Korean rendering of any figurative passage in isolation. If a Korean reader saw only your sentence (without the English), would they feel the metaphor doing work — or would they read past it as filler? Aim for "doing work."

#### Glossary vs generic-noun conflict

The filtered glossary takes priority for **domain-specific technical terms**. But the glossary contains some entries like `Configuration → Configuration` (English preserved) that target product/API/library names. When the source uses the same word as a **generic lowercase noun** in ordinary prose (e.g. *"the latter provides configuration"*), the glossary entry is the wrong rule to apply — follow the system prompt's `<terminology>` Common Technical Terms section instead (`Configuration → 설정`).

Heuristic:
- Source word capitalized as a proper noun or product/API name → follow glossary's English-preserve mapping.
- Source word is a lowercase common noun in a generic sentence → translate to Korean per Common Technical Terms.

When in doubt, choose what reads naturally in the surrounding Korean sentence. **The glossary is a tool for consistency, not a straitjacket.**

#### Sentence rhythm — combine over split

English packs information in short, choppy, subject-led sentences. Korean breathes better with longer, subject-omitted, connector-linked sentences. **Default to combining 2–3 short English sentences into one flowing Korean sentence** when they share an action, condition, or topic. Only split when there is a genuine pivot, contrast, or emphasis shift.

Example:
- English: `While I'm still learning, I've repeated my answers often enough that I'm writing it here so the next time I'm asked I can share a link instead.`
- BAD (split, fragmented end): `아직 배우는 중이지만, 같은 답을 너무 자주 반복해서 이렇게 글로 남긴다. 다음에 또 같은 질문을 받으면 링크 하나만 던져주면 되도록.`
- GOOD (combined, flowing): `아직 배우는 중이지만 같은 질문을 너무 자주 받다 보니, 이번엔 글로 정리해두고 다음에 또 같은 질문이 들어오면 링크 하나만 건네려 한다.`

The English `so that I can ...` pattern is a particular trap — do not let it terminate the Korean sentence in `~되도록.` Restructure the whole clause around a Korean intent ending (`~려 한다`, `~으면 된다`, `~기 위해서다`).

#### 번역투 패턴 흡수 — 문장 단위 (translationese-patterns.md)

`translationese-patterns.md`는 `im-not-ai` 분류 체계에서 흡수한 번역투 패턴의 규칙·예문을 담는다. **규칙 본문은 그 파일에 있다 — 여기서 반복하지 않는다.** 영어 원문을 보며 번역하는 동안, 다음 **문장 단위 패턴**을 원문과 대조하며 적용한다(각 패턴의 정의·처방·`영어 원문 → BAD → GOOD` 예문은 translationese-patterns.md 참조):

- **C-11** 연결어미 뒤 쉼표 — 일괄 제거
- **A-7** light verb (have/make/take/give + 명사) — 동사 환원
- **A-15** 무생물·추상 주어 + 만능 동사 — 행위자 환원 / `…에 따르면` 분리
- **A-18** 관계절 직역(긴 좌향 수식) — 문장 분리 / 동격 후치
- **E-2** 진행형 `~고 있다` 자동 매핑 — 단순 시제 환원 검토
- **F-4** 영어 명사화(-tion/-ment/-ness/-ity) 직역 — 동사·형용사 어근 환원
- **PE15** 호칭 직역(Mr./Ms./Dr.) — 한국어 호칭 또는 생략
- **A-3~A-6·A-11·A-13** 조사 직결 확장(`~에 있어서`·`~라는 점에서`·`~와 관련하여`·`~에 기반하여`·`~을 위해`·명사 나열) — 목적격/주제 조사로 직결

density 기반 패턴(A-16·A-19·G-1/G-2·H-3)은 문장 단위가 아니라 **전체 빈도**로 판단하므로 Step 5(전체 재독)에서 점검한다 — 아래 Step 5 체크리스트 9·15·16·17번 참조.

##### 의역 강도와의 precedence (MANDATORY)

흡수 패턴은 위 Question 2에서 사용자가 고른 의역 강도(보수/균형/적극/과감)와 두 등급으로 상호작용한다. translationese-patterns.md의 "패턴 인덱스" 표가 각 패턴의 등급을 ID별로 명시하며, 아래 분류와 1:1 일치한다:

- **표면 교정형** (C-11, A-7, E-2, F-4, A-19, PE15, G-1/G-2, H-3, A-3~A-6·A-11·A-13): **모든 의역 강도에서 적용한다.** 번역투 *오류 수정*이지 문체적 자유가 아니므로 보수에서도 고친다.
- **구조 재구성형** (A-15, A-16, A-18): **의역 강도에 단조 비례한다.** 문장 구조를 실제로 바꾸므로 보수에서는 명백한 경우만(3중+ 중첩 관형구, 단락 3회+ 대명사) 최소 적용하고, 균형에서 적극 적용, 적극에서 더 적극(긴 좌향 수식·대명사 밀도를 한층 공격적으로 분리), 과감에서 전면 적용한다.

이 등급 구분이 "보수를 고른 사용자에게 문장 전면 재구성을 강요"하는 모순을 막는다.

#### Avoid translationese in adverb placement

English `effectively + verb` should become Korean predicate position, not adverb-first:
- BAD: `AI와 어떻게 효과적으로 일할 수 있을까?` (mirrors English word order)
- GOOD: `AI와 어떻게 함께 일해야 효과적일까?` (predicate position)

This extends the system prompt's "patterns to eliminate `~적(인)`" rule to adverb placement specifically. Whenever you find yourself writing `~적으로 + 동사`, ask whether the adverb can move to the predicate as `~적이다`.

#### Avoid English-derived verb forms

Prefer settled Korean verbs over loanword-transliterated verbs:
- `scale (as verb)` → `확장되다`, NOT `스케일시키다`
- `update (a config)` → `반영하다`, `수정하다`, NOT always `업데이트하다`
- Exception: well-established loanwords like `온보딩하다`, `테스트하다`, `디버깅하다` are fine.

#### Active voice over passive

Convert passive chains to active where the agent is clear. Especially watch for `~되어지다` (double passive — never acceptable) and `~에 의해 ~된다` (replace with `Y가 X한다`).

#### Conversational warmth (essay register, not report register)

Even after applying every rule above, a translation can still read as **stiff** — technically correct, grammatically natural, but feels like a corporate report rather than a columnist's essay. The user picked `균형 있는 에세이/장문 블로그` for tone — that means warmth comes through rhythm and register, not just word accuracy. Watch for these five stiffness patterns and rewrite them:

**Pattern A — Two consecutive crisp declaratives where the original is one breath**

When the source uses two short sentences that share an action, condition, or topic, Korean essay rhythm prefers one flowing sentence ending in `~는 식이다` / `~는 셈이다`. Two `~한다.` declaratives stacked feel like bullet points.
- BAD: `완성된 아티팩트는 다음 세션의 컨텍스트가 된다. 매번의 수정은 설정으로 반영된다.`
- GOOD: `완성된 아티팩트는 다음 세션의 컨텍스트가 되고, 매번의 수정은 설정으로 쌓이는 식이다.`

**Pattern B — Parallel list ending too abruptly**

A 4–5 item parallel list (`A하고, B하고, C하고, D한다.`) feels like a command when the final beat is bare `~한다.`. Soften the final beat with `마지막에/마지막으로 ~는 식이다` or a similar closing marker.
- BAD: `...더 큰 작업을 위임하고, 루프를 닫는다.`
- GOOD: `...더 큰 작업을 위임하고, 마지막에 루프를 닫는 식이다.`

**Pattern C — Formal/academic word choice in personal essay**

First-person essays prefer everyday words over formal/public-document vocabulary. Soften these where the surrounding text is conversational:
- `관행` → `방식`, `것들`
- `실천하다` → `쓰다`, `하다`
- `제공한다` (repeated) → drop the verb where possible (`앞쪽이 컨텍스트라면, 뒤쪽은 설정이다.`)
- `거치는 바로 그 과정과 다르지 않다` (ornate double-construction) → `우리가 늘 거치는 그 과정 그대로다` (positive, plain)
- `구분하기 위한` → `구분해 두는`
- `이전` → `예전` (when 1인칭 회상 맥락)
- `~별` (프로젝트별, 항목별) → `~마다 두는`, `~마다 있는` where it sounds bureaucratic

**Pattern D — Report-style punctuation (가운뎃점) in essay prose**

The middle dot `·` is for newspaper headlines and technical specs. In essay/blog prose, replace with comma + `이나` / `같은`.
- BAD: `이전 코드·프로젝트 문서·분석 결과 같은 자산`
- GOOD: `예전 코드나 프로젝트 문서, 분석 결과 같은 자료`

**Pattern E — `~할 수 있다` literal-translation closure**

English "can do X" / "to do X" often becomes `~할 수 있다` in Korean and reads as direct translation. When the agent is clear and the meaning is "this results in X" rather than "ability to do X", prefer result-form closures: `~는 셈이다`, `~게 된다`, or active declarative.
- BAD: `결과를 인덱스에 박아 놓을 수 있다.`
- GOOD: `결과를 인덱스에 박아 두는 셈이다.`

**Calibration**: do not overshoot into casual blog. The target is "skilled essayist writing a column" — warmth via rhythm, not via polite endings (still forbidden in body text) or slang. If a passage already breathes naturally, leave it alone.

#### Active localization of generic foreign nouns

The system prompt's preservation rules are for proper nouns and acronyms (`API`, `HTTP`, `Docker`). For **generic foreign nouns** that have settled Korean forms or that the source uses as ordinary words (not as branded products), prefer the Korean form. Being too conservative — preserving every English-looking word as English — produces a translation that feels half-foreign.

Heuristic:
- **Preserve as English**: branded product/library names (`Slack`, `Drive`, `Docker`, `FastAPI`, `Claude Code`), acronyms in the protected list, code identifiers, URLs/paths.
- **Naturalize to Korean**: generic service categories (`Mail` → `메일`), common technical-but-naturalized nouns where Korean form is dominant (`mail`, `email` → `메일`, `이메일`; generic `cloud` → `클라우드` not `Cloud`), generic loan adjectives.
- **Judgement edge cases**: when the source capitalizes a generic word ambiguously (e.g. `Mail` next to `Slack`, `Drive`), check whether the author meant a product. If unclear from context and the word has a fully settled Korean form, naturalize. Document-internal consistency wins — once you naturalize a term, don't switch back.

Examples from real essay context:
- `Slack, Drive, Mail` → `Slack, Drive, 메일` (Slack/Drive are branded; Mail is generic email service)
- `cloud storage` → `클라우드 스토리지` (both halves naturalized)
- `Excel sheet` → `엑셀 시트` if used generically; `Excel` if explicitly the Microsoft product

The cost of being too conservative is real: every English word that survives untranslated is a small visual speed bump for a Korean reader. Conversely, never naturalize a branded name — `Slack` should never become `슬랙` in body text (parenthetical phonetic for first occurrence is OK only if needed).

#### Tracking new terms

Track every **new technical term** you decide to translate that was not in the glossary. Use the existing convention: `{ "English Term": "한국어(원문)" }` — Korean translation followed by the English original in parentheses for first occurrences of acronyms/proper nouns. Plain Korean translations (no parenthetical) are also acceptable for non-acronym terms — match what makes sense given existing glossary style.

#### If chunking

- Carry **2 sentences of working context** from the previous chunk's translation forward as you translate the next chunk. This keeps tone and terminology consistent. Do not emit the carry-over to the file.
- Honor newly discovered terms from chunk N consistently in chunks N+1, N+2, …
- After all chunks are translated, concatenate them with a single blank line between chunks (preserve original document spacing).

### Step 5 — Self-review pass for Korean naturalness (MANDATORY)

Before invoking `Write` in Step 6, **re-read your entire translation once** and walk through this checklist. For each item flagged, rewrite that sentence and re-check. This step is the single biggest determinant of whether the output reads as fluent Korean or as translated Korean. **Do not skip this even for short documents.**

Items 9 (pronouns, A-16) and 15–17 below are **density patterns** absorbed from `translationese-patterns.md`: they depend on whole-document frequency (typically a `3회+` threshold), so this whole-doc re-read is the only correct place to catch them. When chunking, a chunk-local pass cannot count document-wide frequency — these must be checked here, after all chunks are concatenated.

1. **Rhythm.** Any 2+ consecutive short sentences that share a subject/topic and could merge into one breathing Korean sentence? Combine them.
2. **Figurative language audit.** For every vivid metaphor, figurative verb, or image-bearing turn of phrase in the source, did your Korean rendering carry an image of equivalent force — generated from the surrounding argument, not from a fixed mapping? Read each figurative passage in isolation: does the Korean still feel like the image is doing work, or does it read past as filler? If flattened, regenerate using the Metaphor and Figurative Language process (identify → trace → render → calibrate → stay consistent). Also check the cluster: if the author reuses a motif, are your Korean renderings sitting in one coherent cluster instead of drifting between near-synonyms?
3. **Adverb position.** Any `~적으로 + 동사` constructions that mirror English adverb-verb order? Reposition to predicate (`~적이다`) or drop `~적` entirely.
4. **Loanword verbs.** Any English-derived verbs that have natural Korean equivalents? (`스케일시키다` → `확장하다`)
5. **Sentence endings.** Any sentence ending in `~되도록.`, `~할 수 있도록.`, or other awkwardly cut endings that lose closure? Rewrite for a clean final beat.
6. **Em dash fragments.** Any place where you split on em dash but the result feels choppy with repeated words (e.g. `무엇이든 ... 무엇이든`)? Try collapsing to parenthetical or comma.
7. **Glossary collision.** Did any glossary mapping produce an unnatural English-in-Korean sentence for a generic-noun usage? Override per the glossary-vs-generic-noun rule.
8. **Active voice.** Any passive constructions (`~되어지다`, `~에 의해 ~된다`) that should flip to active? Convert.
9. **Subject omission & 영어 대명사 직역 (A-16).** Any subjects you carried over from English that Korean would naturally drop when the referent is clear from context? Drop them. **Extend this to English pronouns** (`he/she/it/they` → `그/그녀/그것/그들`): when a paragraph carries 3+ personal pronouns, treat 50–70% of them as deletion candidates and restructure — but only where dropping them does not create '누가 무엇을' ambiguity (verify against the English source). Render `they` as `사람들·일부·어떤 이들`, not reflexively `그들`. This is a 구조 재구성형 pattern — apply in proportion to the chosen 의역 강도. (See translationese-patterns.md.)
10. **Unnecessary English parenthetical.** Did you bracket an English word for a common noun like `사실(facts)`, `주석(annotated)`? The first-occurrence-with-original rule applies to **acronyms, proper nouns, and technical terms** — not to ordinary words. Remove unnecessary parentheticals.
11. **Idiom completeness.** Any vivid Korean idiom that fits better than your literal rendering? Swap in.
12. **Stiff-register audit (Patterns A–E).** Walk the five stiffness patterns from the Conversational warmth section:
    - (A) Two consecutive crisp `~한다.` declaratives that should merge into one `~는 식이다` breath?
    - (B) A 4–5 item parallel list ending bare with `~한다.` that should close with `마지막에 ... ~는 식이다`?
    - (C) Formal/academic word in 1인칭 essay context (`관행`, `실천`, `~별`, `거치는 바로 그 과정과 다르지 않다`)?
    - (D) `·` middle dot in essay prose where comma + `이나`/`같은` would breathe better?
    - (E) `~할 수 있다` literal closure where the meaning is result, not ability — swap to `~는 셈이다` / `~게 된다`?
13. **Localization aggressiveness.** Any generic foreign noun preserved as English where the Korean form is fully settled and the source word is not a branded product? (`Mail` → `메일`, generic `cloud` → `클라우드`, etc.) Naturalize; don't be over-conservative. But never naturalize a branded name (`Slack` stays `Slack`, not `슬랙`).
14. **Frontmatter integrity.** If the source has YAML frontmatter, did every field — especially `title` — stay byte-identical to the source? Translating frontmatter fields is a structural change that breaks tool linkages. Revert any field that was modified.
15. **이중 조사 결합 (A-19, density).** Scan the whole document for double-particle stacks (`~에서의·~에로의·~으로의·~에의·~으로부터의·~로부터의`). At 3+ occurrences, unfold them into clauses/phrases (`긴장으로부터의 해방 → 긴장에서 벗어남`). 단순 `~의`는 제외(caveat C5). 표면 교정형 — apply at every 의역 강도. (See translationese-patterns.md.)
16. **Hedging 남발 (G-1/G-2, density).** Are observation-form endings (`~로 보인다`/`~인 듯하다`/`~로 판단된다`) or double/triple hedges (`~할 가능성이 있을 수 있다`/`~로 보여질 수 있다`) piling up across the document? Assert where the English source asserts; keep one hedge layer only where the source itself hedges. 표면 교정형 — apply at every 의역 강도. (See translationese-patterns.md.)
17. **메타 진입 (H-3, density).** Count meta-entry phrases (`이는 ~을 의미한다`/`이 점에서`/`이 관점에서 보면`/`이 말은`). At 3+ occurrences, merge into the preceding sentence or state the content directly (`이는 X를 의미한다 → X다`). 표면 교정형 — apply at every 의역 강도. (See translationese-patterns.md.)

After this pass, the translation should read as if originally written in Korean by a skilled essayist. If you finish the checklist and made zero rewrites, you have probably skimmed — go back and re-read with fresh eyes once more.

### Step 6 — Write the output file

- Compute the output path per the argument parsing rules: the `--output` path if given, otherwise the input file path itself (in-place overwrite).
- Use `Write` to save the translated text. Write **raw markdown only** — no code fences, no JSON wrapper, no commentary.
- When `--output` is given, leave the source input file untouched. When `--output` is omitted, `Write` overwrites the input file with the translation — no backup is made, so the original English is replaced.

### Step 7 — Update the glossary (only if new technical proper nouns were discovered)

**Scope rule (MANDATORY)**: The glossary is a controlled vocabulary for **technical proper nouns only**. Its value comes from forcing the same domain-specific term to be rendered identically across documents.

- **OK to register**: product/library/framework names (FastAPI, Docker, LangChain), API/SDK names, technical acronyms with expansion (MCP, RAG, KV cache, RLHF), named architectures/patterns with established Korean translations (Hexagonal Architecture, Transformer block), domain-specific industry/academic terms with a settled translation.
- **NEVER register**: metaphors and figurative expressions (`compound`, `blast radius`, `flow state`, `close the loop`), idioms (`hit the ground running`, `low hanging fruit`, `elephant in the room`), general English phrases that translate naturally (`blank slate`, `new hire`, `knowledge work`, `do the heavy lifting`), common adverbs/adjectives (`holistically`, `genuinely uncertain`), or plain nouns that would be rendered differently depending on context.

**Why this matters**: registering a metaphor or general phrase forces every future translation to use the same Korean mapping even when the surrounding argument calls for a different image. That kills natural rhythm and metaphor work (see Step 4 — Metaphor and Figurative Language). When in doubt, **do not add**. If the same phrase shows up in a future document, re-render it from context.

**How to update if (and only if) new technical proper nouns were discovered**:

1. `Read` the glossary file again — it may have changed since Step 1.
2. Merge new terms in. **Do not overwrite** existing keys. If a discovered term collides with an existing key, skip the new one and keep the existing translation.
3. Use `Edit` (preferred) or `Write` to update the glossary file:
   - JSON formatting: 2-space indent, UTF-8, **preserve Korean characters as-is** (do not escape to `\uXXXX`).
   - Append new entries at the end, preserving the order of existing keys.
   - Validate the file is still valid JSON before exiting.

If no new technical proper nouns were discovered, leave the glossary file untouched. Report `New terms added: 0` in Step 8.

### Step 8 — Report

Print a single concise block to the user:

```
✓ Translated → <output_path>
  · Source: <input_path> (<char_count> chars)
  · Chunks: <N>
  · Glossary applied: <filtered_count> terms
  · New terms added: <new_count>
  · Self-review rewrites: <~count of sentences rewritten in Step 5>
```

Do **not** print the translation contents to the chat. The file is the deliverable.

## Hard rules

- Do not emit JSON wrappers — the system prompt's `<output_format>` section is overridden by this command.
- Do not include the original English text alongside the translation (this is a common heading mistake — replace, never duplicate).
- Do not paraphrase code, identifiers, URLs, or file paths.
- Do not invent glossary terms that don't appear in the source.
- **Do not skip Step 5 (self-review).** This is the rule that separates competent translation from fluent translation.
- **번역투 패턴은 source-blind 후처리를 하지 않는다.** 모든 흡수 패턴(translationese-patterns.md)은 영어 원문과 대조하며 고친다 — 한글 출력만 보고 추정하지 않는다. 이것이 후처리 파이프라인 대신 흡수를 택한 핵심 이유다(source-access 우위 유지).
- Do not modify markdown structure that is not in the source (no extra horizontal rules, no inserted blockquotes, etc.).
- If you must stop partway (e.g., context constraint), write what was completed and tell the user exactly where the boundary is and what remains.
