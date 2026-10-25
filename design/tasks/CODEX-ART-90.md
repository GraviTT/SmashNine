# CODEX-ART-90 · Last repairs: guardian margin, hound speckle, the legacy stag attack, two head rechecks

- Request: 점검 세션 "게임 상태 점검 및 정리", 사용자 요청 2026-10-25 — after the checkpoint `checkpoint-2026-10-25` (`c51a417f`), repair the sprites without needing the user. New files are **candidates**.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-b/SmashNine`, branch `codex/art-90`. Its base holds ART-83, ART-88 and ART-87 (merged in this clone only).
- Running at the same time: ART-89 (character motions second try) in `art-a`; it owns Luna victory, Brave Luna hurt/jump/fall, Frey victory/jump, Yuki victory, Nova (female) victory, Rio (male) victory and walk. **Do not touch those rows.** Do not run Godot.
- Read first: `reports/codex-art-83/README.md`, `reports/codex-art-88/README.md`, `reports/codex-art-87/README.md`, the QA-23 copies `qa23/fix-list.md`, `qa23/candidate-rows.md`, `qa23/LEAD-REVIEW.md` (read-only, untracked). Raws: `art/raw/monsters-71`, `-74`, `-76`, `-83`, `-87`.
- Nothing under `smash-nine-prototype/` or `tools/` changes.

## Work
1. **Root guardian F1** (QA-23 C08, C22; ART-88 could not fix): `yggdrasil_root_guardian-attack` F1 and `-defeat-v2` F1 reach within 3 px of the top. Retry those frames only, with the raised arms a little lower (the same pose), so the figure keeps 4 px top margin, feet on y=72 and the row within ±5% of the idle. Write `yggdrasil_root_guardian-attack-v2` (attack has only v1) and update `-defeat-v2` in place (it is not published yet). Rebuild `yggdrasil_root_guardian_sheet-v2.png`.
2. **Vine hound speckle** (ART-83 note): the v2 rows still show fine speckle at 4×. Clean it without losing the leaf texture; update the `vanaheim_vine_hound-*-v2` files in place (not published yet) and the sheet.
3. **Legacy stag attack** (ART-87 note): in `art/bakeoff/monsters/legacy/alfheim_moon_stag_sheet-fix1.png` the attack row came out smaller than the other rows and F4 reuses another cell. Re-slice the attack row from `smash-nine-prototype/assets/art/monsters/alfheim_moon_stag_source.png` at the sheet's scale (or redraw the frames the source cuts) so the four frames are distinct and the size matches the idle and walk rows. Update `-fix1` in place (it is not published yet).
4. **Head rechecks** (QA-23 `candidate-rows.md`, manual recheck items not owned by ART-89): `luna/luna-fall-v3` and the game's `nova/nova_female-meteor_kick` and `nova/nova_male-meteor_kick` rows (adopted versions in `art/bakeoff/nova/`). Measure the faces by hand at 4× (the ART-72 method). Only if a face is really outside 0.96–1.04, write the next free version with those frames retried; otherwise report the measures.

## Checks and output
As the cards that made these files (ART-71/76 for monsters, ART-87 for the legacy sheet, ART-72 for fighters). Changed frames byte-compared against the old ones; unchanged frames identical.
- The files above (`.json` notes in Korean with before → after; `replaces` where a new version is written).
- Boards at 4× of every changed frame: `reports/codex-art-90/`.
- `reports/codex-art-90/README.md` (Korean): per item done / not needed / not done and why.
- `reports/codex-art-90/commit.ps1`: stage with `git add --pathspec-from-file`; only your files (this card and its prompt included; not `qa23/`), no per-attempt dumps, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/monsters/yggdrasil_root_guardian-*`, `art/bakeoff/monsters/yggdrasil_root_guardian_sheet-v2.png`, `art/bakeoff/monsters/vanaheim_vine_hound-*-v2.*`, `art/bakeoff/monsters/vanaheim_vine_hound_sheet-v2.png`, `art/bakeoff/monsters/legacy/alfheim_moon_stag_sheet-fix1.*`, `art/bakeoff/luna/luna-fall-v4.*`, `art/bakeoff/nova/nova_*-meteor_kick-v*.*` (new files only), `art/raw/art-90/**` (git-ignored), `reports/codex-art-90/**`, `design/tasks/CODEX-ART-90.md`, `design/tasks/CODEX-ART-90.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 120 minutes. In the order above.
