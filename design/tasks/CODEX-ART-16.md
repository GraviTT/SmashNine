# CODEX-ART-16 · Attack strips at 1x for their new size, Rio attack and shield rows, Frey attack 4

- Request: 사용자 2026-10-08 "그림이 어색해지는 것은 모두 Codex에게 맡기고, 퀄리티의 문제가 있어 보이는 것들도 스스로 판단하여 보강할것."
- Unit: Builder · Lead (integrates): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/attack-vfx-2x-a`
- Running at the same time: Codex builders `codex/fx-1x-b`, `codex/realm-bg-c`, Codex analyst (bots). **This task does not edit product source.**
- Timeout: given in the prompt.

## 1. Attack strips at twice the frame size

Your CODEX-ART-13 strips (`assets/art/attack_vfx/`, 16 files, 6 frames each) are in game: the code scales each slash to the attack's doubled reach, which comes to about 1.2–2.6x, so their pixels are 2–3 px blocks next to 1x fighters. Rebuild all 16 at **twice the frame size** (e.g. `frey_slash` 6 x 384x256, `rio_k` 6 x 512x192) at 1x pixel density, from your generated sources in `reports/codex-art-13/source/` (still in this clone; regenerate where they lack detail). Same frames, facing, anchors x2, blend; update `assets/art/attack_vfx/README.md`. While at it, fix strips whose arc is cut at the frame edge (e.g. the left end of `luna_slash`, `luna_brave_slash`, `frey_slash` in `reports/codex-art-13/preview.png`).

## 2. Rio attack and shield rows: one body size

`assets/art/rio/rio_male_sheet.png` and `rio_female_sheet.png` (768x896, 6x7 cells of 128 px, feet y=120; rows idle 4 / walk 6 / jump 1 / fall 1 / attack 4 / shield 6 / hurt 1): the original builder shrank each wide attack (row 4) and shield (row 5) frame to fit its slash or crystal shield in the cell, so Rio's body is smaller in those frames than in idle and changes size inside the shield loop (male shield c1–c3 vs c0/c4/c5). Make the body the idle size in every frame of rows 4 and 5 (re-extract from `assets/art/rio/rio_*_v2_rework_source.png`, using the lead's tool `tests/art_preview/frame_reextract_lead/reextract.gd` and your ART-12 hand masks as needed); where the effect then does not fit the 128 px cell, trim or shrink **the effect, never the body**. Keep feet y=120 and the 4 px margin; other frames pixel-identical.

## 3. Frey attack 4

`assets/art/frey/frey_sheet.png` r4c3: body, sword and cape are complete but only the shield's edge shows; in the source (`frey_v2_source.png`, attack row, 4th pose) the shield's face is visible to her right. Restore it (it may touch the neighbouring pose in the source; separate by hand).

Check rows 4–5 at 2x in a strip with their neighbours so size and position do not jump. Run `smash-nine-prototype/tests/test_sprite_frames.gd` (must pass) and `tests/analysis/lead/frame_audit.gd`.

Post-process with Godot's Image API (scripts under `smash-nine-prototype/tests/art_preview/attack_vfx_2x_a/`); use your image tool where new detail is needed; do not install packages or download files. Big inspection images go under `reports/codex-art-16/`.

## Writable paths

`smash-nine-prototype/assets/art/attack_vfx/**`, `smash-nine-prototype/assets/art/rio/rio_male_sheet.png`, `rio_female_sheet.png`, `smash-nine-prototype/assets/art/frey/frey_sheet.png`, `smash-nine-prototype/tests/art_preview/attack_vfx_2x_a/**`, `reports/codex-art-16/**`.

## Report (`reports/codex-art-16/README.md`, Korean)

Before/after for each part; the pixel-identical check for untouched frames; what a human must judge. Commit, or `reports/codex-art-16/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
