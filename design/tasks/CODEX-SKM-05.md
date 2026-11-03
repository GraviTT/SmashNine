# CODEX-SKM-05 · Nova: body rows for her new kit — gravity beam, orb throw, field flight, both bodies (candidates)

- Request: the user (2026-11-03): Nova's new kit is in the game (D47, `reports/nova-kit-2026-11-03/README.md`, captures `board.png`) with stand-in art; "Codex로 만들기" — make the art. **Candidates only**: the user picks in the motion viewer, then the lead puts the picks in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-a/SmashNine`, branch `codex/skm-05` (from main `e5df3cc1`). VFX-05 (Nova's effects and icons) runs at the same time in `vfx-b`; you share no files.

## The three moves (read `design/SKILLS.md`, Nova section)
- **U "중력 광선" (Gravity Beam):** a beam from her palm; the first foe it reaches is **dragged to her** (or slammed down when in the air). Today it borrows `vector_side` frames 5-6 (a punch). Needs an aim, a palm thrust and a **haul-back** (she pulls the foe in like a rope; no beam or rope drawn).
- **K "중력 구체" (Gravity Orb):** she throws a small gravity orb that bursts and pulls. Today it borrows `gravity_brake`. Needs a **one-arm throw** from cupped hands (no orb drawn).
- **L "중력 필드" flight:** inside her own gravity field she **flies** freely in eight directions. Today she shows the jump/fall frames. Needs a **looping hover** (superhero flight, calm).
- Not in this card: the field's cast pose uses the existing candidate `nova_{male,female}-zero_gravity-v1` (both palms thrust up).

## Method (as CODEX-SKM-02/03/04 and ART-72/77; read `design/tasks/CODEX-SKM-02.md`, `design/tasks/CODEX-ART-77.md`, `reports/codex-art-72/README.md`, `reports/codex-skm-04/README.md`)
- Anchors (face, costume, palette, detail): male `art/bakeoff/nova/nova_male-idle-v2.png`, female `art/bakeoff/nova/nova_female-idle-v2.png`. Also the move sheets `smash-nine-prototype/assets/art/nova/nova_{male,female}_moves_sheet.png` and their `*_moves_README.md`: same cell size, placement and look.
- Costume exactly as the idle: short upswept midnight hair, fitted midnight-indigo suit, pale-silver chest and forearm plates, teal gauntlets and boots, the circular gravity-orbit chest emblem. No cape, no weapon. The female body: narrower shoulders, defined waist, the same costume.
- One generation per row (six poses in one line on `#00ff00`, no effects, no beam, no orb, no text, nobody else drawn), then `tools/sprite_pipeline` with `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, one factor per row matched to the anchor. Copy `reports/codex-skm-04/*.py` into `reports/codex-skm-05/` and reuse them.
- 192-px cells, 6 frames, feet on y=152, body centre x=96. The flight row keeps the feet on y=152 too: the game lifts her, the drawing does not.
- Checks per row: face 0.96–1.04 on upright frames (4× crops: eye distance and face width at the eyes; `head_scale.py` too, the face decides). Deliver a row within 0.95–1.06 with the measured ratio in its note; hold it only beyond that or for a visible error. Costume and both hands as the idle; border clear; 4 px margin; spill 0; detail ≥ 79; no fixed-width slicing (each pose cut from its own blob). Up to 2 generations per row.

## Rows (deliver in this order, each body right after the other)

| # | Form | Row | fps | Loop | Six poses |
| ---: | --- | --- | --- | --- | --- |
| 1 | Nova male | `gravity_beam` | 18 | no | (1) turning side-on, the front palm raised to aim, the back hand drawn to the hip; (2) the palm thrust straight forward at chest height, fingers spread (the beam leaves it; nothing drawn); (3) holding the aim, braced, the back foot planted; (4) the haul: the open hand closes to a fist and pulls back toward the chest, leaning back as if hauling a heavy rope; (5) the fist at the hip, the other hand open in front to catch; (6) back to the stance, like the idle |
| 2 | Nova female | `gravity_beam` | 18 | no | as row 1 |
| 3 | Nova male | `orb_throw` | 16 | no | (1) both hands cupped together at the hip as if holding a ball (no ball drawn); (2) torso twisting back, the cupped hands behind; (3) stepping forward; (4) the throw: one arm pushed straight forward, palm open; (5) follow-through, the arm extended, the other arm back for balance; (6) recovering into the stance |
| 4 | Nova female | `orb_throw` | 16 | no | as row 3 |
| 5 | Nova male | `field_fly` | 10 | **yes** | calm superhero hover facing right: body upright and leaning slightly forward, legs together with the toes pointing down, arms loose at the sides with open hands; over the six poses a gentle bob (the whole body up 2–3 px and back), the knees bending a little, the hair lifting; (6) flows back into (1). No ground drawn |
| 6 | Nova female | `field_fly` | 10 | **yes** | as row 5 |

## Output (deliver each row as soon as it passes)
- `art/bakeoff/nova/nova_<body>-<row>-v1.png` + `.json`: `note` (Korean, one or two sentences, with the face ratio if outside 0.96–1.04), `for` (Korean: "U 중력 광선 조준·끌어당기기" / "K 중력 구체 던지기" / "L 중력 필드 안 비행"), `frames` 6, `fps`, `cell` 192, `feet` [96,152], `loop`, `factor`.
- `reports/codex-skm-05/nova_<body>-<row>.png`: a 4× board of the row next to its anchor. For `field_fly` also show (6) next to (1) so the loop can be judged.
- After each row update `reports/codex-skm-05/README.md` (Korean: rows done, checks, what a human should judge, rows not reached) and `reports/codex-skm-05/commit.ps1` (only the delivered row files, the boards, the README, the scripts and this card; no attempt folders, nothing under `art/raw/`, no `__pycache__`, no `run.log`). No line in a committed text file may end with spaces (the lead's commit check rejects trailing whitespace).
- Raw generations in `art/raw/skm-05/` (git-ignored); `reports/codex-skm-05/prompts.txt`.

## Writable
New files only: `art/bakeoff/nova/nova_{male,female}-{gravity_beam,orb_throw,field_fly}-v*.*`, `art/raw/skm-05/**`, `reports/codex-skm-05/**`. Nothing under `smash-nine-prototype/` changes. **Hard stop: 120 minutes.** Deliver rows in order and list the rest.
