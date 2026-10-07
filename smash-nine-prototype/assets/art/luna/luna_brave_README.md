# Brave Luna original character sheet

`luna_brave_sheet.png` is Luna's transformed melee animation sheet. It is a
separate candidate asset and does not replace `luna_sheet.png`.

## Visual direction

- Keeps normal Luna's pink hair, large midnight-purple bow, star hair clip,
  magenta eyes, costume palette, and chibi proportions.
- Replaces the wand-led silhouette with glowing cyan-white starlight gauntlets,
  armored boots, and a low fighter stance.
- The attack row reads as jab, star-punch impact, body kick, and spinning kick.
- The shield row uses raised/crossed forearms behind a compact star barrier.

## Atlas contract

- Canvas: 384x448 RGBA PNG
- Grid: 6 columns x 7 rows, 64x64 per cell
- Used frames: idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1
- Facing right; feet at cell y=48; opaque centroid x=31.5..32.5
- Unused cells are fully transparent
- Runtime display contract: position `(0, -32)`, scale `2`, nearest-neighbour filtering

`luna_brave_generated_source.png` is the built-in ImageGen source. The final
sheet was split, hard-alpha cleaned, reduced with nearest-neighbour sampling,
centered, and rebuilt with Godot's `Image` API by
`tests/art_preview/luna_brave_a/build_assets.gd`.

## Lead integration

The current transformation changes combat logic and tint only. To use this
sheet, the lead should preload it in `characters/luna/Luna.gd`, build the same
seven grid animations used by `_configure_original_sheet("luna")`, switch the
`SpriteFrames` in `_enter_transformation()`, and restore the normal frames in
`_end_transformation()`. Preserve the current animation names so combat calls
continue to resolve without changes.
