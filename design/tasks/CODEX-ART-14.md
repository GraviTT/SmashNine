# CODEX-ART-14 · Effects and ultimate art at 1x for the doubled combat scale

- Request: 사용자 2026-10-08 "Codex를 최대한 활용할것. 그림이 어색해지는 것은 모두 Codex에게 맡기고, 퀄리티의 문제가 있어 보이는 것들도 스스로 판단하여 보강할것."
- Unit: Builder · Lead (integrates): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine`, branch `codex/fx-1x-b`
- Running at the same time: Codex builders `codex/realm-bg-c` (realm backgrounds), `codex/attack-vfx-2x-a` (attack strips, Rio/Frey frames), Codex analyst (bots). **This task does not edit product source.**
- Timeout: given in the prompt.

## Why

Attacks and effects were doubled today (`smash-nine-prototype/scripts/GameScale.gd`, COMBAT 2.0, decision D27). The art did not change, so the code now blows it up 2–4x: a projectile drawn at 4x shows 4x4 pixel blocks next to fighters drawn at 1x (1 art pixel = 1 screen pixel, `assets/art/<id>/<id>_sheet.png`). That reads as cheap. Redraw each file **at the size it is shown now**, at 1x pixel density, with the extra pixels spent on detail (not a nearest-neighbour upscale of the old file).

## Deliverables (replace the files at the same paths; same frame counts; anchors scale with the frames)

| File | Now | Shown at | **New** |
| --- | --- | --- | --- |
| `assets/art/effects/hit_spark.png` | 4 x 48x48 | 2–4.7x | **4 x 96x96 (384x96)** |
| `assets/art/effects/luna_star.png` | 24x24 | 4x | **96x96** |
| `assets/art/effects/yuki_talisman.png` | 32x16 | 4x | **128x64** |
| `assets/art/effects/rio_gem_sword.png` | 48x16 | 2x | **96x32** |
| `assets/art/effects/rio_mana_wave.png` | 24x56 | 2x | **48x112** |
| `assets/art/vfx/frey_ult_charge.png` | 6 x 128x128 | ~1.8x | **6 x 256x256** |
| `assets/art/vfx/frey_ult_wave.png` | 8 x 256x96 | 2x | **8 x 512x192** |
| `assets/art/vfx/yuki_ult_seal.png` | 8 x 256x256 | 3.2x | **8 x 512x512** |
| `assets/art/vfx/yuki_ult_burst.png` | 6 x 256x256 | 3.2x | **6 x 512x512** |
| `assets/art/vfx/luna_ult_transform.png` | 8 x 192x192 | 2.8x | **8 x 384x384** |
| `assets/art/vfx/luna_ult_laser.png` | 4 x 128x96 (tiles) | 2x | **4 x 256x192** (left and right edges still tile) |
| `assets/art/vfx/luna_ult_laser_head.png` | 4 x 96x96 | 2.6x | **4 x 192x192** |
| `assets/art/vfx/nova_ult_core.png` | 6 x 128x128 | 2.2x | **6 x 256x256** |
| `assets/art/vfx/nova_ult_burst.png` | 8 x 256x256 | ~2.5x | **8 x 512x512** |
| `assets/art/vfx/rio_ult_circle.png` | 6 x 192x192 | 1.7x | **6 x 384x384** |
| `assets/art/vfx/rio_ult_impact.png` | 6 x 64x64 | 2.8x | **6 x 128x128** |

Keep each effect's look, palette discipline, timing (frames), facing (right) and additive/normal blend as documented in `assets/art/vfx/README.md` and `assets/art/effects/README.md`; update both READMEs (new sizes and anchors). `ult_cutin_band.png` is HUD art: leave it. Projectiles keep their silhouettes readable at a glance in an 8-fighter brawl. At least 3 px transparent margin (the laser tile excepted on its tiling edges).

Generate with your image tool; post-process with Godot's Image API (scripts under `smash-nine-prototype/tests/art_preview/fx_1x_b/`); do not install packages or download files. Big inspection images go under `reports/codex-art-14/`, not under `smash-nine-prototype/`.

## Writable paths

`smash-nine-prototype/assets/art/effects/**`, `smash-nine-prototype/assets/art/vfx/**`, `smash-nine-prototype/tests/art_preview/fx_1x_b/**`, `reports/codex-art-14/**`.

## Report (`reports/codex-art-14/README.md`, Korean)

Old (as shown in game now, enlarged) vs new side by side next to a v2 fighter frame at 1x; size and anchor table; what a human must judge. Commit, or `reports/codex-art-14/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
