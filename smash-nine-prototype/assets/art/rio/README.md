# Rio original character sheets

`rio_male_sheet.png` and `rio_female_sheet.png` are two body variants of the same
Rio design. Matching 64x64 portrait candidates are included for the start screen.

## Kept from the character frame

- Western-fantasy academy prodigy, spellblade assassin, fast sword user
- Blue geometric rune shield rather than a carried shield
- Cyan mana edge on the diagonal sword attack
- Male and female sheets share one character identity

## Redesigned details

- Navy academy combat coat with teal panels, silver trim, and a cyan diamond emblem
- Slim silver sword with a cyan crystal guard
- Deep-indigo hair; the female variant uses a compact side ponytail
- Navy, teal, cyan, and silver palette, separate from Frey's gold/steel and Luna's pink/violet

Approximate palette: `#15295B`, `#0F6683`, `#39D8FF`, `#DCECF2`, outline `#10172A`.

The male and female variants intentionally keep the same coat construction, emblem,
sword, mana edge, rune geometry, and animation poses. The body, face presentation,
and hair silhouette provide the variant distinction.

## Atlas contract

- Canvas: 384x448 RGBA PNG per sheet
- Grid: 6 columns x 7 rows, 64x64 per cell
- Used frames: idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1
- Facing right; feet at cell y=48; unused cells transparent
- Runtime: position `(0, -32)`, scale `2`, nearest-neighbour filtering

`generated_male_source.png` and `generated_female_source.png` are ImageGen sources.
The final sheets and portraits were cropped, reduced, alpha-cleaned, and aligned with
Godot's `Image` API by `tests/art_preview/chars_b/build_sheets.gd`.
