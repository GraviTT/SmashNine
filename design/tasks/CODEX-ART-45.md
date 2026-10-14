# CODEX-ART-45 · Brave Luna rows in the chosen design (② ponytail combat outfit)

- Request: 사용자 2026-10-14 "Luna 진행. Brave까지." Method D35, rules D32–D34. **Candidates only**; nothing in `smash-nine-prototype/` changes.
- Unit B: branch `codex/luna-45`, clone `SmashNine-units/builder-art/SmashNine`. Unit A (`CODEX-ART-43.md`: the new Luna anchor and the normal-form rows) runs at the same time in `builder-frey`. Keep to your files.
- **Design (user's pick 2026-10-14 from ART-44): ② `luna_brave-idle-v4`.** It is the anchor and Image 1 for every row (size, look, detail):
  - a high ponytail tied with the purple bow and the gold star
  - a sleeveless top, a short skirt over shorts, a short scarf, in Luna's purples and white
  - purple-and-gold armoured gauntlets to the forearm and armoured boots with star knee guards
  - Luna's face and magenta eyes; 2.2 heads tall
  
  The ponytail and the scarf lag one frame in motion. Image 2 = the current game row ×4 nearest (what the move is only; it shows the old outfit, so never copy its clothes, hair or the orbs of light).
- Settings: `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`. One factor per sheet, matched with `head_scale.py --anchor art/bakeoff/luna/luna_brave-idle-v4.png:0` (the anchor; its head is 1.00 of the current Luna's), median 0.96–1.04.
- Cells: base rows 128 (feet y=120); move rows `--cell 192` (feet y=152, D34). One generation per motion, a second only if the first fails. No effects: the game draws the star bursts, the comet light, the heart laser and the aura. The gauntlets are solid objects with no glow halo. Airborne frames are drawn lifted.
- Every 4-frame motion becomes 6 with the same length (fps × 6 / 4); the 6-frame rows keep their fps.

## Rows (in this order)
**Base sheet (128):**
1. `walk` 6, loop @10: a bouncy brawler walk, fists up. The legs must clearly stride (contact, down, passing, then the other side); hair and ribbon lag one frame.
2. `jump` / `fall` / `hurt`: one pose each, in one image.
   - jump: rising, knees tucked, fists up
   - fall: legs reaching down
   - hurt: recoil, eyes squeezed
3. `shield` 6 @12: gauntlets crossed in front of the face. Starts raising, braced, holds.
4. `attack` 6 @16: the base row is only a fallback. Normalise the `brave_combo` raw (row 5) a second time at 128 with the largest single factor that fits, and say what head scale that gives.

**Move sheet (192):**

5. `brave_combo` 6 @16, J: three hits, two frames each (the game plays 1–2, 3–4, 5–6).
   1. guard
   2. straight jab
   3. body-kick chamber
   4. body-height kick
   5. spin-kick wind-up
   6. wide spin kick
6. `brave_upper` 6 @24, up J: a star uppercut that lifts her (crouch, drive up, fist rising, airborne at the top, fist overhead, recover in the air).
7. `brave_low` 6 @24, down J: a low leg sweep (drop low, sweep a leg along the floor, follow through, recover).
8. `brave_air_side` 6 @24, air side J: a forward flying kick (chamber, extend, hold, recover), all airborne.
9. `brave_dive` 6 @24, air down J: a diving kick downward until she lands (tuck, kick angled down, dive, dive, landing touch, recover).
10. `comet_drive` 6 @24, K: a short dash with a compressed star punch (crouch, push off, lunging punch, extended, hold, recover). The game rotates nothing; it is drawn facing right.
11. `luna_breaker` 6 @16, L: a big spinning finishing kick (wind-up, turn, back to the viewer, spinning heel kick extended, follow-through, recover).
12. `heart_laser` 6 @12: the game holds the last frame while the laser lasts.
    1. plant feet
    2. hands drawn in
    3. hands forming a heart shape at the chest
    4. heart pushed forward, arms straight, braced
    5. firing stance, braced
    6. the same stance held
13. `tumble` 6, loop @21: spinning after a strong hit, body curled, one full backward turn; the face is visible in at least 2 frames.

## Checks for every row
- head scale 0.96–1.04 (rotated frames excepted; judge by eye)
- border clear, 4 px margin, spill 0, detail ≥ 90
- one face; two gauntlets, boots intact
- 4× next to the anchor; the motion reads as the move

## Output
- `art/bakeoff/luna/luna_brave-<row>-vN.png` (next free version) + `.json` (`note`, `fps`, `frames`, and `cell`/`feet` for 192 rows).
- Raw generations go to `art/raw/luna-45/` (git-ignored).
- `reports/codex-art-45/<row>/`: `prompt.txt`, `compare.png` (4×), `metrics.json`.
- `reports/codex-art-45/README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/luna/luna_brave-*` (new files only; leave `retired/` alone), `art/raw/luna-45/**`, `reports/codex-art-45/**`. Hard stop 110 minutes; deliver finished rows and list the rest.
