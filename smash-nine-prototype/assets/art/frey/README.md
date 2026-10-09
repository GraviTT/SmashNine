# Frey original sprite sheet

`frey_sheet.png` is the active original-art Frey atlas. The illustration
`frey_illustration.png` is the face, costume, weapon, shield, palette, and proportion reference.

## Atlas contract (v2)

- Canvas: 768×896 RGBA PNG
- Grid: 6 columns × 7 rows; 128×128 per cell
- Facing: right
- Rows: idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1
- Grounded frames: lowest opaque pixel at cell y=120
- Unused cells: fully transparent
- Runtime: position `(0, -56)`, scale `1`, nearest-neighbour filtering
- Target proportion: approximately 3 heads tall

## CODEX-ART-21 review

All 23 used frames were checked individually at 4× and in row sequence. Attack frame 4's
edge-on shield was redrawn from the canonical illustration and adjacent attack frames so the
blue-and-gold oval and star remain readable during recovery. Shield frame 1 was moved up one
pixel to restore the y=120 baseline. All other used cells remain pixel-identical.

The retained ImageGen source, before/after contacts, measurements, and build scripts are in
`reports/codex-art-21/` and `tests/art_preview/sprite_review_21/`.
