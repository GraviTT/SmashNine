# CODEX-ART-78 · Character motions, batch 1 retry: the seven rows ART-72 held

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 3.
- CODEX-ART-72 (merged `4161bd3`) delivered 8 of 15 rows and held 7. The lead reviewed the boards. **Read `design/tasks/CODEX-ART-72.md` and `reports/codex-art-72/README.md` first.** Reuse its scripts by copying them into `reports/codex-art-78/`. The held best attempts are in `reports/codex-art-72/best/<form>/<row>/`.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-extra/SmashNine`, branch `codex/art-78` (from the latest main).
- Running at the same time:
  - ART-75 (Yuki and Nova motions) and ART-77 (Rio motions) in builder-frey and builder-motion: the same lessons apply there
  - ART-74 and ART-76 (monsters), ART-73 fix (portraits)
  - SYS-05 (sound wiring, the only unit running Godot) in analyst
  - You share no files.
- **Candidates only.** Nothing under `smash-nine-prototype/` changes.

## The lead's call per row

| Form | Row | ART-72 result | This card |
|---|---|---|---|
| Frey | `jump` | face .992–1.045, looks right | **deliver the best attempt** as a candidate; the `note` gives the ratio |
| Brave Luna | `fall` | face .955–.985 | **deliver the best attempt** as a candidate; the `note` gives the ratio |
| Frey | `victory` | the sword goes up, down, then up again | redo: one rising movement, sword raised at the end, shield forward, cape swept, a smile |
| Luna | `victory` | the wand changes hands | redo: the wand stays in the same hand through the twirl; star pose and wink at the end |
| Brave Luna | `victory` | the fist pump is small and reads weakly at 1× | redo: the fist goes high above the head (F2–F3), then lands in a fighting stance with a grin |
| Brave Luna | `hurt` | only the face changes; reads as idle | redo: the head snaps back and the torso leans away in F1, a recoil in F2, recovering in F3 |
| Brave Luna | `jump` | face width up to 1.071 | redo, or change the row's single factor if the whole row is off by the same amount |

## Rules (the same as ART-75 and ART-77)
- **Face**: 0.96–1.04 is the target. If a whole row is off by the same amount, change that row's single factor. If one frame is off, retry that frame only, with the row's other frames as references.
- **Delivery**: a row within 0.95–1.06 on every measured frame is delivered as a candidate; if it is outside 0.96–1.04, its `note` says the measured ratio. Hold a row only beyond that, or for a visible error.
- **Victory** (192 cells, feet on y=152, holds the last): one continuous movement; the last frame is the clearest pose.
- Settings, checks and boards as CODEX-ART-72 (4× board per row next to the anchor: `reports/codex-art-78/<stem>-<row>.png`), up to 3 generations per row.

## Output
- Names: the next free version in `art/bakeoff/frey/` and `art/bakeoff/luna/` (Frey `jump-v2`, `victory-v1`; Luna `victory-v1`; Brave `jump-v2`, `fall-v3`, `hurt-v2`, `victory-v1`). Check the folder first; never overwrite.
- `.json` per row (`note` in Korean, `frames`, `fps`, `cell`, `feet`, `factor`).
- `reports/codex-art-78/README.md` (Korean), `prompts.txt`.
- `commit.ps1`: only your files, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/frey/**`, `art/bakeoff/luna/**` (new files only), `art/raw/motions-78/**` (git-ignored), `reports/codex-art-78/**`.

Hard stop: 150 minutes. Rows in the table order.
