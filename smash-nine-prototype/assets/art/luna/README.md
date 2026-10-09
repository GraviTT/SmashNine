# Luna original sprite sheet

`luna_sheet.png` is the active normal-form Luna atlas. `luna_illustration.png` is the face,
costume, five-point star wand, palette, and proportion reference.

## Atlas contract (v2)

- Canvas: 768×896 RGBA PNG
- Grid: 6 columns × 7 rows; 128×128 per cell
- Facing: right
- Rows: idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1
- Grounded frames: lowest opaque pixel at cell y=120
- Unused cells: fully transparent
- Runtime: position `(0, -56)`, scale `1`, nearest-neighbour filtering
- Target proportion: approximately 2.2 heads tall
- Palette identity: hot pink/violet, pale cyan, warm gold; dark violet outline

## Design notes (kept from the v1 sheet)

- Female magical girl and mid-range star mage: jewel wand, bright star motifs, wide readable magic
- Wand swing for attack and a small star barrier for shield
- Pink hair with a large midnight-purple bow for a strong small-scale silhouette
- Short cape/skirt outfit; five-point star wand head and cyan-violet crescent trails
- Approximate palette: `#F35DA9`, `#662A91`, `#BCEBFF`, `#FFE06B`, outline `#171631` (deliberately separate from Frey's gold/steel)

## CODEX-ART-21 review

All 23 used frames were checked individually at 4× and in row sequence. Idle frames 2 and 3
had a broken, undersized wand head; both were redrawn from the illustration and neighbouring
idle frames with a complete cyan-and-gold star. Mixed soft alpha was normalized to hard pixel
alpha, and grounded frames were aligned to y=120. Attack frame 4 was already clean and remains
pixel-identical.

The retained ImageGen sources, before/after contacts, measurements, and build scripts are in
`reports/codex-art-21/` and `tests/art_preview/sprite_review_21/`.
