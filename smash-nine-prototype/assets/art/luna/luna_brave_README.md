# Brave Luna original sprite sheet

`luna_brave_sheet.png` is the active transformed melee atlas loaded by `Luna.gd`. It keeps
normal Luna's pink hair, bow, star ornament, and costume palette while replacing the wand-led
silhouette with cyan-white starlight gauntlets and a low fighter stance.

## Atlas contract (v2)

- Canvas: 768×896 RGBA PNG
- Grid: 6 columns × 7 rows; 128×128 per cell
- Facing: right
- Rows: idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1
- Grounded frames: lowest opaque pixel at cell y=120
- Unused cells: fully transparent
- Runtime: position `(0, -56)`, scale `1`, nearest-neighbour filtering
- Target proportion: approximately 2.2 heads tall

## CODEX-ART-21 review

All 23 used frames were checked individually at 4× and in row sequence. The current attack row
reads as fast gauntlet pressure into a large finishing arc, and the shield row reads as a compact
star barrier. Mixed soft alpha was normalized to hard pixel alpha and grounded frames were
aligned to y=120. Three already-clean cells remain pixel-identical; unused cells remain empty.

The current four-frame attack row is still shared by every Brave basic and skill. The proposed
minimum skill-specific rows are documented in `reports/codex-art-21/README.md`; no extra rows
were drawn in this task.
