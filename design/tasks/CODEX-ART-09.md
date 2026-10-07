# CODEX-ART-09 · Frame-by-frame sprite review and fixes (all v2 sheets)

- Request: 사용자 "스프라이트가 조금씩 잘려서 어색한 부분들이 보였다. … 스프라이트 하나하나씩을 보고 분석 하면서 어색함이 있나를 확인할것." and "Codex를 적극 활용할것." (2026-10-08, 취침 루틴 `routine/2026-10-08-night/`)
- Unit: Builder (reviewer + fixer) · Lead (integrates, decides, verifies with its own detector): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/sprite-fix-a`
- Running at the same time: Codex builder `codex/ult-vfx-b` (ultimate effect art). The lead edits product source. **This task does not edit product source.**
- Timeout: given in the prompt.

## Scope: 8 sheets, 23 used frames each (184 frames)

`smash-nine-prototype/assets/art/`: `frey/frey_sheet.png`, `yuki/yuki_sheet.png`, `luna/luna_sheet.png`, `luna/luna_brave_sheet.png`, `nova/nova_male_sheet.png`, `nova/nova_female_sheet.png`, `rio/rio_male_sheet.png`, `rio/rio_female_sheet.png`.
Contract (unchanged, `design/tasks/CODEX-ART-08.md`): 768x896, 6 columns x 7 rows of 128x128 cells, rows idle 4 / walk 6 / jump 1 / fall 1 / attack 4 / shield 6 / hurt 1, facing right, feet y=120, centre x≈64, drawn at 1x. Head ratios: Frey 3, Rio 3, Nova 2.5, Yuki 2.5, Luna/Brave Luna 2.2. Keep the accepted designs (and the main illustrations in each folder).

## 1. Review every frame (look at each one enlarged)

The user played the deployed build and saw sprites that look "slightly cut". Known example: in several attack and shield frames a slash arc or shield glow ends in a **straight vertical or horizontal cut a few pixels inside the cell** (the first-pass art was clipped at the cell border, then the outer 2 px ring was erased). Check each frame for:

- **cut**: weapon, hair, cape, slash arc or shield cut by a straight edge anywhere in the cell
- **fragment**: floating pieces that belong to a neighbouring frame, or stray pixels
- **pose**: broken anatomy, missing hand/weapon, a frame that does not read as its row (idle/walk/jump/fall/attack/shield/hurt)
- **jump**: size, proportion, colour or feet/centre jumps between consecutive frames of the same row; idle frames that are pixel-identical (no breathing)
- **design**: drift from the character's accepted design (outfit, palette, weapon) or between the male and female sheet of the same character

Write the list as a table: sheet, row, column, issue type, description, severity (high = visible in play, low = only enlarged).

## 2. Fix

Redraw or repair every high and medium issue. Rules:

- Everything stays **inside its cell with at least 4 px of transparent margin**. A slash arc or shield glow that does not fit must be made smaller or end with a natural taper; never cut. Large effects are drawn by the game separately (ultimate effects are being made by the other unit), so the sheets only need the body, the weapon and small motion effects.
- No straight cut edges, no fragments, no colour halo around outlines.
- Keep feet y=120, centre x≈64, head ratio and height (idle height within +6 px of: Frey 100, Rio 98/96, Nova 92/90, Yuki 88, Luna 84).
- Idle frames must differ (breathing / hair / cape motion), walk frames must form a readable cycle.
- Unchanged frames stay pixel-identical. Generate with your image tool where a frame needs redrawing; clean and align with Godot's Image API from a script; do not install packages or download files.

## Writable paths

| Path | For |
| --- | --- |
| `smash-nine-prototype/assets/art/{frey,yuki,luna,nova,rio}/*_sheet.png` (+ `.import`), new `*_fix_source.png`, the folder `README.md` | fixed sheets |
| `smash-nine-prototype/tests/art_preview/sprite_fix_a/**` | review and fix scripts |
| `reports/codex-art-09/**` | review table, per-frame before/after crops, contact sheets |

Forbidden: product source, existing tests, illustrations and faces, `design/`, merging, pushing, installing packages, downloading files.

## Report (`reports/codex-art-09/README.md`, Korean)

- The full review table (all issues found, including the ones you chose not to fix and why).
- For each fixed frame: before/after crop at 4x side by side (one combined image per sheet is fine).
- Per sheet: feet row, centre x, idle height per frame after the fix.
- What a human must judge.
- Commit, or `reports/codex-art-09/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
