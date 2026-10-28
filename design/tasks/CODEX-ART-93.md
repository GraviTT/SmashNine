# CODEX-ART-93 · Match the new monster windup/defeat rows to the kept pictures' size; fix the oracle's tentacles

- Request (사용자 결정, 2026-10-29, 점검 세션 전달): "몬스터 준비·쓰러짐 새 줄을 지금 그림 크기에 맞추고(달나방·예언자·방패 산양·룬 까마귀·서리 올빼미·뿌리 수호자·불씨 임프, 예언자 촉수 바닥선도 확인) 테스트한 뒤 8061에서 다시 보여줘." Rule from the same message: one factor per monster = the kept idle height ÷ the new candidate idle height; build from the raw generation when it exists (enlarging the 96-px row blurs it); a row that would leave the cell takes the largest factor that fits, recorded; the other monsters only if they differ by more than ±8%.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-b/SmashNine`, branch `codex/art-93` (from the apply branch `6031b018`). The lead reassembles the game sheets, runs the tests and the web build.
- Nothing else runs now. Do not run Godot. Never edit anything under `smash-nine-prototype/`.

## Background
The applied six-row sheets `smash-nine-prototype/assets/art/monsters/<id>_sheet.png` (576×576, 96-px cells, feet y=72) keep today's idle / walk / attack / hurt drawings (rows 1, 2, 4, 5) and add the picked windup and defeat rows (rows 3 and 6). Those two rows were drawn at the new candidates' scale, which is smaller for these monsters (measured by the lead: average drawn height of the kept idle row ÷ the candidate idle row):

| Monster | kept idle h | candidate idle h (file) | target factor k | picked windup | picked defeat |
|---|---:|---:|---:|---|---|
| alfheim_moon_moth | 60.0 | 48.3 (idle-v1) | 1.241 | windup-v2 | defeat-v2 |
| yggdrasil_root_oracle | 66.0 | 57.0 (idle-v1) | 1.158 | windup-v2 | defeat-v1 |
| asgard_aegis_ram | 51.5 | 45.0 (idle-v2) | 1.144 | windup-v2 | defeat-v1 |
| asgard_runic_raven | 50.8 | 44.7 (idle-v1) | 1.136 | windup-v2 | defeat-v1 |
| niflheim_frost_owl | 64.5 | 57.7 (idle-v1) | 1.118 | windup-v1 | defeat-v2 |
| ember_imp | 69.0 | 62.7 (idle-v2) | 1.101 | windup-v1 | defeat-v1 |
| yggdrasil_root_guardian | 67.8 | 61.8 (idle-v1) | 1.096 | windup-v1 | defeat-v2 |
| jotunheim_storm_wisp | 61.5 | 56.2 (idle-v1) | 1.095 | windup-v1 | defeat-v1 |

The other ten are within ±8% (golem 0.924 is the closest) and stay as they are. Re-measure k yourself from the files and report if you get a different value.

## Work
1. For each of the 16 rows above (`art/bakeoff/monsters/<id>-<row>-vN.png`, 4 frames on a 6-cell canvas): find the raw generation it was normalized from (`art/raw/monsters-71`, `-74`, `-76`, `-83`, `-87`, `art/raw/art-90`; the cards and reports `reports/codex-art-71`, `-74`, `-76`, `-83`, `-88`, `-90` say which raw and which settings; the row's json has its `factor`). Re-normalize it with the same method and settings at `factor × k`: same background removal, despill, LANCZOS + unsharp, frames in the same order and relative placement, scaled about the row's feet point (x centre, y=72) so it stands where it stood. One factor for all frames of a row.
2. Cell limits: every frame inside its 96-px cell with a 4-px margin, nothing touching or crossing a cell edge, no frame cut. If `factor × k` does not fit, use the largest factor that fits for that row and record it. A row must never get smaller than now.
3. No raw found for a row: enlarge the current row by the same factor with LANCZOS + unsharp 60 (the pipeline's settings) and say so.
4. Oracle windup: the lower tentacles reach rows 76–87, below the ground line y=72. After scaling, keep the head and body where the oracle's kept rows have them (compare with the kept idle and attack in its game sheet), and shorten only the lower tentacles so the lowest drawn pixel is on row 72: squash the tentacle part below the head vertically, or redraw the tips curling (an image edit is allowed). Keep the look and colours.
5. Same look as before: no colour, palette or detail changes beyond the scaling; no effects added.

## Output
- New versions `art/bakeoff/monsters/<id>-<row>-v<next>.png` (4 frames on the same 6-cell canvas, 576×96) + `.json`: `frames`, `fps`, `cell`, `feet`, `loop` copied from the row it replaces, `replaces` (that file), `factor` (the new normalization factor), `size_k` (target), `size_used` (applied), `from_raw` (true/false + the raw path), `note` (Korean: what changed, height ratio of the row vs the kept idle before → after). Never overwrite an existing file.
- A 4× board per monster `reports/codex-art-93/<id>.png`: the kept idle F1 from the game sheet, then the old and the new windup and defeat rows, on one ground line.
- `reports/codex-art-93/README.md` (Korean): a table per row (k, factor used, limited by width / height / none, raw or enlarged, height ratio vs the kept idle before → after, lowest drawn row), and the oracle fix.
- `reports/codex-art-93/commit.ps1` + `commit-paths.txt`: stage with `git add --pathspec-from-file` only your files plus this card and its prompt; no `git add -f`, nothing under `art/raw/`, no attempt dumps, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/monsters/<id>-{windup,defeat}-v<next>.*` for the eight monsters (new files only), `art/raw/monsters-93/**` (git-ignored), `reports/codex-art-93/**`, `design/tasks/CODEX-ART-93.md`, `design/tasks/CODEX-ART-93.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 90 minutes.
