# CODEX-QA-23 · Every character and monster sprite sheet, measured and looked at

- Request (2026-10-25, the user's status check, relayed by the check session): "스프라이트 시트 전수 점검(가장 먼저): 모든 캐릭터·몬스터 시트의 프레임 크기, 고정 폭 슬라이싱, 행 높이·발 위치 정렬, 빠진 프레임, 팔레트 이상." The image/sprite session repairs what you find; **you change no art.**
- Base: tag `checkpoint-2026-10-25` (`main` `c51a417f`). Your folder is a plain export of that commit (no `.git`).
- Unit: Analyst. Folder `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/qa-a/SmashNine`.
- Running at the same time: one Godot unit (QA-24..26) in `qa-b`, and other sessions' Codex units. **You do not run Godot.** Use the Codex runtime Python (`C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`, numpy and Pillow). One process at a time.

## Read first
- Row tables (frame counts, fps, which sheet row each animation starts on): `characters/common/PlayerBase.gd` (`ORIGINAL_SHEET_ROWS`, `SHEET_COLUMNS`, `SHEET_FEET_Y`, `_add_sheet_animations`, `_add_move_sheet_animations`, `OPTIONAL_MOTION_ROWS`, `_add_optional_motion_strip`), each `characters/*/[A-Z]*.gd` (`SHEET_ROWS`, `MOVE_SHEET_ROWS`; Luna's Brave tables). A row longer than 6 frames continues on the next sheet row.
- Monsters: `scripts/RealmMonster.gd` (`ART_ROWS`, the six-row sheets, `_build_art_sprite`, the Jotunheim golem feet exception), `scripts/monsters/MonsterProjectile.gd` (projectile strips).
- The checks the game already runs: `tests/test_sprite_frames.gd`, `tests/test_moves_sheet.gd`, `tests/test_monster_motion.gd`, `tests/test_fighter_motion.gd`. Do not repeat them blindly; say where your measurement goes further.
- Rules the art must follow: `design/DECISIONS.md` D32–D35 (everything inside the cell with an empty 1-px border, one head size per character, effects drawn apart, no pasted parts; 128-px main cells with feet at y=120, 192-px move cells with feet at y=152), `assets/art/README.md`, the earlier inspection `reports/codex-qa-18/README.md` (its method; many of its rows were redrawn since).

## Scope, in this order
1. **In the game now** (highest): the 8 bodies `frey, luna, luna_brave, nova_male, nova_female, rio_male, rio_female, yuki` — `<stem>_sheet.png` and `<stem>_moves_sheet.png` under `smash-nine-prototype/assets/art/<id>/`; the 18 monster sheets `assets/art/monsters/*_sheet.png`; the monster projectile strips `*_projectile.png` and `ember_fireball.png`.
2. **Candidates waiting for the user's pick** (`art/bakeoff/<id>/*.png` with their `.json` sidecars, and `art/bakeoff/monsters/`): measured checks for all; look by eye only at the ones the measurements flag. Do not judge style or pick between candidates.

## Per sheet, measured
- Cell size: width ÷ 6 is an integer and matches the table (128 main, 192 moves, the monster cell from width ÷ 6); height = rows used × cell; no leftover rows or columns with pixels.
- **Fixed-width slicing**: pixels touching a cell edge, a body that continues across a cell boundary, a frame whose bbox centre jumps by about a cell fraction from its neighbours, or two figures in one cell. Give the cell and the pixel count on the edge.
- Empty 1-px border and the 4-px margin (D32).
- Row height and size: per frame the body bbox height, width and silhouette area; the spread inside a row and the jump between neighbouring frames; the row's first frame against idle.
- **Feet**: the lowest opaque row of each ground frame against 120 (128 cell), 152 (192 cell), the monster's feet line (3/4 of the cell; the golem exception); say which rows are airborne and skipped.
- **Missing frames**: a fully empty cell inside the frame count, a frame identical to its neighbour, a row with fewer drawn frames than its table says, drawn cells beyond the table.
- **Palette**: the sheets have no fixed palette since D35 (LANCZOS + sharpen, green background removed), so look for colour faults, not palette size: green-screen spill and leftovers (the D35 de-spill), magenta or near-white halos, partial alpha (0 < a < 255) counts and where they sit, colours far from the rest of the same body (e.g. a frame whose skin or hair hue jumps against idle), isolated stray pixels. Also the head size against idle where `<sheet>_heads.json` or `tools/sprite_pipeline/head_scale.py` gives it (D34: 0.96–1.04).

## Look
For each in-game sheet make one contact image (each row at 2×, the idle frame at the left, frame numbers under each frame, the cell grid drawn) and look at it with view_image. Report only what you saw: cut parts, two heads, smears, effects drawn into the body, a frame that does not belong to the row.

## Report
- `reports/codex-qa-23/README.md` (Korean): first a summary table (sheets checked, problems by kind and severity 상/중/하), then per sheet a table of rows: verdict **좋음 / 손질 / 다시 그림**, frame numbers, the reason, the numbers. Separate measured from guessed.
- `reports/codex-qa-23/fix-list.md` (Korean, for the image/sprite session that repairs): one line per problem, most visible first (in-game idle, walk, J chain, K, L, jump/fall, hurt, then the rest; candidates after the in-game sheets): file · row · frame(s) · problem · measured number · repair kind (move, crop/pad, re-slice, clean pixels, redraw).
- Contact images `reports/codex-qa-23/contact/`, numbers `reports/codex-qa-23/metrics/*.json`, scripts `smash-nine-prototype/tests/analysis/codex_qa_23/*.py`. No `.csv` inside `smash-nine-prototype/`.
- `reports/codex-qa-23/files.txt`: every file you wrote (there is no git here; the lead commits).

## Writable
`reports/codex-qa-23/**`, `smash-nine-prototype/tests/analysis/codex_qa_23/**`. Nothing else.

Hard stop: 120 minutes. If time runs short, finish scope 1 and list what is left.
