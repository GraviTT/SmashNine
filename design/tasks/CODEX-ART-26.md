# CODEX-ART-26 · Per-move sprite rows for Nova, Yuki, Rio (art only)

- Request: same run as CODEX-ART-23..25 (사용자 2026-10-10 20:00 "코덱스 한도 소모를 위해, 코덱스에 이미지, 스프라이트 생성 명령 내릴것."; "Claude는 명령과 검수만"). Run plan: `routine/2026-10-10-work/README.md`. Next characters in order are Nova, Rio, Yuki (D31).
- Unit: Builder (images) · Clone `SmashNine-units/builder-frey/SmashNine`, branch `codex/moves-26`
- Running at the same time: `codex/moves-23` (Frey/Luna move sheets + the loader in `PlayerBase.gd`) and `codex/monsters-ui-25`. **Art only this time: do not edit product code** — the loader from ART-23 will pick these sheets up once each character gets a row table. Headless Godot only, short runs.
- Read first: `design/tasks/CODEX-ART-23.md` (the moves-sheet contract you must follow), `reports/codex-art-21/README.md` ("기술별 추가 행 제안" as the model), `characters/nova/Nova.md` + `Nova.gd`, `characters/yuki/Yuki.md` + `Yuki.gd`, `characters/rio/Rio.md` + `Rio.gd`, the sheets and READMEs in `assets/art/{nova,yuki,rio}/`.

## Make
1. A row table per character first (row name, frames 4–6, poses, which move/input uses it), covering every move that today reuses the 4-frame attack row: ground J chain, up/down J, air J, K, L, I (ultimate start). Put it in the report and the sheet README.
2. Sheets, in this order (stop where time runs out, finished sheets only):
   - `assets/art/nova/nova_male_moves_sheet.png`, `nova_female_moves_sheet.png`
   - `assets/art/yuki/yuki_moves_sheet.png`
   - `assets/art/rio/rio_male_moves_sheet.png`, `rio_female_moves_sheet.png`
   Each 6 columns × N rows of 128×128 (width 768), rows in the table's order, frames left-aligned, unused cells transparent, + `<name>_README.md` (row table, fps, prompts, checks).
- Same character as the live sheet of that body (pass it and the matching `*_illustration.png` as image references every time): head ratio, palette, outline, pixel density and body size as the idle row. Ground poses feet on y=120; air poses body centre like the jump/fall rows. Alpha 0/1, no stray pixels, no text. Rio: draw attack poses at the idle body size (his live attack/shield rows were shrunk per frame — do not copy that).
- The two bodies of one character share the row table and poses.

## Verify and report
- Contact sheets in `tests/art_preview/moves_26/`: each row at 1x and 4x next to the idle frame of the same live sheet. Measure feet y, body height vs idle (±4 px), alpha 0/1, palette distance. List the rows you think are weak.
- Writable: the new `*_moves_sheet.png` + `*_moves_README.md` (+ `.import`) in `assets/art/{nova,yuki,rio}/`, `tests/art_preview/moves_26/**`, `reports/codex-art-26/**`. Keep image-gen originals named `*_source.png`; previews under ~15 MB.
- Report `reports/codex-art-26/README.md` (Korean). Commit, or `reports/codex-art-26/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
