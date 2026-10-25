# SART-01 · Story scene pictures for the narration stages (candidates)

- Request: the user, through the status-check session, 2026-10-25: the Codex quota was reset; work that needs no user decision, mainly image and sprite repairs and additions. Story mode area (D43): add the scene pictures that are missing.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine`, branch `codex/sart-01` (from tag `checkpoint-2026-10-25`). Lead: Claude (reviews every image at full size).
- Running at the same time: SART-02 (stage title cards) in the story-art-b clone. Other sessions run their own units. You share no files with anyone.
- **Candidates only.** Nothing under `smash-nine-prototype/` changes; the game is not wired to these files.
- Read first: `reports/story-mode-plan-2026-10-22.md` section 5, `design/STORY.md` (stages 5, 7, 9), `smash-nine-prototype/assets/art/story/README.md` (how ART-70's three scene pictures were made; same contract here), `reports/codex-art-70/PROMPTS.md`.

## Why

Stage 1 (prologue), stage 8 (the root) and stage 9's ending already have a full-screen picture behind their narration (ART-70). The other narration scenes show only the arena behind the dialogue box: stage 5 (Vanaheim falls), stage 7 (the beast of fire) and the opening of stage 9 (the heart, where the shadows rise).

## Image spec (one row group per picture)

Common to all three:

| Line | Spec |
| --- | --- |
| Size | final **1600×900**, opaque. Generate landscape at the largest size offered, crop to 16:9, downscale with LANCZOS; never upscale (if the raw is under 1600 px wide, final 1280×720). |
| Style | the same painted pixel art as ART-70: attached refs 1 `cg_prologue.png` (style anchor) and 2 `title_bg.png`; visible pixel clusters, no airbrush; deep navy sky with galaxies where the sky shows |
| Bottom quarter | dark and quiet, little detail (the dialogue box covers it) |
| Avoid | people, faces, figures, statues of people, text, letters, glyphs, logos, UI, frames, borders, watermark, photographic look |
| Text | **none** |

### `cg_forest` — stage 5, behind `story.s05.pre.1–2` ("숲의 세계 바나헤임이 무너지기 시작했다 …")

| Line | Spec |
| --- | --- |
| References | 3 `realm_vanaheim/bg_far.png` (the realm's palette and temple), 7 `objects/soul_crystal.png` (the crystals) |
| Must show | the forest realm island breaking apart: giant trees and a mossy stone temple tilting, roots tearing out, chunks of ground falling into the void below, a vine bridge snapping; green and gold forest light with a red-orange collapse glow along the cracks; **three** violet soul crystals glowing among the ruins at different heights |
| Palette | deep green `#0e3b2a`, moss `#3f7d3a`, gold light `#e8c86a`, collapse glow `#ff6a3d`, crystal violet `#b77cff` |

### `cg_beast` — stage 7, behind `story.s07.pre.1–2` ("불의 땅 무스펠헤임 … 거대한 마그마 멧돼지가 땅을 긁는다")

| Line | Spec |
| --- | --- |
| References | 4 `realm_muspelheim/bg_far.png` (lava realm), 6 `art/bakeoff/monsters/muspelheim_magma_boar-idle-v1.png` (the boar's design: dark rock body, glowing lava cracks, spiked back, curved tusks) |
| Must show | a **giant magma boar** in that design, low-angle, lit from below by lava, pawing the ground ready to charge, smoke and embers; eruption pillars behind it; it is the only creature |
| Palette | rock `#2a1410`, lava `#ff5a1f`, hot core `#ffd27a`, smoke `#4a2a2a` |

### `cg_heart` — stage 9, behind `story.s09.pre.1–2` ("이그드라실의 심장. 쓰러뜨린 이들의 소울이 그림자가 되어 일어선다 …")

| Line | Spec |
| --- | --- |
| References | 5 `realm_center/bg_far.png` (the heart arena), ref 1 for the heart's look |
| Must show | the final arena under the world tree: a circular floor of roots and stone; above it the **twisted** pink heart (cracked, dark violet veins, glowing); from the floor **five** pillars of dark violet soul flame rise toward the heart (abstract flames only — no faces, no bodies, no silhouettes of people); faint pink light motes |
| Palette | violet `#3b1d5e`, dark flame `#1a0f2e`, flame edge `#9b5cff`, heart `#ff4fd8`, crack light `#ffd6f5` |

## Variants, checks, deliverables

- **Two clearly different variants per picture** (six generations). Pass the attached references to `image_gen` as reference images, not only as chat context.
- Raw generations go to `art/raw/story/` (git-ignored) under the names `<name>-vN_raw.png`.
- Candidates go to `art/bakeoff/story/<name>-vN.png` (1600×900), each with `<name>-vN.json`:
  - `note` in Korean: what it shows and how it differs from the other variant
  - `for_lines`: the story.csv IDs it sits behind
  - `size`, `processing` (crop box, resize)
- Check each variant against every spec line (pass/fail). Measure: exact size, mean brightness of the bottom quarter vs the top three quarters, colour distance to the palette. Look at every picture at full size for text-like marks, faces or figures before reporting.
- **Contact sheets** in `reports/codex-sart-01/`, one per picture: both variants at 1280×720 with a dark band over the bottom quarter where the dialogue box goes, plus the ART-70 `cg_prologue` next to them for style. Save as JPEG quality 90, at most 2 MB each.
- `reports/codex-sart-01/README.md` in Korean:
  - per picture the variants, the pass/fail table, the final prompts, the processing
  - which variant you would recommend and why. The user picks later.

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `art/bakeoff/story/**` | candidates and their JSON |
| `art/raw/story/**` | raw generations (git-ignored) |
| `reports/codex-sart-01/**` | report and contact sheets |

Forbidden: `smash-nine-prototype/**`, `design/**`, other sessions' files, merging, pushing, installing packages, downloads.

## Done when

- [ ] Six candidates with JSON in `art/bakeoff/story/`, contact sheets and README in `reports/codex-sart-01/`.
- [ ] Commit on the branch, or `reports/codex-sart-01/commit.ps1` staging only the writable paths (not `art/raw/`), message ending `Co-Authored-By: Codex <noreply@openai.com>`.
