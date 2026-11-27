# CODEX-SKM-08 · Rio: body rows for kit v3 — sword throw, counter stance, pierce, decoy step, flurry cut, both bodies (candidates)

- Request: the user (2026-11-27, "지금 시작"; the 총괄 session recommended starting Rio's art after Xion's) asked for Rio's kit v3 art, made with Codex and picked in the pick cup (D49). The kit is in the game (D50, `reports/rio-kit-2026-11-18/README.md`); its moves borrow old rows. **Candidates only**: the lead reviews them, the user picks, then the lead puts the picks in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-a/SmashNine`, branch `codex/skm-08`. CODEX-VFX-11 (his effects and icons) runs at the same time in `vfx-b`; you share no files.

## The moves (read `design/SKILLS.md`, Rio section)
Rio is a spellblade assassin who slips behind his foes. His moves today borrow rows that show other skills:
- **K 마검 투척:** throws a mana sword that sticks where it lands; K again blinks to it. Today: `dimension_slash` 1–3, which is a slash, not a throw.
- **L 그림자 받아치기:** a 0.4 s stance that takes the first hit, vanishes, and reappears behind the attacker. Today: `rune_shield`, a shield that no longer exists.
- **J 3타 관통 베기:** dashes through the foe, cutting, and stops behind him. Today: `mana_combo` 5–6.
- **U 분신 바꿔치기:** leaves a decoy and steps back about 150 px. Today: `dimension_slash` 5–6.
- **I 마검 난무 (second press):** blinks behind each foe and cuts him. Today: `mana_combo` 5–6 and 3–4.

## His look (match the anchors exactly)
- Anchors (face, costume, palette, detail): male `art/bakeoff/rio/rio_male-idle-v2.png`, female `art/bakeoff/rio/rio_female-idle-v2.png`. Also his move sheets `smash-nine-prototype/assets/art/rio/rio_{male,female}_moves_sheet.png` and `rio_{male,female}_moves_README.md`: the same cell size, placement and look.
- **Costume:** navy academy combat coat with teal panels, silver trim and a cyan diamond emblem. Deep-indigo hair; the female body has a compact side ponytail and narrower shoulders.
- **Sword:** a slim silver sword with a cyan crystal guard, in his **right** hand in every frame.
- **Palette:** navy, teal, cyan, silver (`#15295B`, `#0F6683`, `#39D8FF`, `#DCECF2`, outline `#10172A`).
- **Never drawn:** no thrown blade after it leaves the hand, no mana trail, rune, smoke, decoy, effect, ground or text. Draw nobody else.

## Method (as CODEX-SKM-05 and SKM-06; read `design/tasks/CODEX-SKM-05.md`, `reports/codex-skm-05/README.md`, `reports/codex-skm-06/README.md`)
- **One generation per row:** six poses in one line on `#00ff00`. Then run `tools/sprite_pipeline` with `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, one factor per row, matched to that body's anchor.
- Copy `reports/codex-skm-06/*.py` into `reports/codex-skm-08/` and reuse them.
- **Cells:** 192 px, 6 frames, feet on y=152, body centre x=96. Draw at the anchor's pixel scale: the cell is bigger, the man is not (D34).
- **Checks per row:**
  - Face 0.96–1.04 of that body's anchor on upright frames (4× crops: eye distance, face width at the eyes; `tools/sprite_pipeline/head_scale.py` too; the face decides).
  - Costume, hair and the sword in the right hand as in the anchor; the female body stays female (ponytail, narrower shoulders).
  - Border clear, 4 px margin, spill 0; detail at least 90% of the anchor's; no fixed-width slicing.
- **Deliver or hold:** deliver a row within 0.95–1.06 with the measured ratio in its note. Hold it only beyond that, or for a visible error (a missing sword, a third hand, the wrong body). Up to 2 generations per row.

## Rows (deliver in this order, each body right after the other)

| # | Body | Row | fps | Loop | Six poses (facing right) |
| ---: | --- | --- | ---: | --- | --- |
| 1 | male | `sword_throw` | 20 | no | (1) Stance as the idle, sword low in the right hand. (2) Turning side-on, the **left** hand drawn back past the ear, fingers together as if holding a blade (no blade drawn). (3) The throw: the left arm whips forward and the fingers open toward the target; the body leans in, the right hand keeps his sword low. (4) Follow-through, the left arm straight out. (5) Pulling back toward the stance. (6) Stance. |
| 2 | female | `sword_throw` | 20 | no | as row 1 |
| 3 | male | `counter_stance` | 15 | no | A calm, low ready stance that dares a hit: (1) sliding the back foot, knees bending. (2) The sword held reversed along the forearm in front of the chest, the left palm open forward. (3)–(6) Holding the stance: tiny breathing shifts only, the coat hem settling. Feet planted on y=152. |
| 4 | female | `counter_stance` | 15 | no | as row 3 |
| 5 | male | `pierce` | 20 | no | A dash-through cut: (1) leaning forward, sword drawn back low. (2) Lunging: body low and stretched forward, sword pointing ahead. (3) Passing through: the sword sweeps across from front to back at waist height, coat streaming behind. (4) Skidding to a stop, sword trailing behind, the back foot braking. (5) Turning his head back over the shoulder. (6) Ready stance. The game moves him 150 px; the poses stay near the cell centre. |
| 6 | female | `pierce` | 20 | no | as row 5 |
| 7 | male | `decoy_step` | 16 | no | A quick step back that leaves a decoy where he stood (no decoy drawn): (1) stance. (2) A small crouch, weight on the front foot. (3) Pushing off backward, body leaning back, sword held across. (4) Airborne back-step, knees bent (feet may lift up to 12 px). (5) Landing, knees bent. (6) Ready stance. |
| 8 | female | `decoy_step` | 16 | no | as row 7 |
| 9 | male | `flurry_cut` | 24 | no | The finishing cut after a blink behind a foe: (1) appearing crouched low, sword back. (2) Rising, the sword drawn high over the right shoulder with both hands. (3) The cut: a big diagonal down-stroke, body twisted. (4) Follow-through low, the sword pointing back-down. (5) Recovering, standing up. (6) Stance. |
| 10 | female | `flurry_cut` | 24 | no | as row 9 |

## Output (deliver each row as soon as it passes)
- **Row file:** `art/bakeoff/rio/rio_<body>-<row>-v1.png` + `.json`:
  - `note`: Korean, one or two sentences, with the face ratio.
  - `for`: Korean, what the row is used for, e.g. "K 마검 투척".
  - `frames` 6, `fps`, `cell` 192, `feet` [96,152], `loop`, `factor`.
- **Board:** `reports/codex-skm-08/rio_<body>-<row>.png`, a 4× board of the row next to that body's anchor.
- **After each row:**
  - Update `reports/codex-skm-08/README.md` (Korean): rows done, checks, what a human should judge, rows not reached.
  - Update `reports/codex-skm-08/commit.ps1`. It stages only the delivered row files, the boards, the README, the scripts and this card. It stages no attempt folders, nothing under `art/raw/`, no `__pycache__` and no `run.log`.
  - No line in a committed text file may end with spaces.
- **Raw:** generations go in `art/raw/skm-08/` (git-ignored); prompts go in `reports/codex-skm-08/prompts.txt`.

## Writable
- **New files only:** `art/bakeoff/rio/rio_{male,female}-{sword_throw,counter_stance,pierce,decoy_step,flurry_cut}-v*.*`, `art/raw/skm-08/**`, `reports/codex-skm-08/**`.
- Nothing under `smash-nine-prototype/` changes.
- **Hard stop: 150 minutes.** Check the clock before each generation and after every image_gen call. Deliver rows in order and list the rest.
