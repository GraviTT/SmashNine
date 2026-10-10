# Frey move-only sprite sheets (D32)

`frey_moves_sheet.png` is the composite atlas loaded beside `frey_sheet.png`.
The D32 rebuild also keeps the character and effects as independent atlases so body scale never
changes to make a slash arc fit inside a cell.

## Outputs and atlas contract

- `frey_moves_body_sheet.png`: character/equipment only, 768x1024 RGBA PNG
- `frey_moves_fx_sheet.png`: slash, dust and glint layer only, 768x1024 RGBA PNG
- `frey_moves_sheet.png`: body + effect composite used by the game, 768x1024 RGBA PNG
- `frey_moves_heads.json`: idle reference and one head rectangle per used frame
- Grid: 6 columns x 8 rows, 128x128 per cell; used frames are left-aligned
- Every used and unused cell has zero opaque pixels on its outer 1-pixel border
- Ground frames use y=120 as the foot baseline; air frames are centred without scaling to fit
- Palette is quantized to the canonical `frey_sheet.png` palette and alpha is hard
- The runtime row names, order and frame counts are unchanged, so `Frey.gd` needs no table change

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

## Head reference and scaling

The reference is idle frame row 0, column 0 of `frey_sheet.png` at `(62, 27, 28, 32)`.
It includes hair, face and helmet but excludes the white helmet wings because their changing angle
is not a stable scale unit. Every new frame records a 28x32 head box. The independent audit does
not read the JSON: it searches scales 0.70 through 1.40 in 0.025 steps using exact canonical-palette
anchors, mirrored candidates and quarter-rotated tumble candidates. All 35 new matches are 1.000.

## Rebuild pipeline

The retained ImageGen originals are `tests/art_preview/frey_redo_32/*_source.png`. Each row was
generated as one horizontal body strip with no effects, then a separate effects-only strip. The
builder finds pose components rather than slicing equal source widths, scales all bodies from the
same head unit, quantizes to the base palette, overlays the canonical head reference, positions the
separate effects, clears the strict border and writes all three atlases plus the JSON and previews.

From `smash-nine-prototype/`:

```powershell
& $godot --headless --path . -s tests/art_preview/frey_redo_32/build_frey_redo.gd -- `
  --character=frey `
  --base=res://assets/art/frey/frey_sheet.png `
  --old=res://tests/art_preview/frey_redo_32/before_sheet.png `
  --source-dir=res://tests/art_preview/frey_redo_32 `
  --asset-dir=res://assets/art/frey `
  --preview-dir=res://tests/art_preview/frey_redo_32

& $godot --headless --path . -s tests/art_preview/frey_redo_32/head_audit.gd
```

For a later fighter, supply that fighter's base atlas, old move atlas, row source directory and
asset directory. The pilot script already accepts those paths and a character id; its row list,
reference box, effect anchors and grounded flags must be configured for that fighter before use.

## Generation rounds

- One body round kept: `dash_strike`, `rising_cleave`, `spike_followup`, `descent`, `tumble`
- Second body round kept: `attack_up`, `attack_down`, `attack_air_side` (tighter sword/limb layout)
- One independent effects round kept for every row
- No row reached the three-round limit

## Review aids

- Per-row old/new contacts at 1x and 3x: `tests/art_preview/frey_redo_32/*_before_after_{1x,3x}.png`
- Body/effect/composite contacts: `spike_followup_layers_{1x,3x}.png`, `descent_layers_{1x,3x}.png`
- Independent measurements: `head_audit.txt` and `*_head_audit.csv`
- Head rectangles over the composite: `head_boxes_{1x,3x}.png`

Measured consistency, border safety and file structure are automated checks. Pose readability,
animation flow, effect strength and whether rotated tumble faces look natural remain human art calls.
