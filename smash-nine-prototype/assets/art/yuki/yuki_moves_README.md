# Yuki move sheet

`yuki_moves_sheet.png` supplements Yuki's seven-row live sheet with per-move poses.

## Contract

- Canvas: 768×1024 RGBA PNG
- Grid: 6 columns × 8 rows, 128×128 per cell
- Facing right; used frames left-aligned; unused cells transparent

| Row | Animation | Frames | Timing / preview fps | Input and move | Pose sequence |
|---:|---|---:|---|---|---|
| 0 | `talisman_side` | 4 | 0.21s / 19.0fps | ground neutral/side J | sign → draw → flick → recover |
| 1 | `talisman_up` | 4 | 0.24s / 16.7fps | up J, air up J | low sign → raise → upward flare → recover |
| 2 | `ground_ward` | 4 | 0.26s / 15.4fps | ground down J | step → sweep → low ward → recover |
| 3 | `talisman_air_side` | 4 | 0.18s / 22.2fps | air side J | tuck → draw → straight throw → recoil |
| 4 | `talisman_air_down` | 4 | 0.27s / 14.8fps | air down J | turn → aim down → falling cast → float |
| 5 | `seal_place` | 5 | 0.32s / 15.6fps | K · place seal | focus → draw → aim → place → sign |
| 6 | `seal_activate` | 5 | 0.30–0.32s / 15.6–16.7fps | L · activate seals / emergency ward | gather → sign → lift → ignite → recover |
| 7 | `grand_ward` | 6 | 0.62s / 9.7fps | I · Grand Ward start | focus → complex sign → orbit → glyph → cast → recover |

## Source and prompt

- Built-in ImageGen source: `yuki_moves_source.png` (1160×1355).
- References: `yuki_sheet.png` for scale/pixels and `yuki_illustration.png` for identity.
- Prompt invariant: same high ponytail, red-white cord, plum/vermilion/ivory shrine coat,
  talismans and yin-yang clasp; eight ordered rows; hard pixels; transparent; no text.

## Processing and checks

Godot `Image` processing uses dynamic row gutters and nearest reduction only (scale
0.7040). Alpha is binary, unused cells are empty and components below 3px are removed.
The neutral scale anchor is +1px from live idle dark-body height. The large red-orange
`grand_ward` and `seal_activate` effects are intentionally dense; their contrast and
the decorative unreadable marks on the papers need human review.

