# CODEX-ART-32 · Frey move sheet under the three sprite rules (D32), pilot

- Request: 사용자 2026-10-11 (motion viewer https://claude.ai/artifact/188Ryqb526Ue58MDf4BnbU): "이렇게 보니 확실히 스프라이트의 어색함이 많이 보이네. 하나의 모션에서도 일관성이 없고 특히 Frey의 spike_followup은 심각한 수준." Then the rules (`design/DECISIONS.md` D32):
  > 1. 모든 스프라이트는 반드시 정사각형 틀 내에 모두 들어와야 하며, 네 변에 닿는 1픽셀은 반드시 아무것도 없어야 한다.
  > 2. 머리의 크기를 반드시 모든 스프라이트에서 통일하며, 머리를 기준으로 그린다.
  > 3. 이펙트는 따로 그리고 합친다.
- Pilot: the same pipeline goes to Luna, Brave Luna, Nova, Rio and Yuki once Frey passes — build it as reusable scripts (character id and sheet paths as arguments).
- Unit: Builder (images + pipeline + tests) · Clone `SmashNine-units/builder-art/SmashNine`, branch `codex/frey-redo-32` (reset; an earlier start of this card was stopped by the lead — reuse anything useful under `tests/art_preview/frey_redo_32/`). Nothing else runs now. `Frey.gd` row table stays (same row names, order, frame counts).
- Read first: `assets/art/frey/frey_sheet.png` (reference: idle row), `frey_illustration.png`, `frey_moves_sheet.png` + `frey_moves_README.md`, `characters/frey/Frey.md` (what each move does), `reports/codex-art-23/README.md`, `reports/codex-art-28/README.md`.

## What is wrong now
- Scale jumps inside a row: `spike_followup` frame 3 about half the idle size, frame 4 about 1.5×; `descent` 4 small, 5 large; `tumble` smaller than idle.
- Frames of one row come from different generations (ART-23, ART-28), so face, proportions and rendering differ frame to frame; `descent` 2–3 are back views.
- Cause: frames generated separately and each resized on its own to fit its cell; effects baked into the pose, so trimming effects shrank bodies.

## Pipeline (required)
1. **Head reference.** Find the head box (hair + face + helmet, without the wings if that is more stable — say which) in the idle frame of `frey_sheet.png`. That size is the unit for every frame (rule 2).
2. **Body layer, one generation per row.** Generate all poses of a row together in one image (a horizontal strip), character only, **no effects**, with the idle sprite and the illustration as reference images; same character, face or profile visible in every frame (no back views). Prefer editing from the reference sprite.
3. **Scale by the head.** Scale each body frame so its head box matches the reference head size (±1 px on width and height). Never fit a frame to its cell. If a pose then does not fit, regenerate it tighter (sword angle, limbs) instead of shrinking.
4. **Effect layer, drawn separately (rule 3).** Generate the row's effects on their own (slash arcs, dust, glints) and composite them over the body frames, anchored to the weapon/feet. Effects may be shortened or faded with a dithered edge to stay in the cell; the body is never moved or scaled for an effect.
5. **Rule 1.** Every cell of the final sheet has zero opaque pixels on its 1-px border (and keep at least 2 px where you can). Ground frames feet on y=120, air frames centred like jump/fall. Palette and outline of `frey_sheet.png` (quantize to it), hard alpha.
6. **Outputs:** `assets/art/frey/frey_moves_body_sheet.png` (body layer), `frey_moves_fx_sheet.png` (effect layer, same grid), `frey_moves_sheet.png` (composite the game uses), `frey_moves_heads.json` (per row and frame: head box x, y, w, h in cell coordinates, plus the reference size).
7. Order: `spike_followup`, `descent`, `tumble`, then the other five rows. Up to 3 generations per row; keep the best and say which rows fall short.

## Checks (required)
- A head audit that does not trust the JSON: locate the head in each body-layer frame by matching the reference head (scales 0.7–1.4, mirrored, rotated for `tumble`) and report the matched scale per frame; every frame within ±5%. Record the numbers for the current (old) sheet too, as the before.
- Extend `tests/test_sprite_frames.gd`: (a) rule 1 for every cell of every sheet under `assets/art/` that the game slices (fighters, move sheets, monsters): zero opaque pixels on the 1-px border; (b) for every `*_heads.json`: every frame's head box equals the reference size ±1 px and lies inside its cell. Today one other cell breaks rule 1: `monsters/jotunheim_rune_golem_sheet.png` r2c1 (attack frame 2) — fix that cell (move or trim the touching pixels cleanly) so the test passes.
- `test_moves_sheet.gd`, `test_frey_kit.gd`, `test_sprite_pose.gd` pass; `run_all.ps1 -SkipSoak` passes apart from the known certificate line.
- Contact sheets in `tests/art_preview/frey_redo_32/`: per row before/after at 1× and 3×, each row next to the idle frame, measured head scale under every frame; the body layer, effect layer and composite side by side for two rows.

## Writable
`assets/art/frey/frey_moves_sheet.png`, `frey_moves_body_sheet.png`, `frey_moves_fx_sheet.png`, `frey_moves_heads.json`, `frey_moves_README.md` (+ `.import`), `assets/art/monsters/jotunheim_rune_golem_sheet.png`, `tests/test_sprite_frames.gd`, `tests/art_preview/frey_redo_32/**`, `reports/codex-art-32/**`. Keep image-gen originals named `*_source.png`; previews under ~15 MB. Hard stop 110 minutes after you start. Report `reports/codex-art-32/README.md` (Korean): pipeline and how to rerun it for another character, before/after head-scale table per row, prompts, what a human must judge. `commit.ps1` (writable paths only, message ending `Co-Authored-By: Codex <noreply@openai.com>`).
