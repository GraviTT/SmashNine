# CODEX-ART-83 · Monster row repairs (the weak points the reports named)

- Request: 점검 세션 "게임 상태 점검 및 정리", 사용자 요청 2026-10-25 — after the checkpoint `checkpoint-2026-10-25` (`c51a417f`), repair the sprites without needing the user. New files are **candidates** next to the old ones; the user picks later.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-a/SmashNine`, branch `codex/art-83` (from the checkpoint).
- Running at the same time: ART-82 (character motion repairs) in `art-b`. You share no files. Do not run Godot.
- Read first: `design/tasks/CODEX-ART-71.md` (the sheet: 96-px cells, feet y=72, six rows), `reports/codex-art-71/README.md`, `reports/codex-art-74/README.md`, `reports/codex-art-76/README.md` and their `fix-1/` reports (what is weak, how sizes were matched), and the audit `reports/codex-art-81/README.md` (in this folder, untracked: the measurements of every candidate). The raws are in this clone: `art/raw/monsters-71`, `monsters-74`, `monsters-76`.
- Nothing under `smash-nine-prototype/` or `tools/` changes. **Never overwrite**: write `-v2` next to the `-v1`.

## Rows to repair (in this order)

| Monster · row | What is weak (measured or judged in the reports) | Target |
|---|---|---|
| `mossling` walk | feet lift, but the left/right alternation does not read at 1× | clear alternating steps |
| `ember_imp` walk | the same | clear alternating steps |
| `ember_imp` idle | detail 72–76 against the fighters' 96 | detail ≥ 85, same look |
| `asgard_aegis_ram` idle | detail 71–76 | detail ≥ 85, same look |
| `mossling` attack | the jaw opens, but the lunge forward is small | the body moves forward ≥ 8 px at 1× |
| `vanaheim_seed_sprite` attack | forward reach 5 px | ≥ 8 px |
| `vanaheim_vine_hound` (all six rows) | after the green palette remap the leaf edges speckle at 4× | the same greens without the speckle (a smoother remap, or regenerate with the current sheet as the colour reference) |
| `alfheim_moon_moth` windup | F2 measured 0.896 of the idle size | F2 within ±5% |
| `jotunheim_storm_wisp` hurt | the flinch barely changes the shape | a clear flinch in shape, not only in colour |
| `niflheim_glacier_wolf` attack | the leap's apex comes late | the apex in the middle of the arc |

## Rules for every repaired row
- The same identity, colours, size and feet line as the row it replaces; one factor per row matched to that monster's idle (the fix-1 measurements: within ±5% of idle on the same stable part).
- The six-row sheet is a later step: also write the assembled sheet `art/bakeoff/monsters/<id>_sheet-v2.png` (576×576) for every monster you changed, using the v2 rows where you made them and the current v1 rows elsewhere.
- Checks as ART-71 (border clear, 3 px margin, spill 0, one creature per frame, no text, no effects) plus the measure that showed the weakness, before → after.

## Output
- `art/bakeoff/monsters/<id>-<row>-v2.png` + `.json` (`note` in Korean: what was repaired and the measure before → after; `frames`, `fps`, `loop`, `cell: 96`, `feet: 72`, `factor`; `replaces`: the v1 file name), and `<id>_sheet-v2.png`.
- A board per repaired row: the current game sheet, v1, v2 at 1× and 4× (`reports/codex-art-83/<id>-<row>.png`).
- `reports/codex-art-83/README.md` (Korean): a table per row (before → after measures, delivered or not), what is still weak; `prompts.txt`.
- `reports/codex-art-83/commit.ps1`: only your files (this card and its prompt included), no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/monsters/*-v2.*` and `art/bakeoff/monsters/*_sheet-v2.png` (new files only), `art/raw/monsters-83/**` (git-ignored), `reports/codex-art-83/**`, `design/tasks/CODEX-ART-83.md`, `design/tasks/CODEX-ART-83.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 150 minutes. Rows in the table order; list the rest.
