# CODEX-ART-100 · Jupi (look 2, the thunder drummer): every base-sheet row and the motion strips

- Request: the user picked the new characters' looks in the pick cup (round `2026-11-27-rio`, 2026-11-27). Jupi's look is **2, "the thunder drummer"**. The 총괄 set the body-art order (Jupi, then Borok, then Doron; one character at a time, D33) and gave this session two Codex units.
- Her kit (draft, approval pending): `reports/new-characters-2026-11-26/kits/README.md` section 3 (a light, nimble long-range lightning mage; the lightning leaves from her staff's tip). Her skill rows (the move sheet) come later from the skill session.
- Method: D35 and Xion's base art (`design/tasks/CODEX-ART-97.md`, `reports/codex-art-97a/README.md`, `reports/codex-art-97b/README.md`). The walk follows ART-59 (`design/tasks/CODEX-ART-59.md`). The motion strips follow ART-72 and ART-69. Rules: D25, D32–D37.
- **Candidates only.** Nothing under `smash-nine-prototype/` changes. The lead installs later, after the user's web-budget decision.
- **The anchor:** her concept idle frame, `art/bakeoff/newchar-2026-11-26/jupi/2/jupi-idle-2.png` (128 cell, 89 px, about 2.5 heads).
  - It is Image 1 for every row: size, look, detail.
  - Its look: black bob with a side braid, a white ceremonial outfit with yellow cords and tassels, charcoal tights, white boots, and a long staff taller than she is, topped by a ring of five small thunder drums.
- Two units at the same time, on different rows:

  | Unit | Rows | Branch | Clone |
  | --- | --- | --- | --- |
  | `art-a` | idle (6 frames from the anchor), attack, shield, victory, defeat | `codex/jupi-100a` | `SmashNine-units/art-a/SmashNine` |
  | `art-b` | walk; the jump, fall, hurt and land strips | `codex/jupi-100b` | `SmashNine-units/art-b/SmashNine` |

## Rows (all in `art/bakeoff/jupi/`)

| Unit | File | Cell | Frames | fps | Loop | What it shows |
| --- | --- | --- | --- | --- | --- | --- |
| `art-a` | `jupi-idle-v1.png` | 128 | 6 | 6.3 | yes | **Frame 1 is the anchor itself, unchanged.** Frames 2–6 breathe around it (inhale, top, exhale with the braid, cords and tassels lagging a frame, lowest, between), with the staff held steady |
| `art-a` | `jupi-attack-v1.png` | 128 | 6 | 35.25 | no | a short staff jab forward and back (the base sheet's fallback; her J is a move-sheet row later); keep the staff inside the cell |
| `art-a` | `jupi-shield-v1.png` | 128 | 6 | 12 | no | a guard: the staff held across in front of her, below the chin, body braced |
| `art-a` | `jupi-victory-v1.png` | 192 | 6 | 8 | holds the last | a short win: the staff twirled, ending planted beside her with a bright smile |
| `art-a` | `jupi-defeat-v1.png` | 192 | 6 | 10 | holds the last | ART-69's six steps: recoil, stagger, knees buckle, falling, hitting the ground, lying still; the staff dropped beside her |
| `art-b` | `jupi-walk-v1.png` | 128 | 8 | 13.3 | yes | a light walk, the staff held upright in her near hand, the far arm swinging gently |
| `art-b` | `jupi-jump-v1.png` | 128 | 3 | 10 | holds the last | take-off, rising, apex; lifted off the line |
| `art-b` | `jupi-fall-v1.png` | 128 | 2 | 8 | yes | falling; braid, cords and skirt flutter between the two |
| `art-b` | `jupi-hurt-v1.png` | 128 | 3 | 12 | holds the last | hit snap, recoil, recovering; feet on the line |
| `art-b` | `jupi-land-v1.png` | 128 | 2 | 12 | no | landing crouch, rising to the idle stance; feet on the line |

- **The staff in every frame:**
  - It is the same staff: long, thin, the five-drum ring on top.
  - It must fit the cell with the 4-px margin. Tilt it, or hold it lower, rather than shrinking her.
  - It never crosses her face.
- 192 cells: feet on y=152, the figure at the anchor's pixel scale (D34).
- **No effects:** no lightning, sparks, glow, motion lines or storm cloud. The game draws them, and the storm cloud is its own sprite.
- Keep the head and face clear in every frame.

## Method (each row)
- One generation per motion, the frames in a row on green, no effects (D35). Make a second only if the first fails.
- `normalize.py --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, `--cell 128` (feet y=120) or `--cell 192` (feet y=152).
- **One factor per row, matched to the anchor head:** `head_scale.py --anchor art/bakeoff/newchar-2026-11-26/jupi/2/jupi-idle-2.png:0`, median 0.96–1.04.
  - If fewer than 2 frames score ≥ 0.6, compare 4× head crops and say so.
  - Never size curled, crouched or stretched poses by height.
- Use **one shared horizontal anchor per row** where she stays in place (idle, attack, shield, victory, hurt, land), as ART-96b's `reports/codex-art-96b/normalize_idle.py` and the ART-97 fix did. Planted feet then move at most 3 px.
- **The walk (`art-b`):** ART-59 step by step.
  - a grey mannequin (`reports/codex-art-57/frey/make_walk_reference.py`) at her 2.5-head proportions, the staff held steady
  - costume words from the anchor
  - frame 1 first, then frames 2, 4, 5, 6, 8 with frame 1 as Image 3
  - frames 3 and 7 are the passing poses (`walk_feet.py`)
  - `--ground-all`, then `walk_bob.py` once (±3 px)
  - Acceptance as ART-59. Up to 3 generations per frame.
- Never stamp, paste or copy body parts between frames; every frame is one drawing (D32 ②).

## Checks (each row)
- Costume exactly as the anchor on a 4× board (`reports/codex-art-100<a|b>/<row>.png`): hair and braid, the white outfit and yellow cords, tights, boots, the staff and its drum ring.
- One face; hands intact on the staff.
- Border clear, 4-px margin, green spill 0, detail ≥ 90 % of the anchor's.
- Separate what you measured from what you judged by eye.

## Output
- In `art/bakeoff/jupi/`, each strip with a `.json`: `{"note": "<Korean>", "fps": <fps>, "frames": <n>, "loop": <true|false>}`.
- In `reports/codex-art-100<a|b>/`:
  - the 4× boards, `metrics.json` (per row: factor, head scale, detail, border, margin, spill)
  - for the walk (`art-b`): the feet and bob files
  - `prompts.txt`, `README.md` (Korean, UTF-8)
  - `commit.ps1`: the paths as a literal string array, only your files and this card, no `git add -f`, nothing under `art/raw/`, ending with `Co-Authored-By: Codex <noreply@openai.com>`; do not run it
- Raw generations go to `art/raw/jupi-100<a|b>/` (git-ignored).

## Writable
- `art-a`: `art/bakeoff/jupi/jupi-{idle,attack,shield,victory,defeat}-v1.*`, `art/raw/jupi-100a/**`, `reports/codex-art-100a/**`
- `art-b`: `art/bakeoff/jupi/jupi-{walk,jump,fall,hurt,land}-v1.*`, `art/raw/jupi-100b/**`, `reports/codex-art-100b/**`

Hard stop: 130 minutes. Deliver rows in the table's order and list the rest.
