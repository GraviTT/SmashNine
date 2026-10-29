# CODEX-ART-87 · Repairs of the old monster sheets in the game (QA-23 findings)

- Request: 점검 세션 "게임 상태 점검 및 정리", 사용자 요청 2026-10-25 — after the checkpoint `checkpoint-2026-10-25` (`c51a417f`), repair the sprites without needing the user. The bug-check session's sprite audit QA-23 found cut bodies and dirty edges in the **old 4-row monster sheets the game uses now** (`smash-nine-prototype/assets/art/monsters/<id>_sheet.png`, 96-px cells: idle 4, walk 6, attack 4, hurt 1). New six-row sheets exist as candidates (ART-71/74/76); if the user adopts them these repairs are not needed, but until then the game shows the defects. So the repairs are a **fallback candidate**.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-a/SmashNine`, branch `codex/art-87` (from the checkpoint).
- Running at the same time: ART-86 (fighter sheet repairs) in the other art clone. You share no files. Do not run Godot.
- Read first: the QA-23 list `qa23/fix-list.md`, `qa23/README.md` and `qa23/LEAD-REVIEW.md` (copied into this clone, untracked; the full measurements and 231 comparison pictures are read-only at `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/qa-a/SmashNine/reports/codex-qa-23/`; rows L01–L08, L12, L13, L15–L27, L29, L30), `smash-nine-prototype/assets/art/monsters/README.md` (how the sheets were cut), `scripts/RealmMonster.gd` (rows, cell, feet at 3/4 of the cell). The source pictures are next to each sheet: `smash-nine-prototype/assets/art/monsters/<id>_source.png`.
- Nothing under `smash-nine-prototype/` or `tools/` changes. Write the repaired sheets to a separate folder so they are not mixed with the new six-row candidates.

## Work (in this order)
1. **상 — cut bodies** (re-slice from `<id>_source.png` when the source is whole; otherwise redraw the frame with the sheet's other frames as reference, no new style):
   - `jotunheim_rune_golem`: idle 1–4, walk 1–6, attack 1–4, hurt (L01, L08) — the lower body is cut by a straight line; also fit the wide shoulders inside the margin (L07)
   - `muspelheim_magma_boar`: idle 1–4 belly and legs cut (L02)
   - `alfheim_moon_stag`: attack 1–4 head and front body cut (L12), hurt antler cut (L27)
   - `yggdrasil_root_guardian`: attack 1–4 fists and face cut (L13)
   - `niflheim_glacier_wolf`: idle 1–4 (L03) — **first compare with the source**: the lead noted the outline may be closed (a crouched pose). Repair only if the source shows legs that the sheet cut.
2. **중 — attack frames cut on the right** (re-slice): raven attack 3 (L15), slinger attack 3 (L16), boar attack 2–3 (L17), wolf attack 2 (L18), cog drone attack 2 (L19), gear beetle attack 2–3 (L20).
3. **중 — dirty edges** (clean pixels): `ember_imp` purple stepped border on all 15 frames (L04) and the horn tips inside the top margin (L06); `mossling` teal stepped border (L05).
4. **하 — shot effects drawn into the body frames** (L21–L26, L29, L30): the projectile or flash in the body sheet would double with the game's own projectile. Remove only the shot part (keep the tail flames and body glow that belong to the design). If removing it leaves a hole in the body, redraw that frame.

## Rules
- The sheet layout stays exactly the game's: 576×384 (6 columns × 4 rows of 96-px cells: idle 4, walk 6, attack 4, hurt 1), the same frame counts, cell size and feet line; a repaired frame lines up with its neighbours (feet, size). The sources are 1536×1024 pictures of the same poses.
- Frames you do not repair stay byte-identical.
- Say per frame which source region you used (re-slice) or that you redrew it.

## Output
- `art/bakeoff/monsters/legacy/<id>_sheet-fix1.png` (the whole repaired sheet, same size as the game's) + `.json` (`note` in Korean: the QA-23 ids fixed and how; `replaces`: `smash-nine-prototype/assets/art/monsters/<id>_sheet.png`).
- A board per monster: the game sheet, the repaired sheet, the changed frames marked, at 1× and 4× (`reports/codex-art-87/<id>.png`).
- `reports/codex-art-87/README.md` (Korean): a table per QA-23 id (done / not needed after comparing with the source / not done and why), `prompts.txt`.
- `reports/codex-art-87/commit.ps1`: only your files (this card and its prompt included), no `git add -f`, nothing under `art/raw/` or `qa23/`, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/monsters/legacy/**` (new), `art/raw/monsters-87/**` (git-ignored), `reports/codex-art-87/**`, `design/tasks/CODEX-ART-87.md`, `design/tasks/CODEX-ART-87.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 150 minutes. In the order above; list what is left.
