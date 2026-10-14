# Brave Luna sheets (redrawn 2026-10-14, design ② D36)

Brave Luna was redrawn in the design the user picked from three proposals (`CODEX-ART-44`):
- a high pink ponytail with the purple bow and gold star
- a sleeveless top, a short skirt over shorts, a short scarf
- purple-and-gold armoured gauntlets and star knee-guard boots

She has the same face and head size as Luna (2.2 heads). Both sheets were stacked from the accepted candidates (`art/bakeoff/luna/luna_brave-*`, card `CODEX-ART-45.md`) with `tools/sprite_pipeline/assemble.py`.

## `luna_brave_sheet.png`: base sheet (128 px, feet y=120, rows `Luna.SHEET_ROWS`)

| Row | Frames | FPS | Source |
| --- | ---: | ---: | --- |
| idle | 6 | 6.3 (D37) | `luna_brave-idle-v4` (the design anchor) |
| walk | 6 | 10 | `luna_brave-walk-v1` |
| jump | 1 | 1 | `luna_brave-jump-v1` |
| fall | 1 | 1 | `luna_brave-fall-v2` (v1 grounded to clear the top edge) |
| attack | 6 | 21 | `luna_brave-attack-v2`: the J chain at 128, a fallback only |
| shield | 6 | 12 | `luna_brave-shield-v1` |
| hurt | 1 | 1 | `luna_brave-hurt-v1` |

## `luna_brave_moves_sheet.png`: move sheet (192 px, feet y=152, D34)

| Row | Frames | FPS | Move | Source |
| --- | ---: | ---: | --- | --- |
| `brave_combo` | 6 | 16 | Brave J: jab 1–2, body kick 3–4, spin kick 5–6 | `luna_brave-brave_combo-v1` |
| `brave_upper` | 6 | 24 | Brave up/air-up J: star uppercut | `luna_brave-brave_upper-v1` |
| `brave_low` | 6 | 24 | Brave down J: low sweep | `luna_brave-brave_low-v1` |
| `brave_air_side` | 6 | 24 | Brave air-side J: flying kick | `luna_brave-brave_air_side-v1` |
| `brave_dive` | 6 | 24 | Brave air-down J: dive kick | `luna_brave-brave_dive-v1` |
| `comet_drive` | 6 | 24 | Brave K: short dash, compressed star punch | `luna_brave-comet_drive-v1` |
| `luna_breaker` | 6 | 16 | Brave L: spinning finishing kick | `luna_brave-luna_breaker-v1` |
| `heart_laser` | 6 | 12 | transformed I re-input: hands make a heart, then the firing stance (held) | `luna_brave-heart_laser-v1` |
| `tumble` | 6 | 21, loop | strong-launch hitstun | `luna_brave-tumble-v1` |

No effects are drawn into these frames. The game draws the star bursts, the comet light, the heart laser and the aura.
