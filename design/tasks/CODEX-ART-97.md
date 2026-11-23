# CODEX-ART-97 · Xion B, stage 2: every base-sheet row and the motion strips from the anchor

- Request: the user picked **B (the short coat)** (pick cup round `2026-11-19`, item `xion-concept`), then said "전부 진행해" (2026-11-23, through the 총괄 session). Stage 1 (`CODEX-ART-96.md`) made the anchor this card follows.
- **Anchor: `art/bakeoff/xion/b/xion-idle-b2.png`** (6 frames). It is Image 1 for every row: size, look, detail, the scarf's length.
- Method: D35 and the rows of Nova and Rio (`design/tasks/CODEX-ART-61.md`, `reports/codex-art-61b/README.md`). Rules: D25, D32–D37.
  - The walk follows ART-59 exactly (`design/tasks/CODEX-ART-59.md`, the grey mannequin of ART-57, the passing poses of ART-58).
  - The motion strips follow ART-72 and ART-69 (`design/tasks/CODEX-ART-72.md`, `CODEX-ART-69.md`).
- **Candidates only:** nothing under `smash-nine-prototype/` changes. The lead assembles `xion_sheet.png` and installs the strips.
- Two units run at the same time on different rows:

  | Unit | Rows | Branch | Clone |
  | --- | --- | --- | --- |
  | `art-b` | walk; jump, fall, hurt, land strips | `codex/xion-97b` | `SmashNine-units/art-b/SmashNine` |
  | `art-a` | attack, shield; victory, defeat | `codex/xion-97a` | `SmashNine-units/art-a/SmashNine` |

## Xion B (from the anchor)
- A black hip-length coat with silver lines.
- A long crimson scarf tied below the chin, two tails trailing behind.
- Short black hair with a silver streak; fingerless gloves, fitted trousers, buckled boots.
- One short pump shotgun in each hand (the same model).
- 3 heads, about 96–98 px standing, facing right.
- **Keep the head and face clear in every frame:** guns, hands and the scarf never cross the head or face.
- **No effects:** no muzzle flash, smoke, recoil lines, sparks or glow. The game draws them.

## Rows

| Unit | File (`art/bakeoff/xion/b/`) | Cell | Frames | fps | Loop | What it shows |
| --- | --- | --- | --- | --- | --- | --- |
| `art-b` | `xion-walk-b2.png` | 128 | 8 | 13.3 | yes | a walk, both guns held low and steady, the scarf trailing |
| `art-b` | `xion-jump-b2.png` | 128 | 3 | 10 | holds the last | take-off spring, rising, apex; lifted off the line |
| `art-b` | `xion-fall-b2.png` | 128 | 2 | 8 | yes | falling; hair, coat tails and scarf flutter between the two |
| `art-b` | `xion-hurt-b2.png` | 128 | 3 | 12 | holds the last | hit snap, recoil, recovering; feet on the line |
| `art-b` | `xion-land-b2.png` | 128 | 2 | 12 | no | landing crouch, rising to the idle stance; feet on the line |
| `art-a` | `xion-attack-b2.png` | 128 | 6 | 35.25 | no | both shotguns fire forward: aim, shot, recoil, pump, recover, back to ready |
| `art-a` | `xion-shield-b2.png` | 128 | 6 | 12 | no | a guard: both shotguns crossed in front of the chest (below the chin), body braced, coat and scarf settling |
| `art-a` | `xion-victory-b2.png` | 192 | 6 | 8 | holds the last | a short win: the guns spun, ending with one resting on her shoulder and the other held low, a cool look, the scarf settling |
| `art-a` | `xion-defeat-b2.png` | 192 | 6 | 10 | holds the last | ART-69's six steps: recoil, stagger, knees buckle, falling, hitting the ground, lying still; the guns dropped beside her |

- The base sheet's single jump, fall and hurt drawings will be cut by the lead from these strips: jump frame 2, fall frame 1, hurt frame 1. Say if another frame suits better.
- The `attack` row is only the base sheet's fallback (her J plays the move sheet). Keep it short and clear.
- 192 cells: feet on y=152, the figure at the anchor's pixel scale (D34). The lying defeat body rests on y=152 with a 4-px margin (curl the knees if it is longer than the cell).

## Method (each row)
- One generation per motion, the frames in a row on green, no effects (D35). Make a second only if the first fails.
- `normalize.py --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, `--cell 128` (feet y=120) or `--cell 192` (feet y=152).
- **One factor per row, matched to the anchor head:** `head_scale.py --anchor art/bakeoff/xion/b/xion-idle-b2.png:0`, median 0.96–1.04.
  - If fewer than 2 frames score ≥ 0.6, compare 4× head crops instead and say so.
  - Never size curled, crouched or stretched poses by height.
- **The walk (`art-b`):** ART-59 step by step.
  - grey mannequin (`reports/codex-art-57/frey/make_walk_reference.py`) with Xion's 3-head proportions; the guns held steady like the idle
  - costume words from the anchor
  - frame 1 first, then frames 2, 4, 5, 6, 8 with frame 1 as Image 3
  - frames 3 and 7 are the passing poses (`walk_feet.py`)
  - `--ground-all`, then `walk_bob.py` once (±3 px)
  - Acceptance as ART-59: feet within ±6 px, no foot moving more than 25 px, a costume board against the idle. Up to 3 generations per frame.
- **The scarf:** in every frame, the tails keep the anchor's length (±10 %). They may flutter and swing, but not grow or vanish.

## Checks (each row)
- Costume exactly as the anchor on a 4× board (`reports/codex-art-97<a|b>/<row>.png`): coat, scarf, hair, gloves, boots, both guns.
- One face; hands and both guns intact; no effects.
- Border clear, 4-px margin, green spill 0, detail ≥ 90 % of the anchor's.
- Separate what you measured from what you judged by eye.

## Output
- In `art/bakeoff/xion/b/`, each strip with a `.json`: `{"note": "<Korean>", "fps": <fps>, "frames": <n>, "loop": <true|false>}`.
- `reports/codex-art-97<a|b>/`: the 4× boards, `metrics.json` (per row: factor, head scale, detail, border, margin, spill), the walk's feet and bob files (`art-b`), `prompts.txt`, `README.md` (Korean, UTF-8), `commit.ps1`.
  - `commit.ps1`: paths in a literal string array, only your files and this card, no `git add -f`, nothing under `art/raw/`, ending with `Co-Authored-By: Codex <noreply@openai.com>`. Do not run it.
- Raw generations go to `art/raw/xion-97<a|b>/` (git-ignored).

## Writable
- `art-b`: `art/bakeoff/xion/b/xion-{walk,jump,fall,hurt,land}-b2.*`, `art/raw/xion-97b/**`, `reports/codex-art-97b/**`
- `art-a`: `art/bakeoff/xion/b/xion-{attack,shield,victory,defeat}-b2.*`, `art/raw/xion-97a/**`, `reports/codex-art-97a/**`

Hard stop: 120 minutes. Deliver rows in the table's order and list the rest.
