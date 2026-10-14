# CODEX-ART-52 · Nova phase 2: every row for one body (unit A: male, unit B: female)

- Request: 사용자 2026-10-14 "다음은 Nova." Method D35 (Frey, Luna, Yuki), rules D25, D32–D34, idle speed D37. **Candidates only**; nothing in `smash-nine-prototype/` changes.
- **Unit A** (`nova_male`): branch `codex/nova-52a`, clone `SmashNine-units/builder-frey/SmashNine`.
- **Unit B** (`nova_female`): branch `codex/nova-52b`, clone `SmashNine-units/builder-ui/SmashNine`.
- They run at the same time; each touches only its own body's files.
- **Anchor (accepted by the lead): `art/bakeoff/nova/nova_<body>-idle-v2.png`.** Image 1 for every row (size, look, detail). Image 2 = that body's current game row ×4 nearest (what the move is only; ignore its baked effects: cyan trails, afterimages, shockwaves, the gravity core).
- **Detail target:** ≥ 90 % of the current idle: **male ≥ 84, female ≥ 79**.
- Settings: `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`. **One factor per row**, matched to the anchor head:
  - `head_scale.py --anchor art/bakeoff/nova/nova_<body>-idle-v2.png:0`, median 0.96–1.04.
  - When fewer than 2 frames score ≥ 0.6, use 4× head crops next to the anchor and the height of a standing frame. Say which you used.
  - **Curled, crouched or stretched poses must not be sized by height.** Yuki's tumble and ground_ward came out 1.2–1.3× too big that way.
  - Single poses drawn in one image each get their own factor.
- Cells: base rows 128 (feet y=120); move rows `--cell 192` (feet y=152, D34). One generation per motion, a second only if the first fails. Airborne frames are drawn lifted.
- **No effects:** no glow, trails, afterimages, shockwaves or the gravity core. The game draws them. The chest core is a solid cyan shape.
- Every 4- or 5-frame motion becomes 6 frames with the same length (fps × 6 / old frames).

## Rows for your body (in this order)
**Base sheet (128):**
1. `walk` 6, loop @10: a confident hero walk. The legs must clearly stride: contact, down, passing, then the other side. Hair lags one frame.
2. `jump` / `fall` / `hurt`: one pose each, in one image, each with its own factor.
   - jump: rising, knees tucked, fists up
   - fall: legs reaching down, hair up
   - hurt: recoil back, eyes squeezed
3. `shield` 6 @12: forearms crossed before the face, braced. Starts raising, braced, holds. No barrier.
4. `attack` 6 @35.25: the base row is only a fallback. Normalise the `vector_side` raw (row 5) at 128 with its head factor if it fits, else with the largest factor that fits plus one common x shift. Say which.

**Move sheet (192):**

5. `vector_side` 6 @35.25, neutral/side J: a dashing straight punch along the motion. Coil, push off, lean in, punch extended, hold, recover.
6. `vector_upper` 6 @33, up J: a rising uppercut that lifts her or him too. Crouch, drive up, fist rising (airborne), fist overhead at the top, hold, recover in the air.
7. `compression_stomp` 6 @26.1, down J on the ground: a gravity stomp. Knee raised, stamp down, deep squat on impact, hold, rise, ready.
8. `air_side` 6 @40, aerial side J: a flying punch along the flight path, all airborne. Chamber, extend, hold, recover.
9. `meteor_kick` 6 @30, aerial down J: a falling meteor kick until landing. Tuck, kick angled down, plunge, plunge, landing touch, recover.
10. `vector_shift` 6 @27.3, K: a pure acceleration, no attack. Crouch, launch, body streamlined horizontal with one fist leading, hold, hold, upright. Drawn facing right.
11. `gravity_brake` 6 @14.3, L: a sudden full stop that releases a gravity burst. Skid, plant, arms pulled in, arms thrust out to both sides, hold, recover.
12. `slingshot_start` 6 @14, the ultimate's first press: conjuring the gravity core. One hand drawn back, then thrust forward with the palm open, as if holding something; hold; recover.
13. `tumble` 6, loop @21, **a new row for Nova**: knocked spinning after a strong hit, body curled, one full backward turn; the face is visible in at least 2 frames.

## Checks for every row
- head scale 0.96–1.04 (or the crop and height check above)
- border clear, 4 px margin, spill 0, detail at the target
- one face; hands, gauntlets and boots intact
- 4× next to the anchor; the motion reads as the move

## Output
- `art/bakeoff/nova/nova_<body>-<row>-vN.png` (next free version) + `.json` (`note` in Korean, `fps`, `frames`, and `cell`/`feet` for 192 rows).
- Raw generations go to `art/raw/nova-52<a|b>/` (git-ignored).
- `reports/codex-art-52<a|b>/<row>/`: `prompt.txt`, `compare.png` (4×), `metrics.json`.
- `reports/codex-art-52<a|b>/README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/nova/nova_<your body>-*` (new files only; not the anchor; leave `retired/` and `main/` alone), `art/raw/nova-52<a|b>/**`, `reports/codex-art-52<a|b>/**`. Hard stop 130 minutes; deliver finished rows and list the rest.
