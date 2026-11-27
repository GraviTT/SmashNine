# CODEX-SKM-09 · Rio: redraw the two rows CODEX-SKM-08 held — female sword throw, male pierce (candidates)

- Request: the user (2026-11-27, "지금 시작" for Rio's kit v3 art). The 총괄 session gave this unit the free Codex slot after 12:00. CODEX-SKM-08 delivered 8 of 10 rows (merged `ffcd1166`) and held two. **Candidates only**: the lead reviews them, the user picks in the pick cup (D49), then the lead puts the picks in the game after the web budget decision (#223).
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-a/SmashNine`, branch `codex/skm-09`. One other Codex unit runs on this PC (the image session's `art-b`); you share no files.

## The two rows (everything else as CODEX-SKM-08: read `design/tasks/CODEX-SKM-08.md` and `reports/codex-skm-08/README.md`)

| Body | Row | fps | Why SKM-08 held it | What must change |
| --- | --- | ---: | --- | --- |
| female | `sword_throw` | 20 | Frame 2 reads as three hands. | **Exactly two hands in every frame:** the right hand holds her sword low, the left hand is drawn back past the ear and then throws. Follow the delivered male row `art/bakeoff/rio/rio_male-sword_throw-v1.png` pose for pose, in her look (`art/bakeoff/rio/rio_female-idle-v2.png`: compact side ponytail, narrower shoulders). |
| male | `pierce` | 20 | At the anchor's face scale the forward-thrust sword leaves the 192-px cell. | **Body and sword inside the cell with the 4 px margin, at the anchor's face scale.** Keep the lunge lower and the sword angled down-forward, or the arm a little bent, instead of fully straight out. The delivered female row `art/bakeoff/rio/rio_female-pierce-v1.png` shows a pose that fits. Look: `art/bakeoff/rio/rio_male-idle-v2.png`. |

- Method as SKM-08: one generation per row (six poses in one line on `#00ff00`), then `tools/sprite_pipeline` with `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`. 192-px cells, feet on y=152, body centre x=96, face 0.96–1.04 of that body's anchor. Up to 2 generations per row. Copy `reports/codex-skm-08/*.py` into `reports/codex-skm-09/` and reuse them.
- **Checks:** as SKM-08, plus the two fixes above: count the hands in every frame of the female throw; measure the sword's farthest pixel against the cell edge in every frame of the male pierce.

## Output
- `art/bakeoff/rio/rio_female-sword_throw-v1.png` and `art/bakeoff/rio/rio_male-pierce-v1.png`, each with its `.json` (as SKM-08: `note` in Korean with the face ratio and the fix, `for`, `frames` 6, `fps`, `cell` 192, `feet` [96,152], `loop` false, `factor`).
- Boards `reports/codex-skm-09/rio_<body>-<row>.png` (4×, next to the anchor and next to the delivered row of the other body).
- `reports/codex-skm-09/README.md` (Korean, short; measured apart from guessed) and `reports/codex-skm-09/commit.ps1` (stages only the delivered files, the boards, the README, the scripts and this card; no attempt folders, nothing under `art/raw/`; no committed text line ends with spaces, and no text file ends with a blank line).
- Raw generations in `art/raw/skm-09/` (git-ignored); prompts in `reports/codex-skm-09/prompts.txt`.

## Writable
- **New files only:** `art/bakeoff/rio/rio_female-sword_throw-v*.*`, `art/bakeoff/rio/rio_male-pierce-v*.*`, `art/raw/skm-09/**`, `reports/codex-skm-09/**`.
- Nothing under `smash-nine-prototype/` changes.
- **Hard stop: 60 minutes.** Check the clock before each generation and after every image_gen call.
