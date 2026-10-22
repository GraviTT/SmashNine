# CODEX-ART-71 · Monsters to the new art level, batch 1 of 3 (six monsters)

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 2.
- The 18 monsters still use the old 96-px sheets: 4 rows (idle 4, walk 6, attack 4, hurt 1). The ten behaviours of D41 (`scripts/monsters/MonsterArchetypes.gd`) all play the same 4-frame attack, and the wind-up has no drawing.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/art-71` (from the latest main).
- Running at the same time:
  - ART-72 (character motions) in builder-frey
  - AUD-01a (sounds) in auditor
  - You share no files.
- Read first:
  - `scripts/RealmMonster.gd` (rows, cell size, feet at 3/4 of the cell, elites ×1.35)
  - `scripts/monsters/MonsterArchetypes.gd` (skin → behaviour, wind-up seconds)
  - `design/DECISIONS.md` D41
  - `assets/art/monsters/README.md`
  - the current sheets
  - the D35 method: `design/tasks/CODEX-ART-61.md`, `reports/codex-art-61b/README.md`, `tools/sprite_pipeline/README.md`
- **Candidates only** for the art: nothing under `smash-nine-prototype/` changes. The user picks in the motion viewer. Game wiring comes in a later card.

## The new monster sheet
96-px cells, as now: monsters stay 96 screen px and their hit boxes do not change. Feet on y=72 (3/4 of the cell) for walkers. Flyers hover with the body centre where the current sheet has it. 6 columns, 6 rows:

| Row | Frames | fps | Loop | Shows |
|---|---|---|---|---|
| `idle` | 6 | 6 | yes | breathing, or hovering for flyers |
| `walk` | 6 | 10 | yes | walking/running, or flapping for flyers |
| `windup` (new) | 4 | played over the behaviour's wind-up (0.32–0.9 s), holds the last | no | the telegraph of the attack. It must read at 1× within 0.3 s: a clear pose change, not a colour change |
| `attack` | 6 | 12 | yes for sustained actions (charge, swoop); once otherwise | the action itself |
| `hurt` | 2 | 8 | no | flinch |
| `defeat` (new) | 4 | 8 | no | collapse or dissolve; the last frame lies on the ground or is nearly empty |

## Batch 1 (in this order)

| Monster | Behaviour | Attack row |
|---|---|---|
| `mossling` | bite | a quick lunge and bite |
| `ember_imp` | bolt | casts from the hand. The fireball is separate art: draw only the hand's glow |
| `asgard_aegis_ram` | charge | head down, horns forward, a running rush (loop) |
| `asgard_runic_raven` | swoop | a dive with the wings swept back (loop) |
| `alfheim_moon_stag` | leap | crouch, airborne arc, landing |
| `alfheim_moon_moth` | blink | shrinks into sparkles and re-forms (drawn, alpha stays 0/1) |

- **Identity**: keep each monster recognizable: its colours, silhouette and features from the current sheet.
- **Detail**: bring it up to the detail density of the new fighters (reference for density only, not style: `art/bakeoff/frey/frey-idle-v2.png`).
- **Order of work**: an anchor `idle` first (up to 3 variants; choose one and say why). Then the other rows, with the anchor as Image 1.
- **Size**: one factor per row, matched to the anchor's body (a stable part such as head or torso).

## Checks (each monster)
- Border clear, 3 px margin, spill 0, detail measured as in ART-61.
- One creature per frame, no text, no effects except the imp's hand glow.
- Feet on the line for walkers.
- A 1× and 4× board next to the current sheet: `reports/codex-art-71/<id>.png`.
- Up to 3 generations per row. A row that still fails: report the best attempt and why.

## Output
- Per row: `art/bakeoff/monsters/<id>-<row>-v1.png` + `.json` with:
  - `note` in Korean
  - `frames`, `fps`, `loop`, `cell: 96`, `feet: 72`, `factor`
- The assembled 6-row sheet: `art/bakeoff/monsters/<id>_sheet-v1.png` (576×576), for the later wiring.
- **Viewer**: change `tools/motion_viewer/build.mjs` so monster candidates show per row, the new rows (`windup`, `defeat`) included, the way character candidates do. Run `node tools/motion_viewer/build.mjs` to check (`dist` is git-ignored).
- `reports/codex-art-71/README.md` (Korean), `prompts.txt`.
- `commit.ps1`:
  - no `git add -f`
  - nothing under `art/raw/`
  - no `__pycache__`

## Writable
`art/bakeoff/monsters/**` (new files), `art/raw/monsters-71/**` (git-ignored), `reports/codex-art-71/**`, `tools/motion_viewer/build.mjs`.

Hard stop: 150 minutes. Deliver monsters in the table order and list the rest.
