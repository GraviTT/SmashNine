# CODEX-ART-72 · Character motions, batch 1: Frey, Luna, Brave Luna (jump, fall, hurt, land, victory)

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 3.
- Jump, fall and hurt are one drawing each, so the fighters look stiff in the air and when hit. There is no landing and no victory pose (the results screen and the story ending need one).
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine`, branch `codex/art-72` (from the latest main). Your raws from earlier Frey/Luna work are in this clone under `art/raw/`.
- Running at the same time:
  - ART-71 (monsters) in builder-art
  - AUD-01a (sounds) in auditor
  - You share no files.
- Read first:
  - `design/tasks/CODEX-ART-61.md` and `reports/codex-art-61b/README.md` (the method)
  - `tools/sprite_pipeline/README.md`
  - `design/DECISIONS.md` D32–D37
  - the current single drawings and their json: `art/bakeoff/frey/frey-jump-v1.json` says one shared factor 0.205, lifted 11 px off the line
- **Candidates only.** Nothing under `smash-nine-prototype/` changes. The user picks in the motion viewer. The game wiring (multi-frame jump/fall/hurt, landing, victory on the results screen and in the story ending) comes in a later card.

## The rows (per form)

| Row | Cell | Frames | fps | Loop | Shows |
|---|---|---|---|---|---|
| `jump` | 128 | 3 | 10 | no, holds the last | take-off spring, rising, apex. Lifted off the line like the current drawing |
| `fall` | 128 | 2 | 8 | yes | falling, hair and cape flutter between the two |
| `hurt` | 128 | 3 | 12 | no, holds the last | hit snap, recoil, recovering. Feet on the line |
| `land` (new) | 128 | 2 | 12 | no | landing crouch, rising back to the idle stance. Feet on the line |
| `victory` (new) | 192 | 6 | 8 | no, holds the last | a short win pose of the character's own (feet on y=152) |

Victory poses, each drawn without effects:
- **Frey**: sword raised high, shield forward, cape swept, a confident smile.
- **Luna**: a wand twirl ending in a star pose and a wink.
- **Brave Luna**: a fist pump ending in a fighting stance with a grin.

## Forms (in this order)
- Frey: anchor `art/bakeoff/frey/frey-idle-v2.png`
- Luna: `art/bakeoff/luna/luna-idle-v3.png`
- Brave Luna: `art/bakeoff/luna/luna_brave-idle-v4.png`

Output names use the next free version: `<stem>-jump-v2` (Luna `-v3`), `<stem>-fall-v2` (Luna and Brave `-v3`), `<stem>-hurt-v2`, `<stem>-land-v1`, `<stem>-victory-v1`. Check the folder before writing; never overwrite.

## Checks (each row)
- Settings as ART-61: `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, one factor per row matched to the anchor.
- **Face match** 0.96–1.04 on every frame where the face is upright. Measure on 4× crops: eye-to-eye distance, and face width at the eyes, hair excluded. Also run `head_scale.py`; if the two disagree, the face decides.
- Costume exactly as the idle, one face, hands and weapons intact, no effects, no text.
- Border clear, 4 px margin, spill 0, detail ≥ 79.
- A 4× board per row next to the anchor: `reports/codex-art-72/<stem>-<row>.png`.
- Up to 3 generations per row. A row that still fails: report the best attempt and why.

## Writable
- `art/bakeoff/frey/**`, `art/bakeoff/luna/**`: new files only
- `art/raw/motions-72/**` (git-ignored)
- `reports/codex-art-72/**`: README in Korean, `prompts.txt`, and `commit.ps1`, which must:
  - not use `git add -f`
  - add nothing under `art/raw/`
  - add no `__pycache__`

Hard stop: 150 minutes. Deliver forms in order and list the rest.
