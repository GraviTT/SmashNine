# CODEX-ART-61 · Rio remake phase 2: every row for one body (unit A: male, unit B: female)

- Request: 사용자 2026-10-15 "…이후 Rio의 스프라이트 리메이크 진행. 완성 될 때 까지 루틴으로. 단, … 성공한 사례만 따라갈것."
- Method D35, exactly as Nova's rows (`design/tasks/CODEX-ART-52.md`, `reports/codex-art-52a/`, `reports/codex-art-52b/`). Rules D25, D32–D34; idle speed D37. The walk follows ART-59 (the 8-frame walk method). **Candidates only**; nothing in `smash-nine-prototype/` changes.
- They run at the same time; each touches only its own body's files.

  | Unit | Body | Branch | Clone |
  | --- | --- | --- | --- |
  | A | `rio_male` | `codex/rio-61a` | `SmashNine-units/builder-frey/SmashNine` |
  | B | `rio_female` | `codex/rio-61b` | `SmashNine-units/builder-art/SmashNine` |

## The anchor and the references
- **Anchor (accepted by the lead): `art/bakeoff/rio/rio_<body>-idle-v2.png`.** It is Image 1 for every row: size, look, detail.
- Image 2 = that body's current game row, 4× nearest. It shows only what the move is. Ignore its baked effects: blue trails, mana waves, runes, afterimages, glow.
- **Detail target:** ≥ 90 % of the old idle: **male ≥ 79, female ≥ 73**.

## Settings
- `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`.
- **One factor per row**, matched to the anchor head:
  - `head_scale.py --anchor art/bakeoff/rio/rio_<body>-idle-v2.png:0`, median 0.96–1.04.
  - When fewer than 2 frames score ≥ 0.6, use 4× head crops next to the anchor and the height of a standing frame. Say which you used.
  - **Never size curled, crouched or stretched poses by height.**
  - Single poses drawn in one image each get their own factor.
- Cells: base rows 128 (feet y=120); move rows `--cell 192` (feet y=152, D34).
- One generation per motion; a second only if the first fails. Airborne frames are drawn lifted.
- **No effects:** no glow, trails, afterimages, mana waves, runes or orbiting swords. The game draws them. The blade is a solid bright blue shape.
- Every 4- or 5-frame motion becomes 6 frames of the same length (fps × 6 / old frames).

## Rows for your body, in this order
**Base sheet (128):**
1. `walk`, **8 frames, loop @13.3**, by ART-59's method exactly:
   - grey mannequin, frame 1 first, then the accepted frame 1 as Image 3
   - frames 3 and 7 in the passing pose
   - `walk_bob.py` once
   - `walk_feet.py` acceptance
   
   The sword stays low and forward as in the idle, and the cape lags.
2. `jump` / `fall` / `hurt`: one pose each, in one image, each with its own factor.
   - jump: rising, knees tucked, sword held back
   - fall: legs reaching down, hair and cape up
   - hurt: recoil back, eyes squeezed
3. `shield` 6 @12: the sword held across the body, braced. It starts raising, then braces, then holds. No barrier.
4. `attack` 6 @21: the base row is only a fallback. Normalise the `mana_combo` raw (row 5) at 128 with its head factor if it fits. Otherwise use the largest factor that fits plus one common x shift, and say which.

**Move sheet (192):**

5. `mana_combo` 6 @18, the ground J chain of three hits, two frames each. The game plays frames 1–2, then 3–4, then 5–6.
   - 1–2: slash 1, a quick forward cut
   - 3–4: slash 2, a backhand return cut
   - 5–6: the finisher, a big horizontal swing that would release the mana wave (do not draw the wave), then recover
6. `rising_slash` 6 @30, up J and air up J: crouch, rise, overhead cut active, follow-through, airborne recover, recover.
7. `low_sweep` 6 @30, ground down J: lower, pivot, a low sweep along the ground, active hold, recover, ready.
8. `air_slash` 6 @40, aerial side J, all airborne: tuck, draw, horizontal cut active, hold, recoil, recover.
9. `plunge` 6 @12, aerial down J until landing: turn, chamber, dive with the blade down, extension, landing lock, recover.
10. `dimension_slash` 6 @23, K: a blink slash. Focus, draw, a long horizontal cut at full extension (the body stretched along it), hold, reappear and brake, ready. Drawn facing right; no afterimage.
11. `rune_shield` 6 @12, L: set, raise the free hand, palm out, full guard, absorb a hit (braced), release. No rune circle.
12. `infinity_overdrive` 6 @11, the ultimate start: focus, raise the sword overhead, hold it high, command forward, hold, ready. No orbiting swords.
13. `tumble` 6, loop @21, **a new row for Rio**: knocked spinning after a strong hit, body curled, one full backward turn. The face is visible in at least 2 frames.

## Checks for every row
- head scale 0.96–1.04 (or the crop and height check above)
- border clear, 4 px margin, spill 0, detail at the target
- one face; hands, sword and boots intact
- 4× next to the anchor; the motion reads as the move
- for the walk, ART-59's acceptance

## Output
- `art/bakeoff/rio/rio_<body>-<row>-vN.png` (next free version), plus `.json` with:
  - `note`: plain Korean
  - `fps`, `frames`
  - `cell` and `feet` for 192 rows
- Raw generations go to `art/raw/rio-61<a|b>/` (git-ignored).
- `reports/codex-art-61<a|b>/<row>/`: `prompt.txt`, `compare.png` (4×), `metrics.json`.
- `reports/codex-art-61<a|b>/README.md` (Korean, short) and `commit.ps1`: no `git add -f`, nothing under `art/raw/`, no `__pycache__`.

## Writable
- `art/bakeoff/rio/rio_<your body>-*`: new files only. Not the anchor; leave `retired/` alone.
- `art/raw/rio-61<a|b>/**`, `reports/codex-art-61<a|b>/**`

Hard stop: 90 minutes. Deliver the finished rows and list the rest.
