# Luna original character sheet

`luna_sheet.png` is Luna's original 6x7 animation sheet. `luna_portrait.png` is the
matching 64x64 start-screen portrait candidate.

## Kept from the character frame

- Female magical girl and mid-range star mage
- Jewel wand, bright star motifs, and wide readable magic
- Wand swing for attack and a small star barrier for shield

## Redesigned details

- Pink hair with a large midnight-purple bow for a strong small-scale silhouette
- Short cape/skirt outfit instead of copying the concept-art costume
- Five-point star wand head and cyan-violet crescent trails
- Hot pink, violet, pale cyan, and warm yellow palette, deliberately separate from Frey's gold/steel

Approximate palette: `#F35DA9`, `#662A91`, `#BCEBFF`, `#FFE06B`, outline `#171631`.

## Atlas contract

- Canvas: 384x448 RGBA PNG
- Grid: 6 columns x 7 rows, 64x64 per cell
- Used frames: idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1
- Facing right; feet at cell y=48; unused cells transparent
- Runtime: position `(0, -32)`, scale `2`, nearest-neighbour filtering

`generated_source.png` is the ImageGen source. The final sheet and portrait were
cropped, reduced, alpha-cleaned, and aligned with Godot's `Image` API by
`tests/art_preview/chars_b/build_sheets.gd`.
