# CODEX-SKM-06 · Xion: body rows for her kit — eleven move rows in her B look (candidates)

- Request: the user (2026-11-18, relayed by the 총괄 session) asked for Xion's skill motions to be made with Codex and picked in the pick cup (D49). Her kit is in the game (D51, `reports/xion-kit-2026-11-18/README.md`). Since 2026-11-24 her own base art is in the game: the user's pick B, the short coat (`reports/xion-art-2026-11-19/README.md`, main `b8594ca5`). Only `xion_moves_sheet.png` is still a stand-in: Nova's female rows recoloured. **Candidates only**: the lead reviews them, the user picks, then the lead puts the picks in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-a/SmashNine`, branch `codex/skm-06`. CODEX-VFX-10 (her effects and icons) runs at the same time in `vfx-b`; you share no files.

## Her look (match the anchor exactly)
- Anchor: `art/bakeoff/xion/b/xion-idle-b2.png` (6 frames in 128-px cells, 6.3 fps, height about 97 px). Also look at her new sheet `smash-nine-prototype/assets/art/xion/xion_sheet.png` (walk, attack, shield rows) and `art/bakeoff/xion/b/xion_illustration-b2.png`.
- **Hair:** a black bob with one silver-white streak.
- **Scarf:** crimson, with two long tails trailing behind. The tails follow the motion.
- **Coat:** a hip-length black coat with silver trim. Under it, black fitted clothes and black boots.
- **Guns:** a short pump shotgun in **each hand** in every frame: short barrel, thick muzzle, pump grip.
- **Never drawn:** no muzzle flash, smoke, bullets, shells, effects, hologram, ground or text. Draw nobody else.

## Method (as CODEX-SKM-02 to 05; read `design/tasks/CODEX-SKM-05.md`, `reports/codex-skm-05/README.md`, `reports/codex-art-72/README.md`)
- **One generation per row:** six poses in one line on `#00ff00`. Then run `tools/sprite_pipeline` with `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, one factor per row, matched to the anchor.
- Copy `reports/codex-skm-05/*.py` into `reports/codex-skm-06/` and reuse them.
- **Cells:** 192 px, 6 frames, feet on y=152, body centre x=96. Draw at the anchor's pixel scale: the cell is bigger, the girl is not (D34).
- **Checks per row:**
  - Face 0.96–1.04 of the anchor on upright frames. Measure in 4× crops (eye distance, face width at the eyes) and with `tools/sprite_pipeline/head_scale.py`; the face decides.
  - Costume and both guns as in the anchor.
  - Border clear, 4 px margin, spill 0.
  - Detail at least 90% of the anchor's.
  - No fixed-width slicing: cut each pose from its own blob.
- **Deliver or hold:** deliver a row within 0.95–1.06 with the measured ratio in its note. Hold it only beyond that, or for a visible error (a missing gun, a third hand, a broken scarf). Up to 2 generations per row.

## Rows (deliver in this order; the game uses them as `Xion.MOVE_SHEET_ROWS`)

| # | Row | fps | Loop | Used for | Six poses (facing right) |
| ---: | --- | ---: | --- | --- | --- |
| 1 | `shot` | 18 | no | J, side shot (right hand) | (1) stance as the idle, guns low. (2) The right arm snaps up: the right shotgun level at chest height, aimed right; the left gun stays low. (3) The shot: the right gun kicks up and back with the recoil, the shoulders jolt back, the scarf flicks. (4) The gun level again, a half step in. (5) The pump racked on the right gun, the arm lowering. (6) Back toward the stance. |
| 2 | `shot_alt` | 16 | no | J, side shot (left hand, every other shot) | As row 1 with the **left** arm: it crosses forward to aim right, the body turned a little more side-on. The shot at (3). |
| 3 | `double_float` | 10 | **yes** | her doppelganger (the game turns this into a crimson hologram) | Floating upright, toes pointing down, both guns held low and loose. Coat hem and scarf tails drift up a little. Over the six poses, a gentle bob (the whole body up 2–3 px and back). (6) flows into (1). Feet stay on y=152: the game lifts her. |
| 4 | `tumble` | 21 | **yes** | K, the roll (also strong launches) | A tight forward roll with the guns held to the chest: (1) diving forward low; (2) tucked on her back; (3) upside down, tucked; (4) tucked, coming round; (5) coming out of the roll; (6) crouching up. (6) flows into (1). |
| 5 | `recoil_jump` | 33 | no | L, every round fired down, she rises | (1) Crouch, both guns pointing straight down at her feet. (2) The blast: legs braced, body compressed. (3) Launched up: body stretched, legs trailing, guns still pointing down. (4) Rising, knees tucking. (5) The top, guns swinging forward. (6) Settling into a fall. (1)–(2) feet on y=152; (3)–(6) may rise up to 24 px above it. |
| 6 | `barrage` | 14 | **yes** | I, Equilibrium (shots all round, 2.5 s) | Gun kata in place: six angles of a turning firing stance, the arms out in opposite directions (one gun forward, one back). The body turns a sixth each frame (front, three-quarter, side, back three-quarter…). The scarf swirls. (6) flows into (1). Feet planted on y=152. |
| 7 | `dive` | 27 | no | U again, the 0.2 s dive to her doppelganger | A fast level flying dive to the right: (1) pushing off, leaning forward. (2) Body level, both guns forward, legs straight back, scarf streaming. (3)–(4) The same dive with the coat and scarf fluttering. (5) Knees tucking to land. (6) A landing crouch. In (2)–(4) the body is level, centred about y=120. |
| 8 | `double_cast` | 14 | no | U, leaving her doppelganger | (1) Stance. (2) A quick half-turn back, the left arm sweeping out behind her, palm open, as if calling someone behind her. Nobody is drawn. (3) The arm held out behind, looking over her shoulder. (4) Turning forward again, both guns raised and crossed at the chest. (5) Guns lowered, ready. (6) Stance. |
| 9 | `shot_up` | 13 | no | J up | (1) Stance. (2) Both guns raised straight up overhead. (3) The shot: the recoil bends her knees. (4)–(5) Recovering, guns coming down. (6) Stance. |
| 10 | `shot_down` | 26 | no | J down on the ground (a low shot ahead) | (1) Stance. (2) Dropping to a crouch. (3) The shot: both guns aimed low ahead, about 30° below level. (4) Holding the crouch. (5)–(6) Rising to the stance. |
| 11 | `shot_air_down` | 30 | no | J down in the air | (1) In the air, legs tucked. (2) Both guns pointing straight down below her. (3) The shot: the recoil nudges her up about 4 px, legs flaring. (4) Holding. (5)–(6) Recovering into a fall. Feet on y=152 (the game places her). |

## Output (deliver each row as soon as it passes)
- **Row file:** `art/bakeoff/xion/b/xion-<row>-v1.png` + `.json`:
  - `note`: Korean, one or two sentences, with the face ratio.
  - `for`: Korean, what the row is used for, e.g. "J 옆 사격(오른손)".
  - `frames` 6, `fps`, `cell` 192, `feet` [96,152], `loop`, `factor`.
- **Board:** `reports/codex-skm-06/xion-<row>.png`, a 4× board of the row next to the anchor. For a looping row, also show (6) next to (1) so the loop can be judged.
- **After each row:**
  - Update `reports/codex-skm-06/README.md` (Korean): rows done, checks, what a human should judge, rows not reached.
  - Update `reports/codex-skm-06/commit.ps1`. It stages only the delivered row files, the boards, the README, the scripts and this card. It stages no attempt folders, nothing under `art/raw/`, no `__pycache__` and no `run.log`.
  - No line in a committed text file may end with spaces: the lead's commit check rejects trailing whitespace.
- **Raw:** generations go in `art/raw/skm-06/` (git-ignored); prompts go in `reports/codex-skm-06/prompts.txt`.

## Writable
- **New files only:** `art/bakeoff/xion/b/xion-{shot,shot_alt,double_float,tumble,recoil_jump,barrage,dive,double_cast,shot_up,shot_down,shot_air_down}-v*.*`, `art/raw/skm-06/**`, `reports/codex-skm-06/**`.
- Nothing under `smash-nine-prototype/` changes.
- **Hard stop: 180 minutes.** Deliver rows in order and list the rest.
