# Frey move-only sprite sheets (D32, ART-33)

`frey_moves_sheet.png` is the runtime atlas loaded beside `frey_sheet.png`. ART-33 replaces the
ART-32 body atlas because ART-32 stamped the idle head over every generated drawing. Every ART-33
body frame is one complete drawing; no head, face, limb, weapon, shield, or other body part is
copied from another image.

## Outputs and atlas contract

- `frey_moves_body_sheet.png`: character and equipment only, 768x1024 RGBA PNG
- `frey_moves_fx_sheet.png`: retained independent slash, dust, and glint layer, 768x1024 RGBA PNG
- `frey_moves_sheet.png`: body + FX composite used by the game, 768x1024 RGBA PNG
- `frey_moves_heads.json`: independently reproducible measured head boxes for 35 used frames
- Grid: 6 columns x 8 rows, 128x128 per cell; used frames are left-aligned
- Every cell has zero opaque pixels on its outer 1-pixel border
- Ground frames use y=120 as the foot baseline
- Palette is 192 colours from canonical `frey_sheet.png`, with face and eye measurement colours
  reserved before frequency fill; alpha is hard
- Runtime row names, order, and counts are unchanged; no `Frey.gd` table change is required

| Row | Frames | FPS | Move |
|---|---:|---:|---|
| `attack_up` | 4 | 14 | ground/air up J |
| `attack_down` | 4 | 14 | ground/air down J |
| `attack_air_side` | 4 | 14 | air-side J |
| `dash_strike` | 4 | 14 | K directional dash strike |
| `rising_cleave` | 5 | 14 | L rising cleave |
| `spike_followup` | 4 | 14 | landed L re-input spike |
| `descent` | 6 | 14 | grounded and aerial I descent |
| `tumble` | 4 | 14 | strong-launch hitstun loop |

## Drawn-head measurement

The independent audit does not read `frey_moves_heads.json`. For each retained ART-32 source row it
finds the blue eye nearest that pose's expected face area, then measures the surrounding skin-colour
region from the source drawing. The finished frame's actual whole-drawing scale is measured again
from its opaque bounds. Their product is normalized to 22.95 pixels (102 source pixels at the 0.225
baseline). This measures the generated head already present in the drawing; it does not add pixels.

The five synthetic idle scales 0.70, 0.85, 1.00, 1.20, and 1.40 read back within 0.19%. The audit
also detects the two-head synthetic fixture and 32/35 ART-32 stamped frames. All 35 ART-33 frames
measure 0.9827-1.0030, have at most two merged eye-colour clusters, and contain no idle-head stamp.

## Body pixel operations

These are the only operations applied to body art:

1. Crop each complete connected pose from its retained row source.
2. Compute one scale factor for the entire pose from its drawn-head measurement.
3. Resize the entire pose once with nearest-neighbour sampling; no part is resized separately.
4. Quantize opaque RGB pixels to the canonical 192-colour palette and harden alpha at 0.5.
5. Place the entire pose in its 128x128 cell, align grounded feet to y=120, and clear the outer
   1-pixel cell border. No other trim is performed.

The exact crop, correction, scale, target size, and destination for every frame are recorded in
`reports/codex-art-33/body_pixel_operations.txt`. FX are not used to scale the body. The sole
semantic layer composition is `FX over body` after the body sheet is complete.

## Source decision and ImageGen round

All eight retained `tests/art_preview/frey_redo_32/*_body_source.png` strips were visually checked:
each frame already contained one complete Frey drawing and no pasted or duplicate head before the
ART-32 stamping step, so they were eligible for reuse under ART-33.

One built-in ImageGen comparison round was produced for `descent`, using `frey_sheet.png`,
`frey_illustration.png`, and the retained descent source as references. It requested a left idle
anchor plus six poses. The candidate produced seven drawings but its left slot was another combat
pose rather than the canonical idle anchor, so it was rejected and not copied into the project.

## Rebuild and audit

From `smash-nine-prototype/`:

```powershell
& $godot --headless --path . -s tests/art_preview/frey_heads_33/build_frey_heads.gd
& $godot --headless --path . -s tests/art_preview/frey_redo_32/head_audit.gd
```

Review aids are under `tests/art_preview/frey_heads_33/`: eight per-row 3x before/after contacts,
`head_boxes_after_3x.png`, the retained ART-32 failure fixture, and the audit text. Cyan boxes show
the measured head area; the label below each after frame is `scale/eye-cluster-count`.
