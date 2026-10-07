# Frey original sprite-sheet candidate

`frey_sheet.png` is an original replacement candidate for the current Frey placeholder.

## Atlas contract

- Canvas: 384x448 RGBA PNG
- Grid: 6 columns x 7 rows, 64x64 per cell
- Facing: right
- Used frames: idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1
- Unused cells: fully transparent
- Alignment: opaque-pixel centroid at x=31.50..32.47; feet at y=48 in all 23 used frames
- Runtime display contract: position `(0, -32)`, scale `2`, nearest-neighbour filtering

`generated_source.png` is the larger ImageGen source. `tests/art_preview/frey/build_sheet.gd`
uses Godot's `Image` API to split it, apply a hard alpha cutoff, remove detached small islands,
resize with nearest-neighbour, align each frame, and rebuild `frey_sheet.png`.

## Lead integration

After visual approval, change only the texture preload in `characters/frey/Frey.gd`:

```gdscript
const PROTOTYPE_TEXTURE := preload("res://assets/art/frey/frey_sheet.png")
```

The existing `configure_character_sprite()` row offsets, frame counts, frame rates, scale,
and animation names already match this sheet. This builder unit did not edit product source.

