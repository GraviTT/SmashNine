# Realm hazard effect art

All files are transparent RGBA PNGs on a deliberate 2 px pixel grid. The generated source sheet was reduced to the accepted realm palettes and aligned with Godot 4.7 `Image` operations in `tests/art_preview/hazards_a/build_assets.gd`.

## Files and use

| File | Size | Integration |
|---|---:|---|
| `vine_bridge.png` | 96x24 | 3-slice: 24 px left cap / 48 px repeatable middle / 24 px right cap. Repeat only the middle; keep both caps unstretched. |
| `light_beam.png` | 64x128 | Vertically seamless tile. Nearest-neighbour scale to 70 px wide, then repeat/crop vertically to the warning height. |
| `fire_pillar.png` | 64x128 | Vertically seamless tile. Nearest-neighbour scale to 80 px wide, then repeat/crop to 460 px tall. |
| `vent_glyph.png` | 80x16 | Place on the platform directly beneath the warning column. Drawn orange; tint toward gold for Asgard. |

Disable filtering and mipmaps on import. Keep nearest-neighbour sampling and integer placement to preserve the pixel grid.

## Image-generation prompt

Built-in ImageGen was used once with the attached `Concept2.png` as a broad worldbuilding reference only. Final prompt:

> Use case: stylized-concept. Asset type: source sprite sheet for a Godot 4.7 2D pixel platform-brawler. Image 1 is broad worldbuilding, palette, and readable pixel-art reference only; redesign details freely. Create one transparent 1024x1024 source sheet containing exactly four isolated environmental hazard sprites, arranged in a clean 2x2 grid with generous empty transparent margins and no overlap. Top-left: a long side-view Vanaheim temporary vine bridge, braided living roots and leaves, perfectly horizontal, flat traversable top, symmetric curled root caps, forest green and moss gold. Top-right: a tall narrow Asgard falling light column, luminous white-gold core, stepped navy-gold rune edges, magical celestial energy, vertically tileable visual rhythm. Bottom-left: a tall narrow Muspelheim fire pillar, bright yellow core, orange-red flame tongues and dark ember outline, vertically tileable visual rhythm. Bottom-right: a long thin platform vent warning glyph, symmetrical Norse diamond/rune pattern embedded in dark basalt, orange-gold glow, perfectly horizontal. Style: polished limited-palette 2D pixel art, chunky intentional pixels, crisp silhouette, orthographic side view, game-ready VFX sprite source. Each item centered inside its quadrant; vine and glyph horizontal; light and fire columns vertical; leave at least 80 pixels transparent between items and around sheet edges. Genuine transparent background; each sprite fully visible; no shadows outside silhouette; no characters, scenery, labels, UI, words, logo, watermark, antialiased painterly blur.

The output was composition source, not a shippable sprite. Cropping, downsampling, palette mapping, alpha quantisation, 2 px nearest-neighbour enlargement, slice boundaries, and tile seam matching are deterministic in the Godot build script. The generated glyph's low-alpha bounding box collapsed at 80x16, so its generated diamond/arrow motif was redrawn on the logical pixel grid with Godot `Image.set_pixel`; its palette and motif still derive from the generated source.
