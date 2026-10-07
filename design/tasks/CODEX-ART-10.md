# CODEX-ART-10 · Ultimate effect art for the five fighters

- Request: 사용자 "추가로, 캐릭터별 궁극기의 성능과 이펙트를 개선할것." and "Codex를 적극 활용할것." (2026-10-08, 취침 루틴 `routine/2026-10-08-night/`)
- Unit: Builder · Lead (integrates the art into the game, tunes the ultimates): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine`, branch `codex/ult-vfx-b`
- Running at the same time: Codex builder `codex/sprite-fix-a` (sprite fixes). The lead edits product source. **This task does not edit product source.**
- Timeout: given in the prompt. Work fighter by fighter in the order below.

## Read first

- The ultimates as they work now: `smash-nine-prototype/characters/frey/Frey.md` + `Frey.gd` (`_ultimate_*`), `characters/yuki/Yuki.md` + `YukiGrandWard.gd`, `characters/luna/Luna.md` ("Ultimate - Brave Luna", "Heart Laser") + `LunaHeartLaser.gd`, `characters/nova/Nova.md` ("Event Horizon: Gravity Slingshot") + `NovaGravityBurst.gd`, `characters/rio/Rio.md` ("Infinity Overdrive") + `Rio.gd`. Today they are drawn with coloured rectangles, lines and polygons.
- The accepted art for palette and pixel density: the v2 sheets and illustrations in `assets/art/<id>/`, the effects in `assets/art/effects/`, the hazard art in `assets/art/hazards/`. Fighters are drawn at 1x (128 px cells, about 85–100 px tall on screen).

## Deliverables (`smash-nine-prototype/assets/art/vfx/`, PNG RGBA, transparent, pixel art, drawn at 1x unless noted)

Each animated effect is a **horizontal strip** of equal frames, first frame on the left. Every frame keeps a transparent margin of at least 2 px (no cut edges). Bright cores, readable on dark and on busy painted backgrounds. One `README.md` with the file list, frame size and count, suggested fps, anchor point (where the effect's origin is in the frame), and whether it should be drawn additively.

| # | File | Frames x size | What |
| --- | --- | --- | --- |
| 1 | `frey_ult_charge.png` | 6 x 128x128 | golden aura with spread Valkyrie wing silhouettes behind Frey while she charges (anchor: feet at bottom centre) |
| 2 | `frey_ult_wave.png` | 8 x 256x96 | golden ground shockwave travelling right from the left edge (the game mirrors it for the left wave; anchor: bottom left) |
| 3 | `yuki_ult_seal.png` | 8 x 256x256 | rotating four-direction seal circle with yin-yang glyphs, for the 0.7 s warning and 2.35 s active field (game scales it to about 410 px; anchor: centre) |
| 4 | `yuki_ult_burst.png` | 6 x 256x256 | final burst of the grand ward (anchor: centre) |
| 5 | `luna_ult_transform.png` | 8 x 192x192 | star burst of the Brave Luna transformation (anchor: centre at chest height) |
| 6 | `luna_ult_laser.png` | 4 x 128x96 | heart laser beam: each frame is a horizontally tileable beam segment, pink-white core (anchor: left middle) |
| 7 | `luna_ult_laser_head.png` | 4 x 96x96 | heart-shaped beam head / impact (anchor: centre) |
| 8 | `nova_ult_core.png` | 6 x 128x128 | gravity core loop: dark centre, teal-to-gold accretion ring (anchor: centre) |
| 9 | `nova_ult_burst.png` | 8 x 256x256 | gravity explosion where the slingshot ends (anchor: centre) |
| 10 | `rio_ult_circle.png` | 6 x 192x192 | blue geometric summoning circle under the six orbiting gem swords (anchor: centre) |
| 11 | `rio_ult_impact.png` | 6 x 64x64 | gem sword impact sparkle, greyscale/white so the game can tint it per sword (anchor: centre) |

If time is left: `ult_cutin_band.png` 640x112, a dynamic diagonal speed-line band (greyscale, tinted per character by the game) for the ultimate cut-in banner.

Generate with your image tool, then cut, align and clean with Godot's Image API from a script; do not install packages or download files.

## Writable paths

| Path | For |
| --- | --- |
| `smash-nine-prototype/assets/art/vfx/**` | the effect strips, sources (`*_source.png`), `README.md` |
| `smash-nine-prototype/tests/art_preview/ult_vfx_b/**` | build, verify and preview scripts |
| `reports/codex-art-10/**` | report, contact sheet, an animated preview per effect if you can |

Forbidden: product source, existing tests, other art folders, `design/`, merging, pushing, installing packages, downloading files.

## Report (`reports/codex-art-10/README.md`, Korean)

- File table (frames, size, fps, anchor, additive or not), verification (sizes, margins, frame count), a contact sheet with every effect next to a fighter sheet for scale, what a human must judge, what was not done.
- Commit, or `reports/codex-art-10/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
