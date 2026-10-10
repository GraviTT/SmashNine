# Frey move-only sprite sheet

`frey_moves_sheet.png` is the optional second atlas loaded beside `frey_sheet.png`.
It keeps the 128 px runtime cell, right-facing character, nearest filtering, and 3-head Frey design.

## Atlas contract

- Canvas: 768×1024 RGBA PNG; 6 columns × 8 rows; 128×128 per cell
- Used frames are left-aligned; every unused cell is transparent
- All visible pixels have alpha 1; transparent pixels have alpha 0
- Lowest visible pixel in every used cell is y=120
- Runtime fallback: if this file is absent, each move uses its former `attack`-row slice

| Row | Frames | FPS | Move |
|---|---:|---:|---|
| `attack_up` | 4 | 14 | ground/air up J |
| `attack_down` | 4 | 14 | ground/air down J |
| `attack_air_side` | 4 | 14 | air-side J |
| `dash_strike` | 4 | 14 | K directional dash strike |
| `rising_cleave` | 5 | 14 | L rising cleave |
| `spike_followup` | 4 | 14 | landed L re-input spike |
| `descent` | 6 | 14 | grounded and aerial I descent |
| `tumble` | 4 | 14 | strong-launch hitstun (loops; optional hurt fallback) |

## Built-in ImageGen prompt

References on every generation: `frey_sheet.png` (pixel scale, silhouette, palette) and
`frey_illustration.png` (face, winged helmet, armor, sword and blue-gold shield). The prompt asked
for one transparent 6-column/7-row pixel contact with the ART-21 pose sequence: rising slash,
downward slash, airborne horizontal slash, shield-led dash, rising cleave, downward spike and
six-stage descent. Invariants: same woman and 3-head proportion, right-facing, hard pixel edges,
same body size, common grounded baseline, no text/grid/watermark, no missing shield or extra weapon.

`frey_moves_source.png` is the retained built-in ImageGen result. The fixed-width slicer is
superseded by `rebuild_safe_sheets.gd`: it finds each pose by its own connected component, attaches
nearby effect components, preserves the dense body band at the canonical scale, and compacts only
overflowing outer effect bands. It then hardens alpha, removes under-3-pixel crumbs, maps colors to
the canonical Frey palette and aligns action frames to y=120. The tumble row is a nearest-neighbour
quarter-turn sequence derived from the canonical hurt frame.

Round-1 redraw source: `tests/art_preview/moves_23/frey_redraw_source.png` was generated with
`frey_sheet.png`, `frey_illustration.png` and the first move source as references. The prompt asked
for six compact side/three-quarter spike and descent frames with the face, sword and shield visible,
no rear-view hair/cape mass, hard alpha, no touching/cropping. Adopted frames replace
`spike_followup` 3–4 and `descent` 3–4.

## Checks

- `edge_audit.gd`: 20 edge-touching cells before → 0 after
- `verify_moves.gd`: 35/35 used cells non-empty, 13 unused cells empty, hard alpha; action rows y=120
- Mean RGB distance from generated source to the retained canonical palette: 15.78/255
- 1×/4× review: `tests/art_preview/moves_23/frey_moves_contact_{1x,4x}.png`

