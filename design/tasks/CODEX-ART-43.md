# CODEX-ART-43 · Luna phase 2A: the new Luna anchor and the normal-form rows

- Request: 사용자 2026-10-14 "Luna 진행. Brave까지. 추가로, Luna가 궁극기를 사용할 때 변신하는 특별 모션이 있으면 좋겠다." Method D35, rules D32–D34. **Candidates only**; nothing in `smash-nine-prototype/` changes.
- Unit A: branch `codex/luna-43`, clone `SmashNine-units/builder-frey/SmashNine`. A Brave unit may start later in `builder-art`. Keep to your files.
- **First: a new Luna anchor `luna-idle-v3`.** The lead reviewed ART-42 and kept neither anchor.
  - `luna-idle-v2` has the detail, but its head is 0.92 of the current Luna's at the same 82-px height. That makes about 2.4 heads tall, and D25 sets Luna at **2.2 heads**.
  - Brave waits for the user's design choice and is not in this card.
  
  Draw the idle again as in ART-42 (6 frames, loop, 10.5 fps, the same breathing lines), with Image 1 = the current `luna_sheet.png` idle frame 1 ×4. The prompt must stress her chibi proportions exactly as Image 1: big head, 2.2 heads tall, short legs.
  - Choose the factor by the head: `head_scale.py --anchor smash-nine-prototype/assets/art/luna/luna_sheet.png:0` (the tool reads a game sheet's first row) must read 0.96–1.04.
  - The body height must then be 79–86 px. If it is taller, the drawing's proportions are wrong: regenerate (at most twice). Never squash.
  - Stop and report if neither generation passes.
- Then every row in this card uses the new anchor: Image 1 = `luna-idle-v3` (size, look, detail); Image 2 = the current game row ×4 nearest (what the move is; ignore its baked effects).
- Settings: `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`. One factor per sheet, matched with `head_scale.py --anchor art/bakeoff/luna/luna-idle-v3.png:0`, median 0.96–1.04.
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

## The special transformation
Not in this card. It waits for the user's Brave Luna design choice and gets its own card, which keeps the 12-frame plan from this card's first version (git history).

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
`art/bakeoff/luna/luna-*` (new files only, normal-form rows; not `luna_brave-*`; leave `retired/` alone), `art/raw/luna-43/**`, `reports/codex-art-43/**`. Hard stop 110 minutes; deliver finished rows and list the rest.
