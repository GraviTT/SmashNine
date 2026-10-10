# Luna normal-form move-only sprite sheet

`luna_moves_sheet.png` is the optional 128 px second atlas for normal Luna.

## Atlas contract and rows

- Canvas: 768×768 RGBA PNG; 6 columns × 6 rows; hard alpha; unused cells transparent
- Lowest visible pixel in used cells: y=120; right-facing; nearest filtering

| Row | Frames | FPS | Move |
|---|---:|---:|---|
| `star_up` | 4 | 14 | normal up/air-up J |
| `star_down` | 4 | 14 | normal down/air-down J |
| `star_comet` | 4 | 14 | normal K Star Comet |
| `moon_ring` | 5 | 14 | normal L Moon Ring |
| `transform` | 6 | 14 | I transformation start |
| `tumble` | 4 | 14 | strong-launch hitstun (loops; optional hurt fallback) |

## Built-in ImageGen prompt

References on every generation: `luna_sheet.png` for the 2.2-head pixel scale, outline, palette
and five-point wand; `luna_illustration.png` for the same face, pink hair, bow, costume and star
motifs. The transparent 6×5 prompt specified overhead and ground wand arcs, compressed/launching
comet, two semicircles completing a moon ring, and six transformation stages ending with Brave
gauntlets. It forbade redesign, extra characters, text, grid, watermark, antialiasing and cell
overlap.

`luna_moves_source.png` is retained. `rebuild_safe_sheets.gd` extracts each pose from its own
connected component instead of fixed-width slicing, attaches nearby effect components, preserves
the dense body band at canonical scale, compacts overflowing outer effects, hardens alpha and
aligns action frames to y=120. The generated RGB is retained after palette-distance measurement.
The tumble row is a nearest-neighbour quarter-turn sequence from the canonical hurt frame.

## Checks

- `edge_audit.gd`: 19 edge-touching cells before → 0 after
- `verify_moves.gd`: 27/27 used cells non-empty, 9 unused cells empty, hard alpha; action rows y=120
- Sampled mean RGB distance to the canonical palette: 15.60/255 (max row/frame mean 17.83)
- 1×/4× review: `tests/art_preview/moves_23/luna_moves_contact_{1x,4x}.png`

