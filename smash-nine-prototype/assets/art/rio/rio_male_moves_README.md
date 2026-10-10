# Rio male move sheet

`rio_male_moves_sheet.png` is Rio's male-body per-move atlas. All attack poses use the
live idle body's scale rather than the shrunken scale of the older attack/shield rows.

## Contract

- Canvas: 768×1024 RGBA PNG
- Grid: 6 columns × 8 rows, 128×128 per cell
- Facing right; used frames left-aligned; unused cells transparent

| Row | Animation | Frames | Timing / preview fps | Input and move | Pose sequence |
|---:|---|---:|---|---|---|
| 0 | `mana_combo` | 6 | combo-fit / 18fps preview | ground J chain | guard → slash 1 → slash 2 wind-up → slash 2 → wave finisher → recover |
| 1 | `rising_slash` | 4 | 0.20s / 20fps | up J, air up J | crouch → rise → overhead active → air recover |
| 2 | `low_sweep` | 4 | 0.20s / 20fps | ground down J | lower → pivot → ground sweep → recover |
| 3 | `air_slash` | 4 | 0.15s / 26.7fps | air side J | tuck → draw → horizontal active → recoil |
| 4 | `plunge` | 5 | 0.50s / 10fps | air down J | turn → chamber → dive → extension → landing lock |
| 5 | `dimension_slash` | 5 | 0.26s / 19.2fps | K · Dimension Slash | focus → draw → vanish cut → reappear → brake |
| 6 | `rune_shield` | 6 | 0.50s / 12fps | L · Rune Shield | set → raise → rune → full shield → absorb → release |
| 7 | `infinity_overdrive` | 6 | orbit-fit / 11fps preview | I · Infinity Overdrive start | focus → raise → one sword → six orbit → command → ready |

## Source and prompt

- Built-in ImageGen source: `rio_male_moves_source.png` (1160×1355).
- References: `rio_male_sheet.png` and `rio_male_illustration.png`.
- Prompt invariant: same male Rio, academy coat, cyan diamond, silver/cyan sword and
  cape tails; full idle body scale; eight ordered rows; hard alpha; no text/background.

## Processing and checks

Godot `Image` processing uses dynamic gutters and nearest reduction only (scale 0.6853).
The neutral scale anchor is +1px from live idle dark-body height and partial alpha is
zero. `dimension_slash` deliberately includes a body-absent streak frame; the transition
and cell-edge clipping of its long trail need human judgement.

