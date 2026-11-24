# CODEX-SKM-07 · Xion: redraw the air-down J row (`shot_air_down`) as a real air pose (candidates)

- Request: the user (2026-11-24, "다시 그리기") asked for the row CODEX-SKM-06 held to be redrawn. Xion's other ten move rows, her icons and four effects are in the game since `0af7b909` (pick cup round `2026-11-24`); this row is the last stand-in (Nova's female drawing recoloured). **Candidates only**: the lead reviews them, the user picks in the pick cup (D49), then the lead puts the pick in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-a/SmashNine`, branch `codex/skm-07`. No other Codex unit runs.

## What went wrong in SKM-06 (do not repeat)
Two generations were held (`reports/codex-skm-06/README.md`, section `xion-shot_air_down`; the attempt folders `reports/codex-skm-06/xion/shot_air_down/attempt-1|2/` are still in this clone):
- **Feet planted on y=152 in every frame.** The row reads as a girl squatting on the ground, not in the air.
- Attempt 1: frames 2–4 are the same drawing, so the recoil is lost.
- Attempt 2: in frame 3 she straightens her legs and stands up; her head rises 15 px (about 4 px was asked).

## Her look (match the anchor exactly, as SKM-06)
- Anchor: `art/bakeoff/xion/b/xion-idle-b2.png` (6 frames in 128-px cells). Costume detail: `art/bakeoff/xion/b/xion_illustration-b2.png` (ignore the hologram double).
- Black bob with one silver-white streak; crimson scarf with two long tails; hip-length black coat with silver trim; black fitted clothes and boots; a short pump shotgun in **each hand** in every frame.
- **Never drawn:** no muzzle flash, smoke, bullets, shells, effects, ground or text. Draw nobody else.

## The air look (her other air frames in the game)
- Row 7 (`recoil_jump`, y 1152–1344) of `smash-nine-prototype/assets/art/xion/xion_moves_sheet.png`: frames 3–6 are in the air. Their lowest boot pixels are at y=143, 136, 128, 143 in 192-px cells (the SKM-06 attempts: y=152 in every frame): the boots are **above** the line.
- `smash-nine-prototype/assets/art/xion/xion_jump.png` and `xion_fall.png` (128-px cells, feet line y=120): legs bent or hanging, boots off the line.
- The game puts the cell point (96,152) on her feet point. In the air, boots above y=152 read as tucked legs. That is what this row needs.

## The row
| Row | fps | Loop | Used for | Six poses (facing right) |
| --- | ---: | --- | --- | --- |
| `shot_air_down` | 30 | no | J down in the air (frames 1–5 play; the 3rd frame is the shot) | (1) In the air, knees tucked up, both guns held low and pointing down. Lowest boot pixel about y=138–144. (2) Both guns pointing straight down below her, arms straight, still tucked (boots about y=138–144). (3) **The shot:** the recoil nudges her up: her head top is **3–5 px higher** than in (2). The legs kick out and flare apart and down (boots may reach about y=146–152). The guns kick up a little; the scarf tails and coat hem flip up. (4) Holding: guns still down, legs coming back in, head within 2 px of (3). (5) Recovering: guns swinging up toward the hips, legs hanging. (6) Falling, upright like `xion_fall.png`, both guns low; lowest boot about y=146–152. **No frame stands on the ground**: no planted soles, no squat with the boots flat on the line. |

## Method (as SKM-06)
- One generation per take: six poses in one line on `#00ff00`. Then run `tools/sprite_pipeline` with `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, one factor for the row, matched to the anchor.
- Copy `reports/codex-skm-06/*.py` into `reports/codex-skm-07/` and reuse them.
- **Cells:** 192 px, 6 frames, body centre x=96. Place each frame by the pose, not by the bottom edge: keep the boots where the table says.
- **Checks per take:**
  - Face 0.96–1.04 of the anchor (4× crops, `tools/sprite_pipeline/head_scale.py`).
  - **Rise (2)→(3): 3–5 px**, measured on the head top and on the face box. Report both numbers.
  - Lowest boot pixel per frame, in the note.
  - Costume and both guns as in the anchor; border clear, 4 px margin, spill 0; detail at least 90% of the anchor's; no fixed-width slicing.
- **Fixing the rise:** a take that passes everything but the rise may have whole frames moved up or down. Say so in its note, with the shift per frame.
- **Takes:** up to 3 generations. Deliver up to two passing takes as **two different candidates**: `v2` a compact tuck, `v3` a wider leg flare at the shot. If only one passes, deliver it as `v2`.

## Output
- **Row file:** `art/bakeoff/xion/b/xion-shot_air_down-v2.png` (and `-v3.png`) + `.json`:
  - `note`: Korean, one or two sentences, with the face ratio, the rise and the lowest boot per frame.
  - `for`: "공중 J 아래 사격".
  - `frames` 6, `fps` 30, `cell` 192, `feet` [96,152], `loop` false, `factor`.
- **Board:** `reports/codex-skm-07/xion-shot_air_down-v2.png` (and `-v3`): 4× next to the anchor and next to `recoil_jump` frames 3–6, with the y=152 line drawn.
- `reports/codex-skm-07/README.md` (Korean): takes, checks, measured vs guessed, what a human should judge.
- `reports/codex-skm-07/commit.ps1`: stages only the delivered row files, the boards, the README, the scripts and this card. No attempt folders, nothing under `art/raw/`, no `__pycache__`, no `run.log`. No committed text line ends with spaces.
- **Raw:** generations go in `art/raw/skm-07/` (git-ignored); prompts go in `reports/codex-skm-07/prompts.txt`.

## Writable
- **New files only:** `art/bakeoff/xion/b/xion-shot_air_down-v2.*`, `art/bakeoff/xion/b/xion-shot_air_down-v3.*`, `art/raw/skm-07/**`, `reports/codex-skm-07/**`.
- Nothing under `smash-nine-prototype/` changes.
- **Hard stop: 90 minutes.** Check the clock before each generation and after every image_gen call. Stop making new takes once the hard stop has passed.
