# CODEX-ART-49 · Yuki phase 2: every row from the anchor

- Request: 사용자 2026-10-14 "그 다음으로 Yuki를 같은 방식으로 작업 해볼 것." Method D35 (Frey, Luna), rules D32–D34, idle speed D37. **Candidates only**; nothing in `smash-nine-prototype/` changes.
- Unit: branch `codex/yuki-49`, clone `SmashNine-units/builder-frey/SmashNine`. A main-art unit runs in `builder-art`; keep to your files.
- **Anchor (accepted by the lead): `art/bakeoff/yuki/yuki-idle-v2.png`.** It is Image 1 for every row (size, look, detail). Image 2 = the current game row ×4 nearest (what the move is only; ignore its baked effects: flying talismans, flame barriers, glows).
- **Detail target, corrected:** ≥ 90 % of the current game idle's interior detail. That is **≥ 80** for Yuki: her current idle is 89.4, and her black hair and dark clothes give less contrast than Frey or Luna. The flat 90 in ART-48 was wrong for her; the anchor's 84.5 (95 %) passes.
- Settings: `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`. **One factor per row**, matched with `head_scale.py --anchor art/bakeoff/yuki/yuki-idle-v2.png:0`, median 0.96–1.04.
  - When the reliable frames (score ≥ 0.6) are fewer than 2, do not trust the median. Compare a standing frame's height with the anchor (89–91 px) and look at 4× head crops next to the anchor; say what you used. A low-confidence probe made Luna's transformation 1.2× too big.
  - Single poses drawn in one image each get their own head-matched factor.
- Cells: base rows 128 (feet y=120); move rows `--cell 192` (feet y=152, D34). One generation per motion, a second only if the first fails. Airborne frames are drawn lifted.
- **No effects.** The game draws the thrown talismans, waves, seals, barriers and pulses. A talisman in her hand is part of her; once thrown, her hand is empty.
- Every 4- or 5-frame motion becomes 6 frames with the same length (fps × 6 / old frames).

## Rows (in this order)
**Base sheet (128):**
1. `walk` 6, loop @10: a calm, light walk with the talisman fan in one hand. The legs must clearly stride: contact, down, passing, then the other side. Sleeves, hair and bow ribbons lag one frame.
2. `jump` / `fall` / `hurt`: one pose each, in one image, each normalised with its own factor.
   - jump: rising, knees tucked, sleeves trailing
   - fall: legs reaching down, sleeves and hair up
   - hurt: recoil, eyes squeezed, talismans still held
3. `shield` 6 @12: a guard. She raises crossed forearms with talismans held between her fingers: starts raising, braced, holds. No barrier drawn.
4. `attack` 6 @28.5: the base row is only a fallback. Normalise the `talisman_side` raw (row 5) at 128 with its head-matched factor if it fits, else with the largest factor that fits plus one common x shift. Say which.

**Move sheet (192):**

5. `talisman_side` 6 @28.5, neutral/side J, a quick straight throw.
   1. talisman drawn back by her ear
   2. step in
   3. throw, arm straight forward, talisman leaving her fingers
   4. follow-through, hand open
   5. recover
   6. ready
6. `talisman_up` 6 @25, up J: the same rhythm thrown upward.
7. `ground_ward` 6 @23.1, down J: she crouches and slaps a talisman onto the ground in front of her (the game draws the exorcism wave). Crouch, reach, slap, hold, rise, ready.
8. `talisman_air_side` 6 @33.3: airborne, a quick forward throw; all frames lifted.
9. `talisman_air_down` 6 @22.2: airborne, throwing a talisman downward.
10. `seal_place` 6 @18.7, K, placing a binding seal.
    1. draw a talisman
    2. two fingers raised before her face
    3. arm extended forward with the talisman between two fingers
    4. hold
    5. release
    6. recover
    
    Drawn facing right; the game handles other directions.
11. `seal_activate` 6 @19.2, L, releasing the wards.
    1. hands come together
    2. a ritual hand sign at the chest
    3. eyes closed, concentrating
    4. palms thrust out to both sides
    5. hold
    6. recover
12. `grand_ward` 6 @9.7, I, the ultimate "Four-Direction Grand Ward" (the game plays it over about 1.1 s and draws the four giant talismans and the circle).
    1. talismans fanned out, calm
    2. both arms raised, talismans spread
    3. hands brought together overhead
    4. the hand sign at the chest, sleeves flaring
    5. palms thrust forward, commanding
    6. hold that pose
13. `tumble` 6, loop @21, **a new row for Yuki**: knocked spinning after a strong hit, body curled, one full backward turn; the face is visible in at least 2 frames.

## Checks for every row
- head scale 0.96–1.04 (or the height and crop check above)
- border clear, 4 px margin, spill 0, detail ≥ 80
- one face; hands, sleeves, bow and bell, boots intact
- 4× next to the anchor; the motion reads as the move

## Output
- `art/bakeoff/yuki/yuki-<row>-vN.png` (next free version) + `.json` (`note` in Korean, `fps`, `frames`, and `cell`/`feet` for 192 rows).
- Raw generations go to `art/raw/yuki-49/` (git-ignored).
- `reports/codex-art-49/<row>/`: `prompt.txt`, `compare.png` (4×), `metrics.json`.
- `reports/codex-art-49/README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/yuki/yuki-*` (new files only; leave `retired/` and `yuki-idle-v2.*` alone), `art/raw/yuki-49/**`, `reports/codex-art-49/**`. Hard stop 130 minutes; deliver finished rows and list the rest.
