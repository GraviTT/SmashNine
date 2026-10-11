# CODEX-ART-34 · Walk cycles that read as walking (all fighter sheets)

- Request: 사용자 2026-10-11 (motion viewer https://claude.ai/artifact/188Ryqb526Ue58MDf4BnbU): "walk에 걷는 모습이 전혀 보이지 않는다."
- Rules: `design/DECISIONS.md` D32 — everything inside the cell with an empty 1-px border; one head size per character (the idle head of the same sheet), the body drawn to the head; effects apart; **no pasted heads or body parts — every frame is one drawing**.
- Two builders, one sheet set each:
  - **A** `codex/walk-34a` (clone `SmashNine-units/builder-art/SmashNine`): `frey/frey_sheet.png`, `rio/rio_male_sheet.png`, `rio/rio_female_sheet.png`, `yuki/yuki_sheet.png`
  - **B** `codex/walk-34b` (clone `SmashNine-units/builder-frey/SmashNine`): `nova/nova_male_sheet.png`, `nova/nova_female_sheet.png`, `luna/luna_sheet.png`, `luna/luna_brave_sheet.png`
- Read first: `reports/codex-art-33/README.md` and `tests/art_preview/frey_heads_33/` (the validated pipeline: whole-frame scaling to the drawn head, head detector, eye-cluster double-head check — reuse it, configured per character), the sheet READMEs in `assets/art/<id>/`, `characters/common/PlayerBase.gd` (`ORIGINAL_SHEET_ROWS`: walk = row 1, 6 frames, 10 fps, loop).

## Lead measurement (feet band y 100–120, silhouette change between consecutive walk frames, loop)
Frey 33%, Rio male 26%, Rio female 25%, Nova female 35%, Nova male 44%, Luna 49%, Yuki 49%, Brave Luna 56%. Frey and Rio barely move: the cape and the hanging sword hide the legs and the six frames are near copies.

## Do (hard stop 90 minutes after you start)
1. Redraw **only row 1 (walk)** of each sheet: a 6-frame side-view walk cycle at 10 fps that loops — contact, down, passing, contact (other leg), down, passing. Legs clearly alternate and are visible (cape and hair behind the legs, weapon held so it does not cover them), a small body bob, arms counter-swing where the kit allows (Frey keeps sword and shield, Rio his sword, Luna her staff, Brave Luna her gauntlets, Nova his fists, Yuki her talismans).
2. Generate the whole cycle in one image with the idle frame of the same sheet as the scale anchor; same character, face visible in every frame. Scale whole frames so the drawn head matches the idle head (±5%, measured by the validated detector); one head per frame (eye-cluster check). Never paste a head or part.
3. The sheet's existing contract stays: 128 px cells, feet on y=120, the 4 px margin `tests/test_sprite_frames.gd` enforces on main sheets, palette and hard alpha of that sheet. **Every other row must stay byte-identical** (check it and say so).
4. Feet motion: rerun the lead's measurement (`tests/art_preview/walk_34/walk_feet.gd`, copied there by the lead) — target ≥ 45% silhouette change per step for every sheet; report before/after.

## Done when
- Per sheet: walk row redrawn, head scale within ±5% on all 6 frames, one head per frame, feet change ≥ 45%, other rows identical, `test_sprite_frames.gd` and `test_art.gd` pass, `--headless --import` exits 0.
- Contact sheets in `tests/art_preview/walk_34/`: per sheet, before/after walk row at 3× with the idle frame, head box and scale under each frame; plus an onion-skin strip (all 6 frames overlaid at low opacity) before/after so the leg swing is visible in one picture.
- No `.csv` inside `smash-nine-prototype/` (use `.txt` or `reports/`).
- Writable: your four sheets (+ `.import`, README notes), `tests/art_preview/walk_34/<a|b>/**` (A writes `walk_34/a/`, B `walk_34/b/`), `reports/codex-art-34<a|b>/**`. Report `reports/codex-art-34<a|b>/README.md` (Korean): every operation on body pixels, before/after numbers, what a human must judge. `commit.ps1` (writable paths only, message ending `Co-Authored-By: Codex <noreply@openai.com>`).
