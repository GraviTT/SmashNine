# CODEX-ART-22 · Passive marks for Frey and Luna

- Request: 사용자 2026-10-10 (취침 루틴, 04:55 "Codex 한도 충전 완료. 다시 Codex 사용으로 하고 루틴 재진입."). Approved plan, spare-time item: "Codex A 2차(남은 프레임, 패시브 표시 효과)". The seven finishing criteria include "스킬들이 플레이어가 사용했을 때 확실하게 어떤 스킬이다 라는 것을 인지 할 수 있는지".
- Unit: Builder (images) · Lead: Claude (wires the art into the code, keeps the current drawn shapes as the fallback)
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/passive-marks-22`
- Read first: `smash-nine-prototype/assets/art/effects/README.md` (effect art contract and prompts), `characters/frey/Frey.md` and `characters/luna/Luna.md` ("Passive" sections), `characters/frey/Frey.gd` (`_make_pursuit_mark`, `_play_followup_flash`), `characters/luna/Luna.gd` (`_update_star_orbit`, `_make_star_points`), the illustrations `assets/art/frey/frey_illustration.png` and `assets/art/luna/luna_illustration.png`.
- Running at the same time: Codex analyst `codex/char-qa-17-r2b` (Godot measurements). Keep Godot use short.
- Timeout: given in the prompt (about 45 minutes).

## What exists now (drawn in code)

- Frey "발키리의 추격": a gold wing mark (two Polygon2D wings) floats about 118 px above the marked target for up to 1 s.
- Frey spike window: a gold ring (Line2D, radius 46 px, grows over 0.18 s) around Frey plus a sprite flash.
- Luna "별빛 충전": up to five small gold stars (Polygon2D, radius 7) circle 44 px around her body.

## Make (new files only)

| File | Size | Background | Must show | Avoid |
| --- | --- | --- | --- | --- |
| `frey_pursuit_mark.png` | 64×40 | transparent | a downward-pointing valkyrie wing chevron (two white-gold wings meeting over a small gold point), reads as "this one is marked" from above a fighter | text, a full bird, red |
| `frey_spike_ring.png` | 96×96, 1 frame | transparent | a thin gold-white ring with four small feathers at the diagonals, open enough that Frey (about 60 px tall) shows inside | a filled disc, thick outline hiding the sprite |
| `luna_star_charge.png` | 18×18 | transparent | a five-point star, warm gold with a white core and a violet outline, clearly brighter than Luna's star bolt (`luna_star.png`) | pink fill (lost against her hair), soft blur |

Palette: Frey gold `#FFD27A` / `#FFB85C`, white highlights, dark outline like the character sheets; Luna gold `#FFE06B`, white, violet `#662A91`. Pixel art at the final size, alpha 0/1 (effects README rule), nearest filtering.

## Checks and report

- Exact sizes, transparent background, alpha 0/1, no stray pixels; a contact sheet at 1x and 4x on three realm backgrounds (`assets/art/realm_*/bg_*.png`) with a 128 px fighter cell from `frey_sheet.png` / `luna_sheet.png` for scale.
- Writable: `smash-nine-prototype/assets/art/effects/passive/**` (the three PNGs + `README.md` with the contract and prompts), `smash-nine-prototype/tests/art_preview/passive_marks_22/**`, `reports/codex-art-22/**`. Do not edit product code.
- Report `reports/codex-art-22/README.md` (Korean): the files, the prompts, the checks, the contact sheet. Commit, or `reports/codex-art-22/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
