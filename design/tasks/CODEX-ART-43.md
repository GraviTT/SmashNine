# CODEX-ART-43 · Luna phase 2A: normal-form rows and the special transformation

- Request: 사용자 2026-10-14 "Luna 진행. Brave까지. 추가로, Luna가 궁극기를 사용할 때 변신하는 특별 모션이 있으면 좋겠다." Method D35, rules D32–D34. **Candidates only**; nothing in `smash-nine-prototype/` changes.
- Unit A: branch `codex/luna-43`, clone `SmashNine-units/builder-frey/SmashNine`. Unit B (`CODEX-ART-44.md`, the Brave rows) runs at the same time in `builder-art`. Keep to your files.
- Anchors (ART-42, accepted by the lead): `art/bakeoff/luna/luna-idle-v2.png` (Luna) and `art/bakeoff/luna/luna_brave-idle-v2.png` (Brave). Image 1 for every row is the right anchor (size, look, detail); Image 2 is the current game row ×4 nearest (what the move is; ignore its baked effects).
- Settings: `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`. One factor per sheet, matched with `head_scale.py --anchor art/bakeoff/luna/luna-idle-v2.png:0`, median 0.96–1.04.
- Cells: base rows 128 (feet y=120). Move rows `--cell 192` (feet y=152, D34). One generation per motion (512-px cells), a second only if the first fails. No effects: the game draws trails, star blooms, comets, rings and auras. Airborne frames are drawn lifted.
- Every 4- or 5-frame motion becomes 6 frames with the same length (fps × 6 / old frames).

## Rows (in this order)
**Base sheet (128):**
1. `walk` 6, loop @10: a light, cheerful walk holding the wand. The legs must clearly stride: right contact, down, left passing, left contact, down, right passing. Hair and ribbon lag one frame.
2. `jump` / `fall` / `hurt`: one pose each, in one image.
   - jump: rising, knees tucked, hair trailing down
   - fall: legs reaching down, hair and ribbon up
   - hurt: recoil back, eyes squeezed, wand still held
3. `attack` 6 @21, the side J "Star Echo": the wand draws a ribbon trail forward.
   1. wand back at the shoulder
   2. swing starts
   3. wand sweeping forward (active)
   4. arm extended, wand pointing forward
   5. follow-through
   6. recover
   
   If it cannot fit 128 at head scale 0.96–1.04, make it a 192 move-row candidate named `star_side` instead and say so.
4. `shield` 6 @12: guard, the wand held across the body. Starts lifting, braced, holds.

**Move sheet (192):**

5. `star_up` 6 @21: the wand swept from in front of her up over her head.
6. `star_down` 6 @21: the wand swept forward and down near the ground.
7. `star_comet` 6 @21, K: a casting thrust.
   1. wand drawn back
   2. lean in
   3. thrust forward, arm straight
   4. hold
   5. recoil
   6. recover
8. `moon_ring` 6 @16.8, L: she spins in place with the wand held out, as if drawing a ring around herself: front, side, back, other side, front, recover.
9. `tumble` 6, loop @21: knocked spinning after a strong hit, body curled, one full backward turn; the face is visible in at least 2 frames.

## The special transformation: `transform`, **12 frames** @12 fps (about 1 s)
The user wants a special motion when Luna uses her ultimate. She is a magical girl, so this is her transformation sequence: she starts in the **normal outfit with the wand** and ends as **Brave Luna with the star gauntlets**.

Draw it as two generations of 6 (3×2 each). Generate the second with the first as Image 1, plus the Brave anchor, so the spin and the size continue. The 12 frames go into one 192-px strip, 12 cells wide (2304×192).

1. Normal Luna, eyes closed, both hands holding the star wand at her chest, calling the power.
2. She raises the wand high over her head, looking up, rising onto her toes.
3. She lets the wand go upward; it hovers just above her open hand; arms spread.
4. The spin begins, lifted a little off the ground: 3/4 back view, arms crossed over her chest, hair swirling (normal outfit).
5. Spin, back view: hair wraps around her, skirt flared; the change is hidden behind her.
6. Spin, side view: the star gauntlets are now on her crossed fists; the outfit is turning into Brave's.
7. Spin, front 3/4 view: Brave outfit complete, arms still crossed, eyes closed.
8. The spin ends: arms uncross, fists out to the sides, hair settling (Brave).
9. She lands in a crouch, one fist planted on the ground (the game puts the transformation burst here).
10. She rises from the crouch, punching one fist up and forward.
11. Hero pose: one fist forward, the other on her hip, confident grin, a wink.
12. The same hero pose settling: hair and ribbon come to rest, ready to fight.

Rules for this row:
- Both outfits must read clearly: frames 1–5 are normal Luna, 6–12 are Brave.
- The head size is the anchor's in all 12 frames.
- No light, sparkles, ribbons of light, transformation glow or burst. The game draws them in time with these frames. The crossed arms and the turning body carry the change.
- Lift: frames 4–8 float a little (lifted in the cell); 9–12 stand on the floor line.
- JSON: `{"note": "...", "fps": 12, "frames": 12, "cell": 192, "feet": 152}`. This row is 12 cells wide; the lead adds two-row support to the game and the viewer.

## Checks for every row
- head scale 0.96–1.04 (rotated frames excepted; judge those by eye)
- border clear, 4 px margin, spill 0, detail ≥ 90
- one face; hands, wand or gauntlets, boots intact
- 4× next to the anchor; the motion reads as the move

## Output
- `art/bakeoff/luna/luna-<row>-vN.png` (next free version) + `.json` (`note`, `fps`, `frames`, and `cell`/`feet` for 192 rows).
- Raw generations go to `art/raw/luna-43/` (git-ignored).
- `reports/codex-art-43/<row>/`: `prompt.txt`, `compare.png` (4×), `metrics.json` (factor, lift, head scale).
- `reports/codex-art-43/README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/luna/luna-*` (new files only, normal-form rows; Brave files belong to unit B; leave `retired/` alone), `art/raw/luna-43/**`, `reports/codex-art-43/**`. Hard stop 110 minutes; the transformation comes last, so leave it unfinished rather than rush the other rows.
