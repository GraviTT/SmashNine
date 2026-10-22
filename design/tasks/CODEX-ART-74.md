# CODEX-ART-74 · Monsters to the new art level, batch 2 of 3 (six monsters)

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 2.
- Batch 1 (CODEX-ART-71, merged `455d49e`) made six monsters. **Read `reports/codex-art-71/README.md` first** and reuse its method, its scripts (`reports/codex-art-71/process.py`, `verify.py`) and its board layout.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/art-74` (from the latest main).
- Running at the same time:
  - ART-76 (monsters batch 3) in the tester clone
  - ART-75 (character motions) in builder-frey
  - QA-21 (bug hunt, the only unit running Godot) in analyst
  - You share no files.
- Read first: everything CODEX-ART-71 lists, and its report.
- **Candidates only**: nothing under `smash-nine-prototype/` changes. The user picks in the motion viewer.
- The viewer already shows monster candidates by file name (ART-71). **Do not change `tools/motion_viewer/`.** Run `node tools/motion_viewer/build.mjs` only to check that your rows appear.

## The sheet
The same as CODEX-ART-71: 96-px cells, feet on y=72 for walkers, flyers centred where the current sheet has them, 6 columns × 6 rows (`idle` 6, `walk` 6, `windup` 4, `attack` 6, `hurt` 2, `defeat` 4).

## Batch 2 (in this order)

| Monster | Behaviour (code) | `windup` | `attack` row |
|---|---|---|---|
| `midgard_rooftop_slinger` | lob, 0.6 s | winds the sling back | the throw, follow-through, recover (once). The stone is separate art: no projectile |
| `svartalfheim_gear_beetle` | shell, 0.65 s: rushes forward, front hits halved | pulls head and legs into the shell | a rolling or sliding shell rush (loop: the code loops `charge`/`swoop` only, but the rush lasts 0.65 s; make it loop cleanly) |
| `svartalfheim_cog_drone` | swoop, but **drops a bomb** straight down and does not dive | rises a little, a hatch or claw opens under it | the release: hatch open, recoil up, hatch closes. The bomb is separate art. The code loops swoop rows: it must also loop cleanly |
| `vanaheim_vine_hound` | leap, 0.55 s | low crouch, vines tense | take-off, airborne arc, landing (once) |
| `vanaheim_seed_sprite` | lob, 0.6 s: three seeds in a fan | gathers in, pods swell | a burst that sends the seeds (seeds are separate art; no projectiles) |
| `jotunheim_rune_golem` | slam, 0.9 s: shockwaves both sides | raises both fists overhead, runes brighten (pose first, glow second) | the smash down, the impact frame, the recovery. The shockwaves are separate art: no dust or waves |

## Lessons from batch 1 (measured there; check them here)
- **Detail**: imp and ram stayed at 72–76 against Frey 96 (ART-61 measure). Aim for **≥ 85** on every row; report any row below.
- **Walk**: the left/right alternation must read at 1×. Show the leg positions per frame on the 4× board.
- **Feet**: on walking, idle and grounded attack frames every foot that carries weight touches y=72 (±1). Only airborne frames (leap) lift off. Ram charge frames floated at y=63–66; do not repeat it.
- **Reach**: a lunge or throw moves the body or arm forward visibly (≥ 8 px at 1×).
- **Size**: one factor per row, matched to a stable body part of the anchor. Report each row's measured size against the anchor.

## Checks and output
As CODEX-ART-71 (border clear, 3 px margin, spill 0, one creature per frame, no text, no effects; a 1× and 4× board next to the current sheet: `reports/codex-art-74/<id>.png`; up to 3 generations per row).

- Per row: `art/bakeoff/monsters/<id>-<row>-v1.png` + `.json` (`note` in Korean, `frames`, `fps`, `loop`, `cell: 96`, `feet: 72`, `factor`).
- The assembled sheet: `art/bakeoff/monsters/<id>_sheet-v1.png` (576×576).
- `reports/codex-art-74/README.md` (Korean): a table per monster and row, the lesson checks above, and what is still weak (measured vs judged). `prompts.txt`.
- `commit.ps1`: only your files, no `git add -f`, nothing under `art/raw/`, no `__pycache__`.

## Writable
`art/bakeoff/monsters/<batch-2 ids>-*` and `<batch-2 ids>_sheet-v1.png` (new files), `art/raw/monsters-74/**` (git-ignored), `reports/codex-art-74/**`.

Hard stop: 150 minutes. Deliver monsters in the table order and list the rest.
