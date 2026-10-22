# CODEX-ART-75 · Character motions, batch 2: Yuki, Nova (male, female) (jump, fall, hurt, land, victory)

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 3.
- Batch 1 (CODEX-ART-72, merged `4161bd3`) did Frey and Luna. **Read `design/tasks/CODEX-ART-72.md` and `reports/codex-art-72/README.md` first**: the same rows, the same method, the same checks. Reuse its scripts (`reports/codex-art-72/process.py`, `face_check.py`, `verify.py`) by copying them into `reports/codex-art-75/`.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine`, branch `codex/art-75` (from the latest main).
- Running at the same time:
  - ART-77 (Rio motions) in builder-motion
  - ART-74 and ART-76 (monsters) in builder-art and tester
  - ART-73 fix (portraits) in auditor
  - QA-21 (bug hunt, the only unit running Godot) in analyst
  - You share no files.
- **Candidates only.** Nothing under `smash-nine-prototype/` changes. The game already plays these rows when the files exist (SYS-06); the user picks in the motion viewer first.

## Rows
As CODEX-ART-72: `jump` 3@10 (holds the last), `fall` 2@8 (loop), `hurt` 3@12 (holds the last), `land` 2@12, all in 128 cells; `victory` 6@8 in 192 cells, feet on y=152, holds the last.

Victory poses, each without effects:
- **Yuki**: flicks a talisman up between two fingers, then opens her fan in front of her chin with a calm smile.
- **Nova (male)**: rolls his shoulder and punches his open palm, ending with a fist forward and a grin.
- **Nova (female)**: a quick jab, jab, then a fist raised high, ending in a ready stance with a wink.

## Forms (in this order)
- Yuki: anchor `art/bakeoff/yuki/yuki-idle-v2.png`
- Nova (male): `art/bakeoff/nova/nova_male-idle-v2.png`
- Nova (female): `art/bakeoff/nova/nova_female-idle-v2.png`

Output names use the next free version: `-jump-v2`, `-fall-v2`, `-hurt-v2` (Nova female `-hurt-v3`: v2 is another candidate), `-land-v1`, `-victory-v1`. Check the folder before writing; never overwrite.

## Lessons from batch 1 (check them here)
- **Hurt must read as a hit**: the head snaps back and the torso leans away from the hit in the first frame, then recovers. Brave Luna's hurt changed only the face and read as idle.
- **Victory is one continuous movement**: no lowering and raising again (Frey's sword went down and up). The weapon or prop stays in the same hand (Luna's wand changed hands). The last frame is the held pose: make it the clearest.
- **Jump frames differ**: rising and apex must look different (Luna's F2 and F3 were nearly the same).
- **Face**: 0.96–1.04 is the target. If a whole row is off by the same amount, change that row's single factor. If one frame is off, retry that frame only, with the row's other frames as references.
- **Delivery**: a row within 0.95–1.06 on every measured frame is delivered as a candidate; if it is outside 0.96–1.04, its `note` says the measured ratio, so the user can judge. Hold a row only beyond that, or for a visible error.

## Checks and output
As CODEX-ART-72 (settings, face match on 4× crops plus `head_scale.py`, costume exactly as the idle, border clear, 4 px margin, spill 0, detail ≥ 79, a 4× board per row next to the anchor `reports/codex-art-75/<stem>-<row>.png`, up to 3 generations per row).

- `art/bakeoff/{yuki,nova}/<stem>-<row>-v<n>.png` + `.json` (`note` in Korean, `frames`, `fps`, `cell`, `feet`, `factor`).
- `reports/codex-art-75/README.md` (Korean), `prompts.txt`.
- `commit.ps1`: only your files, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/yuki/**`, `art/bakeoff/nova/**` (new files only), `art/raw/motions-75/**` (git-ignored), `reports/codex-art-75/**`.

Hard stop: 150 minutes. Deliver forms in order and list the rest.
