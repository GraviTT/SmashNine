# CODEX-ART-86 · Repairs of the fighter sheets in the game (QA-23 findings)

- Request: 점검 세션 "게임 상태 점검 및 정리", 사용자 요청 2026-10-25 — after the checkpoint `checkpoint-2026-10-25` (`c51a417f`), repair the sprites without needing the user. The bug-check session's sprite audit QA-23 found these defects in the sheets **the game uses now**. Repairs are **new candidate versions**; the game files do not change.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-b/SmashNine`, branch `codex/art-86` (from the checkpoint).
- Running at the same time: ART-83 (monster row repairs) in the other art clone. You share no files. Do not run Godot.
- Read first: the QA-23 list `qa23/fix-list.md`, `qa23/README.md` and `qa23/LEAD-REVIEW.md` (copied into this clone, untracked; the full measurements and 231 comparison pictures are read-only at `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/qa-a/SmashNine/reports/codex-qa-23/`; rows L09, L10, L11, L14, L34, L35, L37 and the notes on L28, L36, L38), `tools/sprite_pipeline/README.md`, `design/tasks/CODEX-ART-61.md` and `reports/codex-art-61b/README.md` (the sheet method), `reports/codex-art-68/README.md` (Rio's redrawn rows). The raws of the runs that made these rows are in this clone under `art/raw/` (`rio-61a`, `rio-61b`, `rio-65`, `rio-68`, `nova-51`, `nova-52a`, `nova-52b`, `frey-37`…`frey-41`).
- Nothing under `smash-nine-prototype/` or `tools/` changes. **Never overwrite**: write the next free version next to the adopted one.

## Rows

| QA-23 | Game row (adopted candidate) | Defect | Repair | New file |
|---|---|---|---|---|
| L14 상 | `rio/rio_female-mana_combo-v1` (moves sheet `mana_combo`) | F5 blade cut flat, F6 a detached blade tip (80 px) | re-slice F5–F6 from the raw if the raw is whole; otherwise redraw those frames with the row as reference | `rio_female-mana_combo-v2` |
| L09 중 | `nova/nova_male-walk-v2` | F3 arm guard and shin armour bigger and different from the other frames | redraw F3 only, matching F2/F4 | `nova_male-walk-v3` |
| L10 중 | `rio/rio_female-walk-v3` | F4 the sword points up behind the body; F3/F5 hold it forward-down | redraw F4 only | `rio_female-walk-v4` |
| L11 중 | `rio/rio_male-walk-v1` | the whole walk is about 18% smaller than the idle (sword, cape, legs) | rebuild with the factor matched to the idle anchor if the raw allows; otherwise redraw. **No head pasting.** | `rio_male-walk-v2` |
| L34 하 | `nova/nova_female-gravity_brake-v1` | F4–F6 feet at y=148 instead of 152 | move those frames down to the feet line | `nova_female-gravity_brake-v2` |
| L37 하 | `frey/frey-attack-v4` (base sheet `attack`, a spare row: J uses `attack_chain`) | F3–F6 head 0.92 of the idle | rebuild or retry the frames to the face rule 0.96–1.04 | `frey-attack-v5` |

Check only (no new file unless the check fails):
- L35 / L38 (`rio_female-attack-v1`: F5 blade cut, F6 detached piece, head 0.90) and L36 (`rio_male-attack-v1`: head 0.72): the ART-68 candidates `rio_female-attack-v2` and `rio_male-attack-v2` were made to fix the head; check that their blades are whole and their heads in the rule. Report it; only if `rio_female-attack-v2` still has the cut blade, write `rio_female-attack-v3`.
- L28 (`nova_female` base hurt feet 8 px up): the D40 candidate `nova_female-hurt-v2` (lowered 8 px) and the multi-frame `nova_female-hurt-v3` already exist. Confirm their feet; no new file.

## Rules
- Frame-only repairs keep every other frame byte-identical to the adopted row.
- The face rule (0.96–1.04, the ART-72 `face_check.py` method) on every frame you change; the costume exactly as the idle; border clear, 4 px margin, spill 0, feet on the line; the cell size of the row (base 128, moves 192).
- For a re-slice: say which raw file and which crop; show the raw next to the result.

## Output
- `art/bakeoff/<folder>/<stem>-<row>-v<n>.png` + `.json` (`note` in Korean: the QA-23 id, what was repaired, measures before → after; `frames`, `fps`, `cell`, `feet`; `replaces`: the adopted file).
- A 4× board per row: the adopted row, the repaired row, the frames changed marked (`reports/codex-art-86/<stem>-<row>.png`).
- `reports/codex-art-86/README.md` (Korean): a table per QA-23 id (done / covered by an existing candidate / not done and why), `prompts.txt`.
- `reports/codex-art-86/commit.ps1`: only your files (this card and its prompt included), no `git add -f`, nothing under `art/raw/` or `qa23/`, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/{frey,nova,rio}/**` (new files only), `art/raw/fighters-86/**` (git-ignored), `reports/codex-art-86/**`, `design/tasks/CODEX-ART-86.md`, `design/tasks/CODEX-ART-86.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 150 minutes. Rows in the table order.
