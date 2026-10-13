# CODEX-ART-35 · Shared sprite pipeline (normaliser) + motion viewer bake-off

- Request: 사용자 2026-10-13 "CuSurvive/docs/sprite-motion-guide.md 이 내용을 확인하여, 다른 게임 작업에서 효과적으로 적용중인 스프라이트 제작 방법을 분석하라. 그리고 다시 전체 캐릭터 점검을 위한 루틴에 들어간다." Analysis: `reports/sprite-method-analysis-2026-10-13.md`. Rules: `design/DECISIONS.md` D32.
- Unit: Builder (tools, no image generation) · Clone `SmashNine-units/builder-art/SmashNine`, branch `codex/pipeline-35`
- Running at the same time: analyst `codex/inspect-18` (CODEX-QA-18, read-only on the art, writes reports). Keep CPU-heavy work short.
- Read first: `C:/Users/TH/Documents/AI/GameProject/CuSurvive/scripts/run-bakeoff/README.md`, `normalize.py`, `test_normalize.py` (read-only: the tool that works in the other game — port its ideas, do not edit that repository), `C:/Users/TH/Documents/AI/GameProject/CuSurvive/docs/sprite-motion-guide.md`, `characters/common/PlayerBase.gd` (`ORIGINAL_SHEET_ROWS`, `SHEET_FEET_Y`), the move-row tables in `characters/*/[A-Z]*.gd`, `tools/motion_viewer/` (build.mjs, index.html, README).
- Python: the Codex runtime `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). No installs.

## Part 1 — `tools/sprite_pipeline/` (required)
`normalize.py` turns one generated motion (a sheet of square cells, chroma green or alpha background) into the SmashNine contract:
- Output a horizontal strip of **128×128 cells, frames left-aligned in 6 columns** (one row of a game sheet), plus `frames/`, `closeup.png` (2× with the y=120 line), `metrics.json`, `compare.png` (the current game row above the candidate, both at 2×, with the idle frame of the same sheet at the left).
- **One common scale for every frame** — `fixed:<factor>` or `height:<px>` (median contact-frame body height). Print the factor so it can be reused for the character's other motions. No per-frame scaling, ever; no head-based scaling.
- Contact feet on **y=120**; airborne frames keep their authored lift. Side view (no 3/4 assumptions).
- **D32 rule 1**: zero opaque pixels on each cell's 1-px border; report the 4-px margin the main sheets need (`tests/test_sprite_frames.gd`). If a frame does not fit at the common scale, **fail with a message** (the lead regenerates) — never shrink that frame.
- Background: `--bg #00ff00 | alpha | auto` (connected field from the border); a `prepare_raw.py` step that flattens near-green and removes grid lines the generator may draw.
- Palette: `make_palette.py <sheet>` writes a per-character palette from the current game sheet (`tools/sprite_pipeline/palettes/<id>[_<body>].json`, all 8 bodies: frey, luna, luna_brave, nova_male, nova_female, rio_male, rio_female, yuki); `normalize.py --palette` maps to it without dithering and reports violations; binary alpha.
- Optional `--outline auto` like CuSurvive (only bridges 1-px holes in existing dark outline, never grows the silhouette).
- `--reference <sheet>:<row>:<count>` for `compare.png`; `--title`.
- `metrics.json`: per frame body height/width/area/bottom/lift, colour count, palette violations, alpha state, border and margin; per set the ranges.
- `test_normalize.py` (synthetic: background removal, one scale, y=120 contact, lift kept, palette-only, binary alpha, border failure).
- Validate on real generations already in the repo (`smash-nine-prototype/tests/art_preview/walk_34/*/*source*.png`, `frey_redo_32/*_body_source.png`, `frey_heads_33/`): show `compare.png` for three of them and the factor used.
- `README.md` (Korean + command examples).

## Part 2 — motion viewer bake-off (required)
- Candidates live **outside the Godot project**: `art/bakeoff/<id>/<stem>-<row>-v<N>.png` (a strip from Part 1; `<stem>` = `frey`, `nova_male`, ...; `<row>` = a row name of that sheet, e.g. `walk`, `spike_followup`), optional `…-v<N>.json` `{ "note": "...", "fps": 14 }`.
- `tools/motion_viewer/build.mjs` adds them to the manifest under the matching row; `index.html` shows, for the selected row, **current and each candidate side by side on the stage, playing in sync** (same frame index, same zoom and guides), with the candidate's version and note; tiles of rows that have candidates get a small "후보 N" badge. Keep the page's look, both themes, phone width, no new libraries.
- Seed one example candidate from Part 1's validation so the lead can see it working; update `tools/motion_viewer/README.md`.

## Writable
`tools/sprite_pipeline/**`, `tools/motion_viewer/build.mjs`, `tools/motion_viewer/index.html`, `tools/motion_viewer/README.md`, `art/bakeoff/**`, `reports/codex-art-35/**`. No product code, no game sheets, no `.csv` inside `smash-nine-prototype/`. Hard stop 70 minutes after you start. Report `reports/codex-art-35/README.md` (Korean): usage, the three validation results with numbers, limits. `commit.ps1` (writable paths only, message ending `Co-Authored-By: Codex <noreply@openai.com>`).
