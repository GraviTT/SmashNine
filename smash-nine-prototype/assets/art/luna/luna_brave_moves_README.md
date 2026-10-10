# Brave Luna move-only sprite sheet

`luna_brave_moves_sheet.png` is loaded beside `luna_brave_sheet.png` while Luna is transformed.

## Atlas contract and rows

- Canvas: 768×1152 RGBA PNG; 6 columns × 9 rows; hard alpha; unused cells transparent
- Lowest visible pixel in used cells: y=120; right-facing; nearest filtering

| Row | Frames | FPS | Move |
|---|---:|---:|---|
| `brave_combo` | 6 | 16 | Brave J: guard/jab, kick wind-up/body kick, spin/recover |
| `brave_upper` | 4 | 16 | Brave up/air-up J |
| `brave_low` | 4 | 16 | Brave down J |
| `brave_air_side` | 4 | 16 | Brave air-side J |
| `brave_dive` | 4 | 16 | Brave air-down J |
| `comet_drive` | 4 | 16 | Brave K |
| `luna_breaker` | 6 | 16 | Brave L ground/air sequence |
| `heart_laser` | 6 | 12 | transformed I re-input |
| `tumble` | 4 | 14 | strong-launch hitstun (loops; optional hurt fallback) |

## Built-in ImageGen prompt

References on every generation: `luna_brave_sheet.png` for low stance, pixel scale, gauntlets and
boots; `luna_illustration.png` for identity, hair, bow and costume. The transparent 6×8 prompt
specified all eight ART-21 rows and explicitly required the jab, torso-height body kick and wide
spin kick to read as separate silhouettes at 1×. It required no wand, consistent 2.2-head size,
cyan-white starlight gauntlets, common baseline/body centre, and no text/grid/watermark.

`luna_brave_moves_source.png` is retained. The connected-component pipeline is the same as normal
Luna and never upscales the source. `tests/art_preview/moves_23/luna_brave_dive_redraw_source.png`
was generated with the Brave sheet and Luna illustration as references; its four compact side-view
dive-kick frames replace the unclear rear-facing dive row. The prompt fixed the face and kicking
boot as the readable landmarks and forbade merged silhouettes or oversized effects. The tumble row
is a nearest-neighbour quarter-turn sequence from the canonical Brave hurt frame.

## Checks

- `edge_audit.gd`: 12 edge-touching cells before → 0 after
- `verify_moves.gd`: 42/42 used cells non-empty, 12 unused cells empty, hard alpha; action rows y=120
- Sampled mean RGB distance to the canonical palette: 15.75/255 (max row/frame mean 17.62)
- 1×/4× review: `tests/art_preview/moves_23/luna_brave_moves_contact_{1x,4x}.png`

