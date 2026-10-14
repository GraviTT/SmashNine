# Luna sheets (redrawn 2026-10-14, D33–D37)

Both Luna sheets were rebuilt from the accepted motion-viewer candidates (`art/bakeoff/luna/`, cards `design/tasks/CODEX-ART-42.md` … `CODEX-ART-46.md`) with `tools/sprite_pipeline/assemble.py`. Strips are stacked as they are, pixel for pixel. The method is the Frey method (`smash-nine-prototype/assets/art/frey/frey_moves_README.md`, `reports/frey-rework-2026-10-14.md`).

## `luna_sheet.png`: base sheet (128 px, feet y=120)
Rows come from `Luna.SHEET_ROWS`, which both forms share.

| Row | Frames | FPS | Source |
| --- | ---: | ---: | --- |
| idle | 6 | 6.3 (D37) | `luna-idle-v3` (the anchor, 2.2 heads, D25) |
| walk | 6 | 10 | `luna-walk-v1` |
| jump | 1 | 1 | `luna-jump-v2` |
| fall | 1 | 1 | `luna-fall-v2` |
| attack | 6 | 21 | side J raw at factor 0.230 with x −12, so it fits 128: a fallback only, because the side J plays `star_side` |
| shield | 6 | 12 | `luna-shield-v1` |
| hurt | 1 | 1 | `luna-hurt-v1` |

## `luna_moves_sheet.png`: move sheet (192 px, feet y=152, D34)
8 sheet rows: `transform` fills two.

| Row | Frames | FPS | Move | Source |
| --- | ---: | ---: | --- | --- |
| `star_up` | 6 | 21 | normal up/air-up J | `luna-star_up-v1` |
| `star_down` | 6 | 21 | normal down/air-down J | `luna-star_down-v1` |
| `star_comet` | 6 | 21 | normal K Star Comet | `luna-star_comet-v1` |
| `moon_ring` | 6 | 16.8 | normal L Moon Ring (a spin in place) | `luna-moon_ring-v1` |
| `transform` | 12 | 12 | I: the special transformation into Brave Luna (② design, D36) | `luna-transform-v3` |
| `tumble` | 6 | 21, loop | strong-launch hitstun | `luna-tumble-v1` |
| `star_side` | 6 | 21 | normal side/air-side J Star Echo | `luna-attack-v2` |

## The special transformation
The user asked for it on 2026-10-14. The 12 frames:
1. the wand gathered at the chest
2. raised overhead
3. let go to float
4–6. a floating spin; behind her back the hair ties into the ponytail, the dress becomes the combat outfit and the gauntlets appear
7–8. arms cross and open
9. a crouched landing, one fist on the ground
10–12. a fist raised, then the winking hero pose

In the game (`Luna._transformation_start`):
- The row plays over `TRANSFORM_MOTION_TIME` (1.0 s) at its own 12 fps.
- She becomes Brave Luna and the burst fires at `TRANSFORM_BURST_TIME` (frame 9, 0.67 s).
- The ultimate's super armour covers the 1.0 s.

The sprite has no effects; the game draws the charge, the star bloom and the burst.
