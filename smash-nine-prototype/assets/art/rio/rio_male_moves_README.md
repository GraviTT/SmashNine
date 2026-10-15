# Rio male sheets (redrawn 2026-10-15, D33–D37)

Both sheets were rebuilt from the candidates in `art/bakeoff/rio/rio_male-*` (cards `design/tasks/CODEX-ART-60.md`, `CODEX-ART-61.md`, `CODEX-ART-64.md`; night routine `routine/2026-10-15-night/`) with `tools/sprite_pipeline/assemble.py`, pixel for pixel. The method is the Frey method (`reports/frey-rework-2026-10-14.md`); the walk is the 8-frame walk (`reports/walk-8frame-2026-10-15.md`).

## `rio_male_sheet.png`: base sheet (128 px, feet y=120, rows `Rio.SHEET_ROWS`, shared by both bodies)

| Row | Frames | FPS | Source |
| --- | ---: | ---: | --- |
| idle | 6 | 6.3 (D37) | `rio_male-idle-v2` (the anchor, 3 heads) |
| walk | 8 | 13.3, two sheet rows | `rio_male-walk-v1` |
| jump | 1 | 1 | `rio_male-jump-v1` |
| fall | 1 | 1 | `rio_male-fall-v1` |
| attack | 6 | 21 | `rio_male-attack-v1`: a fallback only |
| shield | 6 | 12 | `rio_male-shield-v1` |
| hurt | 1 | 1 | `rio_male-hurt-v1` |

## `rio_male_moves_sheet.png`: move sheet (192 px, feet y=152, D34)

| Row | Frames | FPS | Move | Source |
| --- | ---: | ---: | --- | --- |
| `mana_combo` | 6 | 18 | ground J chain: slash, backhand, finisher (the game plays 1–2, 3–4, 5–6) | `rio_male-mana_combo-v1` |
| `rising_slash` | 6 | 30 | up J, air up J: a rising overhead cut | `rio_male-rising_slash-v1` |
| `low_sweep` | 6 | 30 | ground down J: a low sweep | `rio_male-low_sweep-v1` |
| `air_slash` | 6 | 40 | aerial side J: a horizontal cut | `rio_male-air_slash-v1` |
| `plunge` | 6 | 12 | aerial down J: a diving plunge | `rio_male-plunge-v1` |
| `dimension_slash` | 6 | 23 | K: the blink slash | `rio_male-dimension_slash-v1` |
| `rune_shield` | 6 | 12 | L: the rune shield guard | `rio_male-rune_shield-v1` |
| `infinity_overdrive` | 6 | 11 | ultimate start: sword raised, command | `rio_male-infinity_overdrive-v1` |
| `tumble` | 6 | 21, loop | **new** strong-launch hitstun | `rio_male-tumble-v1` |
