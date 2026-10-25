# CODEX-ART-88 · New monster candidates: margins, the wolf's hurt head, missing json fields

- Request: 점검 세션 "게임 상태 점검 및 정리", 사용자 요청 2026-10-25 — after the checkpoint `checkpoint-2026-10-25` (`c51a417f`), repair the candidates without needing the user.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-a/SmashNine`, branch `codex/art-88`, **started from `codex/art-83`** (ART-83 made `-v2` rows and `_sheet-v2.png` for eight monsters; this card builds on them).
- Running at the same time: ART-86 (fighter sheet repairs) in `art-b`. You share no files. Do not run Godot.
- Read first:
  - the QA-23 list `qa23/fix-list.md` (section "후보", rows C01–C23) and `qa23/LEAD-REVIEW.md` (read-only copies, untracked); full QA-23 data read-only at `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/qa-a/SmashNine/reports/codex-qa-23/`
  - the ART-81 audit `ref81/README.md`, `ref81/issues.json` (read-only copies, untracked): its 43 `metadata` items
  - `design/tasks/CODEX-ART-71.md` (the six-row sheet: 96-px cells, feet y=72), `reports/codex-art-83/README.md`
- Nothing under `smash-nine-prototype/` or `tools/` changes.

## 1. Margins (QA-23 C01–C08, C10–C23)
Some frames of the new six-row candidates come closer to the cell edge than the 4 px safety margin QA-23 used (the outer pixel is clear, so nothing is cut today).
- Re-measure each listed frame with QA-23's method; fix only the frames really inside 4 px.
- Fix by moving the figure inside its cell (keep the feet on y=72 for grounded frames). Only if a figure is too wide for 88 px, lower that row's single factor, and keep the row within ±5% of the idle size (the ART-71/74/76 fix-1 measure).
- Where a row already has a `-v2` from ART-83, apply the fix to that `-v2` (it is not published yet); where a row has only `-v1`, write `-v2`. Never change a `-v1` file.

## 2. The wolf's hurt head (QA-23 C09)
`niflheim_glacier_wolf-hurt-v1`: the top of the raised head is cut by a horizontal line (top y=21, 8 px straight). Re-slice from the ART-76 raw (`art/raw/monsters-76/`) if the raw is whole; otherwise redraw that frame. Write `niflheim_glacier_wolf-hurt-v2`.

## 3. Missing json fields (ART-81, 43 files)
Add the missing `cell`, `feet` and `loop` to those candidates' json files, with the values the card that made them used (fighters: `cell` 128 or 192, `feet` 120 or 152; monsters 96 / 72; `loop` from the row: idle, walk and fall loop; the others do not). **Only add missing fields; never change an existing value or the note.**

## 4. Assembled sheets
Rebuild `art/bakeoff/monsters/<id>_sheet-v2.png` (576×576) for every monster whose rows you changed, from its newest rows (v2 where it exists, v1 elsewhere); check each row of the sheet equals the row file (pixel compare).

## Output
- the changed or new `art/bakeoff/monsters/<id>-<row>-v2.png` + `.json` (`note` in Korean: the QA-23 id and the margin before → after; `replaces`: the v1 file), the json field additions, the sheets
- `reports/codex-art-88/README.md` (Korean): a table per QA-23 id (fixed / not needed after re-measuring / not fixed and why) and the list of json files completed; boards of the changed frames at 4× (`reports/codex-art-88/`)
- `reports/codex-art-88/commit.ps1`: stage with `git add --pathspec-from-file`; only your files (this card and its prompt included; not `qa23/` or `ref81/`), no per-attempt dumps, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`

## Writable
`art/bakeoff/monsters/*-v2.*`, `art/bakeoff/monsters/*_sheet-v2.png`, the json files of the 43 ART-81 metadata items (field additions only), `art/raw/monsters-88/**` (git-ignored), `reports/codex-art-88/**`, `design/tasks/CODEX-ART-88.md`, `design/tasks/CODEX-ART-88.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 120 minutes. In the order above.
