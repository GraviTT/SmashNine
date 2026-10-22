# CODEX-ART-77 · Character motions, batch 3: Rio (male, female) (jump, fall, hurt, land, victory)

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 3.
- Batch 1 (CODEX-ART-72, merged `4161bd3`) did Frey and Luna. **Read `design/tasks/CODEX-ART-72.md` and `reports/codex-art-72/README.md` first**: the same rows, the same method, the same checks. Reuse its scripts (`reports/codex-art-72/process.py`, `face_check.py`, `verify.py`) by copying them into `reports/codex-art-77/`.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-motion/SmashNine`, branch `codex/art-77` (from the latest main).
- Running at the same time:
  - ART-75 (Yuki and Nova motions) in builder-frey
  - ART-74 and ART-76 (monsters) in builder-art and tester
  - ART-73 fix (portraits) in auditor
  - QA-21 (bug hunt, the only unit running Godot) in analyst
  - You share no files.
- **Candidates only.** Nothing under `smash-nine-prototype/` changes. The game already plays these rows when the files exist (SYS-06); the user picks in the motion viewer first.
- Rio's head was redrawn recently (ART-68 candidates, `reports/codex-art-68/`). Match the **current idle anchor**, not the ART-68 candidates.

## Rows
As CODEX-ART-72: `jump` 3@10 (holds the last), `fall` 2@8 (loop), `hurt` 3@12 (holds the last), `land` 2@12, all in 128 cells; `victory` 6@8 in 192 cells, feet on y=152, holds the last.

Victory poses, each without effects (the blade keeps its own glow as in the idle, nothing more):
- **Rio (male)**: a flourish of the blade at his side, ending with the sword planted point-down in front of him, both hands on the pommel, the cape settling.
- **Rio (female)**: a blade twirl, ending with the sword raised to the side, the ponytail swinging, a confident look.

## Forms (in this order)
- Rio (male): anchor `art/bakeoff/rio/rio_male-idle-v2.png`
- Rio (female): `art/bakeoff/rio/rio_female-idle-v2.png`

Output names use the next free version: `-jump-v2`, `-fall-v2`, `-hurt-v2`, `-land-v1`, `-victory-v1`. Check the folder before writing; never overwrite.

## Lessons from batch 1 (check them here)
- **Hurt must read as a hit**: the head snaps back and the torso leans away from the hit in the first frame, then recovers. Brave Luna's hurt changed only the face and read as idle.
- **Victory is one continuous movement**: no lowering and raising again (Frey's sword went down and up). The sword stays in the same hand (Luna's wand changed hands). The last frame is the held pose: make it the clearest.
- **Jump frames differ**: rising and apex must look different (Luna's F2 and F3 were nearly the same).
- **Face**: 0.96–1.04 is the target. If a whole row is off by the same amount, change that row's single factor. If one frame is off, retry that frame only, with the row's other frames as references.
- **Delivery**: a row within 0.95–1.06 on every measured frame is delivered as a candidate; if it is outside 0.96–1.04, its `note` says the measured ratio, so the user can judge. Hold a row only beyond that, or for a visible error.
- **The cape and the long sword** make wide frames: keep the 4 px margin; the sword may not be cut by the cell edge.

## Checks and output
As CODEX-ART-72 (settings, face match on 4× crops plus `head_scale.py`, costume exactly as the idle, border clear, 4 px margin, spill 0, detail ≥ 79, a 4× board per row next to the anchor `reports/codex-art-77/<stem>-<row>.png`, up to 3 generations per row).

- `art/bakeoff/rio/<stem>-<row>-v<n>.png` + `.json` (`note` in Korean, `frames`, `fps`, `cell`, `feet`, `factor`).
- `reports/codex-art-77/README.md` (Korean), `prompts.txt`.
- `commit.ps1`: only your files, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/rio/**` (new files only), `art/raw/motions-77/**` (git-ignored), `reports/codex-art-77/**`.

Hard stop: 150 minutes. Deliver forms in order and list the rest.
