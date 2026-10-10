# Nova male move sheet

`nova_male_moves_sheet.png` is Nova's male-body per-move atlas. It supplements the
live `nova_male_sheet.png`; it does not replace the seven common animation rows.

## Contract

- Canvas: 768×1024 RGBA PNG
- Grid: 6 columns × 8 rows, 128×128 per cell
- Facing right; used frames are left-aligned and unused cells are transparent
- Runtime scale: the same 1:1 authored size as the 128px live sheet

| Row | Animation | Frames | Timing / preview fps | Input and move | Pose sequence |
|---:|---|---:|---|---|---|
| 0 | `vector_side` | 4 | 0.17s / 23.5fps | ground neutral/side J · Vector Strike | coil → launch → gravity punch → brake |
| 1 | `vector_upper` | 4 | 0.17–0.19s / 21–23.5fps | up J, air up J | crouch → rise → vertical active → air recover |
| 2 | `compression_stomp` | 4 | 0.23s / 17.4fps | ground down J | brace → compress → ground impact → recover |
| 3 | `air_side` | 4 | 0.15s / 26.7fps | air side J | tuck → align → flying punch → air brake |
| 4 | `meteor_kick` | 5 | 0.20s then landing hold / 25fps | air down J | turn → chamber → dive → meteor kick → landing lock |
| 5 | `vector_shift` | 4 | 0.22s / 18.2fps | K · Vector Shift | brace → streamline → streak → brake |
| 6 | `gravity_brake` | 5 | 0.42s / 11.9fps | L · Gravity Brake | speed → stop → cross fists → burst → recover |
| 7 | `slingshot_start` | 6 | duration-fit; last frame may hold | I first input · Event Horizon | plant → aim → gather → core → detach → orbit ready |

## Source and prompt

- Built-in ImageGen source: `nova_male_moves_source.png` (1374×1145).
- References on the generation call: `nova_male_sheet.png` for pixel scale/body and
  `nova_male_illustration.png` for identity/costume.
- Prompt invariant: exact same male Nova; eight ordered move rows; hard pixel edges;
  midnight-indigo/silver/teal/gold palette; no weapon, cape, text, guides, or background.

## Processing and checks

`tests/art_preview/moves_26/build_moves.gd` finds transparent row gutters, slices the
six columns, applies nearest-neighbour reduction only (scale 0.7302), hardens alpha,
removes detached islands below 3px, aligns ground anchors to y=120 and air anchors to
the live jump centre, then writes the sheet and contact boards.

The neutral scale anchor differs from the live idle dark-body height by +1px. All
partial-alpha pixels are removed. `vector_upper` has small detached gravity particles
and is the weakest row for human review.

