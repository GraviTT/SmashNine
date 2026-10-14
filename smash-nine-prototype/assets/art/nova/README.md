# Nova original character sheets

**2026-10-14: both Nova bodies were redrawn (D33–D37).** The current contracts are in `nova_male_moves_README.md` and `nova_female_moves_README.md`. The sections below are history.

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

## CODEX-ART-34B walk redraw

The active male and female v2 sheets are 768×896 with 128 px cells. Only row 1 was
redrawn as a six-frame contact/down/passing walk loop. Each generated pose was kept as
one whole drawing, reduced only with nearest-neighbour whole-frame x/y scaling,
palette-family quantized to its own idle frame, hardened to binary alpha, and grounded at
cell y=120. No head or limb was pasted separately. The male source was regenerated after
lead review so midnight hair/suit and cyan trim remain distinct. Raw-pixel head boxes are
within 1 px of each sheet's idle box (male 46x43, female 51x41), and detached walk pixels
were removed. The row remains the existing six-frame, 10 fps looping `nova_walk`
animation; no runtime code changed. Source strips, before/after contacts, onion skins,
and measurements are in `tests/art_preview/walk_34/b/`.
