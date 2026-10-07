# Yuki original character sheet

`yuki_sheet.png` is the original-art candidate for Yuki, the female Eastern-myth
onmyoji controller.

## Design

- Kept from the broad frame: female onmyoji, slight/nimble silhouette, paper talismans,
  ranged controller identity, held ward barrier.
- Redesigned: high black ponytail with a red-white cord, asymmetric deep-plum and
  vermilion shrine coat, dark fitted trousers, short boots, and a small yin-yang clasp.
- Intended palette: midnight/navy outline, black-violet hair, deep plum, vermilion,
  ivory paper, muted gold. It avoids Frey's blonde/steel/blue read.
- Attack row: wind-up, forward talisman flick, active paper trail, recovery.
- Shield row: held hand sign with a small red-gold seal barrier in front.

## Atlas contract

- Canvas: 384x448 RGBA PNG
- Grid: 6 columns x 7 rows, 64x64 per cell
- Rows: idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1
- Facing right; unused cells fully transparent
- Feet at y=48 and opaque-pixel centroid within 0.5px of x=32
- Runtime target: position `(0, -32)`, scale `2`, nearest-neighbour filtering

`yuki_generated_source.png` is the built-in ImageGen source. The Godot script
`tests/art_preview/chars_a/build_sheets.gd` cuts it into logical cells, reduces it with
nearest-neighbour sampling, applies a hard alpha cutoff, removes tiny detached islands,
and aligns every used frame. `yuki_portrait.png` is a 64x64 optional start-screen
portrait derived from the first idle frame with the same Godot `Image` workflow.

## Lead integration

The current Yuki implementation uses separate 128x128 strips. Original-art mode needs
the same 6-column `CharacterAnimation.add_grid()` layout already used by Frey:
row starts `0, 6, 12, 18, 24, 30, 36` and counts `4, 6, 1, 1, 4, 6, 1`.
The builder unit did not edit `characters/yuki/Yuki.gd`.
