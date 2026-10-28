# CODEX-QA-30 · Check the applied candidate picks, then capture the evidence screens

- Request (사용자 결정, 2026-10-29, 점검 세션 전달): "결정된 222줄을 게임에 적용한다 … 테스트·웹 빌드까지 하고, main에 합치기 전에 사용자 확인을 받는다." The lead applied them on branch `apply/candidates-2026-10-29` (`0cb48937`) and asks for an independent check and screen captures.
- Unit: Tester. Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-b/SmashNine`, branch `codex/qa-30` (= `0cb48937`).
- Running at the same time: the lead's full test suite and bot soak in another clone (CPU is busy). Do not run soaks; one windowed Godot at a time.
- Never edit product source or assets (`smash-nine-prototype/scripts/`, `characters/`, `scenes/`, `assets/`, `project.godot`). Findings go to the lead.

## Setup
`.godot/` does not exist yet: run `<godot> --headless --path smash-nine-prototype --import` twice (the first pass prints missing-translation errors; the second must be clean). Godot console: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`. Known sandbox noise: `ERROR: Failed to read the root certificate store.` — report it separately.

## Part A · Independent check of the apply (scripted, about 15 minutes)
Inputs: `reports/apply-2026-10-29/picks-snapshot.json` (222 rows; `choice` "none" = keep the game's picture), `applied.json` and `apply_picks.py` (how the lead applied them), the checkpoint `c51a417f` (`git show c51a417f:<path>` for the old game files), `smash-nine-prototype/assets/art/README.md`, `assets/art/monsters/README.md`, `characters/common/PlayerBase.gd` (`OPTIONAL_MOTION_ROWS`, `_add_optional_motion_rows`), `scripts/RealmMonster.gd`.
Check from the pictures, not from `applied.json`:
1. Every picked row: the game file holds exactly the picked candidate's pixels. Fighter strips `assets/art/<folder>/<stem>_<row>.png`: the candidate's first N cells (N from the row table, the rest of the candidate canvas empty). Rows inside sheets (Frey `attack`, Rio `walk`, Rio female `mana_combo`): the sheet cells of that row equal the candidate. Portraits and projectiles: same pixels as the candidate.
2. Every "none" row: the game picture equals the checkpoint's (strip absent if it was absent; sheet cells unchanged).
3. Monster sheets (18): 576×576; rows idle / walk / windup / attack / hurt / defeat; rows 1, 2, 4, 5 equal the kept 4-row picture (the QA-23 repair `art/bakeoff/monsters/legacy/<id>_sheet-fix1.png` where the pick is `fix1`, else the checkpoint sheet; the golem's kept rows lifted 7 px), rows 3 and 6 the picked windup and defeat; unused cells empty; the lowest drawn pixel row per sheet row.
4. `git diff --name-status c51a417f HEAD -- smash-nine-prototype/assets` lists only the expected files (no other picture changed).
Write `reports/codex-qa-30/apply-audit.json` and a table in the README: rows checked, mismatches (none expected), anything surprising.

## Part B · Evidence captures (windowed Godot, real scenes and real assets)
Write `smash-nine-prototype/tests/analysis/codex_qa_30/capture_apply.gd` and run it windowed: `<godot> --path smash-nine-prototype -s tests/analysis/codex_qa_30/capture_apply.gd -- --out=../reports/codex-qa-30`. Use the game's own scripts (`RealmMonster`, `FrontendMenu.show_results`, `StoryScreens.show_story_ending`, the story dialogue used by story mode), not mock-ups. PNGs:
1. `six-row-monsters.png`: four monsters (moon moth, rune golem, root guardian, frost owl) in idle, windup (mid-way), attack and defeat (mid-way), side by side, ground line visible.
2. `shockwaves.png`: the root guardian's own wave and the golem's shared slam wave.
3. `story-faces.png` (one image or a few): a hero speaking with `happy`, `angry`, `hurt`, and Yuki with `hurt` (not picked: must show her neutral face).
4. `shadow-face.png`: a line spoken by a shadow (the v2 shadow face).
5. `results-victory.png`: the results screen after a winner's victory pose has finished (two heroes, e.g. Nova female and Luna).
6. `story-ending.png`: the story ending for two heroes: the main illustration, no victory pose (D43).
Open each PNG yourself and say in the README what it shows.

## Output
- `reports/codex-qa-30/README.md` (Korean): Part A table and findings; Part B list of PNGs with one line each; what you could not capture and why.
- `reports/codex-qa-30/commit.ps1` + `commit-paths.txt`: stage with `git add --pathspec-from-file` only your files (this card, its prompt, the capture script, the report folder); no `git add -f`, no `.godot`, no `.uid`, no `run.log`.

## Writable
`smash-nine-prototype/tests/analysis/codex_qa_30/**`, `reports/codex-qa-30/**`, `design/tasks/CODEX-QA-30.md`, `design/tasks/CODEX-QA-30.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 90 minutes.
