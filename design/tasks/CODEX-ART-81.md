# CODEX-ART-81 · Technical audit of every art candidate (measure only)

- Request: 점검 세션 "게임 상태 점검 및 정리", 사용자 요청 2026-10-25 — after the checkpoint `checkpoint-2026-10-25` (`c51a417f`), repair and extend the sprites without needing the user. This card finds what to repair.
- Unit: Analyst (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-a/SmashNine`, branch `codex/art-81` (from the checkpoint).
- Running at the same time: ART-82 (character motion repairs) in `art-b`. You share no files. Do not run Godot.
- **Measure only.** Do not change any art. Nothing under `smash-nine-prototype/`, `art/` or `tools/` changes.

## What to audit
Every candidate that is not adopted (its json has no `adopted` field):
- fighter rows `art/bakeoff/{frey,luna,yuki,nova,rio}/<stem>-<row>-v<n>.png` (53; 128-px cells, feet y=120; `victory` 192-px cells, feet y=152; strips are padded to 6 columns, `frames` in the json says how many are used)
- monster rows `art/bakeoff/monsters/<id>-<row>-v1.png` (108; 96-px cells, feet y=72 for walkers) and the assembled sheets `<id>_sheet-v1.png` (18; 576×576)
- monster projectiles `art/bakeoff/monsters/*-projectile-v1.png` and `slam_shockwave-v1.png` (8; 48-px cells, the shockwave 64×48 with its floor at y=44)
- dialogue faces `art/bakeoff/<folder>/<stem>_face-{happy,angry,hurt,shadow}-v1.png` (32; 256×256)

The reports that made them: `reports/codex-art-68`…`codex-art-80`, the fix-1 folders, `reports/codex-art-79`.

## Checks (each file)
1. **Format**: size = columns × cell; RGBA; the json fields (`frames`, `fps`, `cell`, `feet`, `loop`) match the strip (count the non-empty cells).
2. **Fixed-width slicing**: every frame's figure sits inside its own cell with the margin (fighters 4 px, monsters and projectiles 3 px); no figure part crosses into the next cell or is cut at a cell edge (look at connected components across cell borders).
3. **Feet**: on grounded rows the lowest weight-bearing pixel is on the feet line (±1). Airborne frames (jump, fall, leap, swoop, flyers) are reported, not failed.
4. **Alpha**: semi-transparent pixels, light or dark halos at the edge, checkerboard or green-screen leftovers.
5. **Repeated frames**: consecutive frames that are the same or nearly the same (say the measure and the threshold).
6. **Size between rows**: each monster row against its idle (bounding box and one stable part); each fighter row's head against its idle anchor (`tools/sprite_pipeline/head_scale.py` and the ART-72 `face_check.py` method).
7. **Palette drift**: the candidate's main colours against the current game sheet of the same character or monster (`smash-nine-prototype/assets/art/…`); flag a drift like the vine hound's green → yellow (ART-74).
8. **Assembled sheets**: each row of `<id>_sheet-v1.png` equals the per-row candidate file (pixel compare); a stale row is a defect.
9. **Faces**: expressions keep the neutral face outside the mask (count changed pixels); shadow faces line up with the neutral (offset).

## Output
- `reports/codex-art-81/README.md` (Korean):
  - a defect table, worst first (상/중/하): file, check, measured value, threshold, the likely fix (rebuild with a factor, frame retry, palette remap, reassemble, …)
  - per kind, how many files passed every check
  - what you could not measure and why
- `reports/codex-art-81/audit.json` (every file, every check, every number) and the script that makes it (`reports/codex-art-81/audit.py`), so the lead can rerun it on new versions
- boards of the 20 worst defects at 4×
- `reports/codex-art-81/commit.ps1`: only your files (this card and its prompt included), no `git add -f`, no `__pycache__`, no `run.log`

## Writable
`reports/codex-art-81/**`, `design/tasks/CODEX-ART-81.md`, `design/tasks/CODEX-ART-81.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 120 minutes.
