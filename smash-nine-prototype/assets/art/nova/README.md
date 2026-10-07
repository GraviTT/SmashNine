# Nova original character sheets

`nova_male_sheet.png` and `nova_female_sheet.png` are two body variants of the same
original cosmic-guard superhero design.

## Shared design

- Kept from the broad frame: superhero gravity striker, fast athletic silhouette,
  speed converted into impact, teal-to-gold momentum accents.
- Redesigned: short upswept midnight hair, face-visible fitted midnight-indigo suit,
  pale-silver chest/forearm plates, teal gauntlets and boots, circular gravity-orbit
  chest emblem. No cape or weapon.
- Intended palette: midnight indigo, pale silver, electric teal, small gold high-speed
  accents. It avoids Frey's blonde/steel shield silhouette and Yuki's plum/red robes.
- Attack row: coiled wind-up, launch, active momentum punch with gravity streak,
  braking recovery.
- Shield row: crossed forearms inside a compact circular gravity field.

## Variant consistency

Both variants use the same costume panels, emblem, gear, effect colours, hair identity,
animation actions, and atlas layout. The female variant uses narrower shoulders, a
defined waist, slightly wider hips, and a subtly feminine face; no exposed-skin costume
change was introduced. At 64x64 these differences are intentionally secondary to the
shared Nova identity, so the human reviewer should decide whether they read strongly
enough in motion.

## Atlas contract

- Each sheet: 384x448 RGBA PNG
- Grid: 6 columns x 7 rows, 64x64 per cell
- Rows: idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1
- Facing right; unused cells fully transparent
- Feet at y=48 and opaque-pixel centroid within 0.5px of x=32
- Runtime target: position `(0, -32)`, scale `2`, nearest-neighbour filtering

The two `nova_*_generated_source.png` files are built-in ImageGen sources. The Godot
script `tests/art_preview/chars_a/build_sheets.gd` performs the cell cutting, nearest
reduction, alpha cleanup, tiny-island cleanup, and alignment. The matching 64x64
`nova_*_portrait.png` files are optional start-screen portraits derived with Godot's
`Image` API.

## Lead integration

The existing Nova animation code already uses `CharacterAnimation.add_grid()`, but its
prototype atlas has 14 columns. For either new sheet use 6 columns, row starts
`0, 6, 12, 18, 24, 30, 36`, and counts `4, 6, 1, 1, 4, 6, 1`. The generic
`ArtSettings.character_sheet("nova", ...)` path does not select a gender variant;
the lead must choose `nova_male_sheet.png`, `nova_female_sheet.png`, or add explicit
variant selection. The builder unit did not edit `characters/nova/Nova.gd`.
