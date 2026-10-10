# Rio female move sheet

`rio_female_moves_sheet.png` is the female-body counterpart to Rio's move atlas and
shares the male row table and animation beats. It preserves the live idle body's scale.

## Contract

- Canvas: 768×1024 RGBA PNG
- Grid: 6 columns × 8 rows, 128×128 per cell
- Facing right; used frames left-aligned; unused cells transparent

| Row | Animation | Frames | Timing / preview fps | Input and move |
|---:|---|---:|---|---|
| 0 | `mana_combo` | 6 | combo-fit / 18fps preview | ground J chain |
| 1 | `rising_slash` | 4 | 0.20s / 20fps | up J, air up J |
| 2 | `low_sweep` | 4 | 0.20s / 20fps | ground down J |
| 3 | `air_slash` | 4 | 0.15s / 26.7fps | air side J |
| 4 | `plunge` | 5 | 0.50s / 10fps | air down J |
| 5 | `dimension_slash` | 5 | 0.26s / 19.2fps | K · Dimension Slash |
| 6 | `rune_shield` | 6 | 0.50s / 12fps | L · Rune Shield |
| 7 | `infinity_overdrive` | 6 | orbit-fit / 11fps preview | I · Infinity Overdrive start |

The pose sequence for each row is identical to `rio_male_moves_README.md`.

## Source and prompt

- Built-in ImageGen source: `rio_female_moves_source.png` (1374×1145).
- References: `rio_female_sheet.png` and `rio_female_illustration.png`.
- Prompt invariant: preserve the long high ponytail, athletic feminine body, academy
  outfit, cyan diamond, silver/cyan sword and cape tails; full idle scale; same male
  beats; hard alpha; transparent; no text or guides.

## Processing and checks

Godot `Image` processing uses dynamic gutters and nearest reduction only (scale 0.7869).
The neutral scale anchor is +1px from live idle dark-body height and partial alpha is
zero. The long ponytail is intentionally a major silhouette feature. Human review should
focus on its motion continuity and the dense six-sword ultimate row at 1x.

