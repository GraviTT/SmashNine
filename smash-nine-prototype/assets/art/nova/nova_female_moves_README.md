# Nova female move sheet

`nova_female_moves_sheet.png` is the female-body counterpart to Nova's move atlas.
It shares row order, move meanings, timing and pose beats with the male sheet.

## Contract

- Canvas: 768×1024 RGBA PNG
- Grid: 6 columns × 8 rows, 128×128 per cell
- Facing right; used frames left-aligned; unused cells transparent

| Row | Animation | Frames | Timing / preview fps | Input and move |
|---:|---|---:|---|---|
| 0 | `vector_side` | 4 | 0.17s / 23.5fps | ground neutral/side J · Vector Strike |
| 1 | `vector_upper` | 4 | 0.17–0.19s / 21–23.5fps | up J, air up J |
| 2 | `compression_stomp` | 4 | 0.23s / 17.4fps | ground down J |
| 3 | `air_side` | 4 | 0.15s / 26.7fps | air side J |
| 4 | `meteor_kick` | 5 | 0.20s then landing hold / 25fps | air down J |
| 5 | `vector_shift` | 4 | 0.22s / 18.2fps | K · Vector Shift |
| 6 | `gravity_brake` | 5 | 0.42s / 11.9fps | L · Gravity Brake |
| 7 | `slingshot_start` | 6 | duration-fit; last frame may hold | I first input · Event Horizon |

The pose sequence for each row is identical to `nova_male_moves_README.md`.

## Source and prompt

- Built-in ImageGen source: `nova_female_moves_source.png` (1374×1145).
- References: `nova_female_sheet.png` and `nova_female_illustration.png`.
- Prompt invariant: preserve the short upswept hair, feminine live body, same suit,
  plates, emblems and palette; match the male row beats; hard alpha; no text/background.

## Processing and checks

Godot `Image` processing uses dynamic transparent gutters, nearest reduction only
(scale 0.7143), hard alpha, sub-3px island cleanup and live-sheet anchors. The neutral
scale anchor matches the live idle dark-body height (0px delta); partial alpha is zero.
The `meteor_kick` flame silhouette and `slingshot_start` core spacing need human taste
review at game speed.

