# CODEX-ART-38 · Frey only, phase 2: the other rows at 6 frames with the ART-37 settings

- Request and rules as in `design/tasks/CODEX-ART-37.md` (사용자 2026-10-13 "Frey만 재작업 해볼것. 그리고, 현재 4프레임인 동작을 6프레임 이상으로 할 것.", D33, D32). **Candidates only**: nothing in `smash-nine-prototype/` changes.
- Unit: one unit, branch `codex/frey-38`, clone `SmashNine-units/builder-frey/SmashNine`. No other unit runs.
- Settings (ART-37, accepted by the lead at 3×): `--resample lanczos --sharpen 60 --despill auto --palette none`, `--bg #00ff00`. Detail came back to the current sheets' level (idle 94–98, attack 101–114 vs current idle 102).

## Task 0 · Green pockets (fix first)
The lead found pure-green pixels **inside** the figures:
- `frey-idle-v2` has 13, in frames 2–5, for example (28, 54) in frame 3 = (0, 75, 0) and (33, 54) in frame 4 = (0, 140, 0).
- `frey-attack-v4` has 22, for example frame 6 (33, 80) = (0, 168, 0).

They are chroma-key pockets enclosed between hair locks and between the cape and an arm. The pocket check runs after the shrink, when the pockets are already blended dark (G < 180), so it misses them. `spill_pixel_count` counts only the 2-px edge band, so the report said 0.

Fix:
1. Key out pockets on the **full-size source, before the shrink**: every pixel near the key colour becomes transparent whether or not it touches the border. The edge-band despill then also cleans the pocket rims.
2. Count spill over **all** visible pixels (G > max(R, B) + 20). For Frey it must be 0.
3. Add a test with an enclosed green pocket.
4. Re-normalise `frey-idle-v2` and `frey-attack-v4` **in place** from `art/raw/frey-37/` with the same factors, and redo their `compare.png` and `metrics.json` in `reports/codex-art-37/`.
- Anchor: `art/bakeoff/frey/frey-idle-v2.png` (ART-37) and its factor. Image 1 for every row = the anchor sheet (size, look, detail); Image 2 = the current game row ×4 nearest (what the move is; do not copy its drawing).
- Per row: one generation (a second only if the first fails), 512 px cells (6 frames = 3×2, 1536×1024). The prompt structure is ART-37's, including the detail style line and **no effects**. Use one factor per sheet, matched to the anchor's head on the clearest frame. If a frame does not fit, regenerate with a tighter pose; never shrink one frame. Airborne rows are drawn lifted, with no floor contact.
- Check every frame at 4× against the current game frame and the anchor:
  - interior detail ≥ 90 % of the current idle
  - one face, head size like the anchor
  - two arms, sword and shield intact
  - no green fringe
  - D32 ① border clear, 4 px margin

## Rows (in this order; stop at the hard stop and deliver the finished rows)
Next free version per row (e.g. `frey-walk-v2`, `frey-tumble-v3`); the json gives `note`, `fps` and `frames`.

1. `walk` 6, loop, 10 fps. The user said "walk에 걷는 모습이 전혀 보이지 않는다", so the legs must clearly stride. Sword low forward, shield on the front arm; cape and hair lag one frame.
   1. right heel contact, legs apart
   2. weight down, front knee bends
   3. left leg passing
   4. left heel contact
   5. weight down
   6. right leg passing
2. `shield` 6, 12 fps. No bubble or glow.
   1. starts lifting the shield
   2. shield half up, weight shifting back
   3. shield fully up in front of the body, knees bent, sword pulled back
   4. braced
   5. braced, small push forward
   6. braced hold
3. `jump`, `fall`, `hurt`: one pose each, in one image (3×1).
   - jump: rising, knees tucked, cape and hair trailing down
   - fall: descending, legs reaching down, hair and cape lifting
   - hurt: recoil backward, eyes squeezed, sword and shield still held
4. `attack_up` 6 @21: anti-air slash opening upward and forward from the body.
   1. crouch, sword low behind
   2. rising, sword sweeping forward low
   3. sword at shoulder height, moving up
   4. active: sword overhead pointing up-forward, body stretched
   5. follow-through, sword behind the head
   6. recover toward guard
5. `attack_down` 6 @21: cut forward and down at the landing spot.
   1. sword raised above the front shoulder
   2. lean forward, sword starting down
   3. active: downward cut in front
   4. blade near the floor in front
   5. hold low
   6. recover
6. `attack_air_side` 6 @21: airborne forward slash.
   1. sword drawn back, knees tucked
   2. lunge begins
   3. active: slash forward at chest height, arm fully extended
   4. extension held
   5. follow-through
   6. airborne guard
7. `dash_strike` 6 @21. The game holds frames 1–2 while she aims, plays 3–6 for the dash, and rotates the sprite to the dash direction, so draw it horizontal, facing right.
   1. aim: compact crouch, sword drawn back at the hip, shield forward
   2. deeper coil
   3. launch: body leaning hard forward, back foot pushing off
   4. thrust: body nearly horizontal, sword straight forward, arm fully extended, cape and hair streaming back
   5. thrust continues: cape and hair vary
   6. slash-through, body coming upright
8. `rising_cleave` 6 @16.8. Lift her from frame 3.
   1. crouch, sword low behind, shield up
   2. spring, sword starting its upward arc in front
   3. rising, sword sweeping up in front
   4. apex cleave: body stretched upward, sword straight above the head
   5. follow-through behind the head, knees tucking
   6. airborne guard, ready for the follow-up
9. `spike_followup` 6 @21. All airborne; she cannot act until landing.
   1. reload: sword high behind the head, body arched back
   2. deeper coil, knees tucked
   3. sweep begins over the top
   4. active: wide forward-down sweep across the chest line
   5. blade low forward, body leaning forward
   6. locked follow-through, compact, falling
10. `descent` 6 @14. No wings, shockwave or dust.
    1. charge: sword raised, knees bent
    2. sword point down, shield over it, body tucked (airborne)
    3. vertical drop: body straight, sword point below the feet, hair and cape streaming up
    4. landing squash: knees deep, sword driven into the ground in front
    5. braced impact, cape settling
    6. rising to guard
11. `tumble` 6, loop @21: knocked spinning after a strong hit, body curled, sword and shield held close. One full backward turn over the six frames; the face is visible in at least 2 frames.

## Output
- `art/bakeoff/frey/frey-<row>-vN.png` and `.json`.
- Raw generations go to `art/raw/frey-38/<row>/` (git-ignored).
- `reports/codex-art-38/<row>/`: `prompt.txt`, `compare.png` (4×), `metrics.json`.
- `reports/codex-art-38/README.md` (Korean): per-row notes and what is still wrong. Plus `commit.ps1`.

## Writable
`tools/sprite_pipeline/**` (Task 0), `art/bakeoff/frey/*` (new files, plus `frey-idle-v2.*` and `frey-attack-v4.*` in place; leave `retired/` alone), `art/raw/frey-38/**`, `reports/codex-art-37/{idle,attack}/**` (Task 0 redo), `reports/codex-art-38/**`. Hard stop 130 minutes.
