# CODEX-ART-01 · Center realm art vertical slice (Yggdrasil Heart)

- Request: 사용자 "다음 작업은? 가능하면 그래픽, 캐릭터 개발, 대규모 수정 쪽으로." (2026-10-07, 근무 루틴 `routine/2026-10-07-work/`)
- Unit: Builder · Lead (integrates, decides): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/art-01`
- Running at the same time: Codex builder `codex/frey-art-01` (Frey sprites, also image generation). The lead edits `smash-nine-prototype/scripts/` and `characters/` meanwhile. **This task does not edit product source.**
- Timeout: 90 minutes. Deliver whatever is finished before then.

## Read first

1. `AGENTS.md`, `design/DECISIONS.md` (D5, D6, D12), `smash-nine-prototype/FINAL_GAME_GOAL.md` ("Art Direction")
2. `smash-nine/Concept1.png`, `smash-nine/Concept2.png` (attached): tone of the central arena and realm backgrounds
3. Current look: `reports/screens-compat/05_center_open.png`, `06_sudden_death.png`; code that draws it: `smash-nine-prototype/scripts/RealmBackdrop.gd` (theme `starfall_shrine`), `scripts/realms/RealmWorld.gd`, `scripts/realms/RealmCatalog.gd` (Yggdrasil Heart layout: 1920x1080, platform rects)

## Goal

Original art for the central realm "Yggdrasil Heart" (the final arena) that the lead can drop in behind a toggle:
2D pixel-art fantasy, dark cosmic purple/indigo with a glowing world-tree heart, matching the concept art, but **quiet enough that small fighters (about 64x128 px on screen), hit sparks and red sudden-death zones stay readable**.

## Deliverables (all PNG, RGBA, in `smash-nine-prototype/assets/art/realm_center/`)

| File | Size | Use |
| --- | --- | --- |
| `bg_far.png` | 1920x1080 | sky / distant world tree, fully opaque |
| `bg_mid.png` | 1920x1080 | ruins / roots silhouettes, transparent where empty (drawn over bg_far, behind platforms) |
| `platform_main.png` | 3 slices in one strip: left cap, repeatable middle, right cap; 54 px tall | the long ground platform (1500x54 in game) |
| `platform_sub.png` | same 3-slice strip, 30-34 px tall | thin one-way platforms (220-360 px wide) |
| `portal.png` | 96x96, transparent | portal visual |
| `contact_sheet.png` | any | all of the above + a mock frame composed at 1920x1080 with platforms at the RealmCatalog positions |
| `README.md` | — | prompts used, slice widths in px, palette, how each file is meant to be drawn (stretch / tile / 9-slice margins) |

Pixel-art look: generate large, then reduce to a consistent pixel scale (e.g. draw at 960x540 and scale 2x nearest), limited palette. Post-process with Godot's Image API from a script or the bundled runtime; do not install packages.

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `smash-nine-prototype/assets/art/realm_center/**` | the deliverables (+ Godot `.import` files) |
| `smash-nine-prototype/tests/art_preview/realm/**` | preview/composition scripts |
| `reports/codex-art-01/**` | report, screenshots |

Forbidden: product source (`scripts/`, `characters/`, `scenes/`, `project.godot`), existing tests, `design/`, merging, pushing, installing packages, downloading files.

## Verification

- Compose the mock frame in Godot (windowed run of your own preview script) with the real platform rectangles and two fighter sprites from `assets/characters/` for scale; screenshot it into the report.
- State measured facts (sizes, colours) separately from taste judgements. Taste is the user's call.

## Done when

- [ ] Deliverables above, `reports/codex-art-01/README.md` in Korean (what was made, prompts, integration notes for the lead, readability concerns, what a human must judge)
- [ ] Commit, or `reports/codex-art-01/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`
