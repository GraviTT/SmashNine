# CODEX-ART-92 · New general motions for the 8 fighter forms (dodge roll, taunt, stun, crouch)

- Request (사용자, 2026-10-28 14:30, 점검 세션 전달): "Codex에게 스프라이트를 더 만들게 하여 아직 게임에 없는 더 많은 행동 패턴 동작을 생성해볼것. 이후 사용 할수도 있으니 미리 만들어두는 것이고, 오늘 오후 4시에 종료."
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-b/SmashNine`, branch `codex/art-92` (from `after-cp/art-sprite` `51b6ada6`).
- Running at the same time: ART-91 in `art-a` (inventory, then **monster** motions). You share no files. The character-skill session makes skill motions; do not make skill moves. Do not run Godot.
- New files are **candidates** for later; nothing is wired into the game.

## Time — hard limits
- Check the clock (`Get-Date`) before each row. **Do not start a new row after 15:45** local time. Finish the row in hand, then write the report; be done by **15:55**. The process is killed at 15:57; anything not delivered by then is lost.
- Deliver row by row: when a row passes, write its files and add it to the progress list at once (below). Never batch deliveries to the end.

## Read first (briefly — about 5 minutes)
`design/tasks/CODEX-ART-72.md` (the motion rules), `reports/codex-art-89/README.md` and its scripts (`process.py`, `face_check.py`, `run_variant_v2.py`, `package_results.py`, `verify_delivery.py`): the proven method. Reuse them by copying into `reports/codex-art-92/`; do not edit them in place.

## Rows — in this order, motion by motion, all 8 forms each
Forms: `frey`, `luna`, `luna_brave`, `nova_male`, `nova_female`, `rio_male`, `rio_female`, `yuki` (folders frey, luna, luna, nova, nova, rio, rio, yuki).

| Order | Row name | What it shows | Cell / feet | Frames · fps · loop |
|---|---|---|---|---|
| 1 | `dodge_roll` | a quick forward roll on the ground: crouch → tuck and roll → come up ready, body compact, weapon held close | 128 / 120 | 6 · 14 · false |
| 2 | `taunt` | a short character-specific taunt (a confident gesture with their own weapon or prop), back to ready | 192 / 152 | 6 · 8 · false |
| 3 | `stun` | dizzy: head and upper body sway, unsteady stance, eyes half closed; body only (no stars or effects) | 128 / 120 | 6 · 8 · true |
| 4 | `crouch` | drop into a low crouch and hold it (last frames a small breathing hold) | 128 / 120 | 6 · 12 · false |

If time is left after row 4, continue with `run_start` (lean forward, push off; 128/120, 6 · 14 · false) for all forms.

## Method (as ART-89)
- One generation draws the **whole row** (all 6 frames in one image). Image 1 = that form's idle anchor (as ART-89 built it), Image 2 = a related existing row of the same form for style and costume (dodge roll: `tumble` or `jump`; taunt: `victory`; stun: `hurt`; crouch: `land`; run_start: `walk`). Up to 2 generations per row; keep the better.
- Normalize the row with **one** factor matched to the idle anchor (ART-72/89 settings: LANCZOS + unsharp 60 + despill auto, no palette map). No per-frame rescaling, no head pasting, no feature drawing in code.
- Do not draw effects into the body frames (no dust, stars, trails, flashes, auras).

## Checks (deliver only if all pass)
Face 0.96–1.04 of the idle on every measurable frame (the `face_check.py` method; frames where the face is turned away, hidden or eyes closed are reported, not failed); costume exactly as the idle; border clear; 4 px margin inside every cell; spill 0; detail ≥ 79; feet on the line where grounded; **fixed-width slicing**: the strip is exactly 6 × cell wide and no pixel of a frame touches or crosses its cell edges; 6 distinct frames (no repeated frame).

## Output per delivered row
- `art/bakeoff/<folder>/<stem>-<row>-v1.png` (6 frames in one row) + `.json`: `note` (Korean: what the motion shows, per-frame face ratios, anything weak), `frames`, `fps`, `cell`, `feet`, `loop`, `new_row: true`.
- A 4× board `reports/codex-art-92/<stem>-<row>.png`: the idle anchor, then the 6 frames.
- Append one line to `reports/codex-art-92/progress.md`: time · stem · row · file · frames · checks (pass/fail with numbers) · note. Append the row's paths (png, json, board) to `reports/codex-art-92/commit-paths.txt`.
- A failed row: no file in `art/bakeoff`; log it in `progress.md` with the reason and keep the best attempt under `art/raw/motions-92/`.

## At the end (by 15:55)
`reports/codex-art-92/README.md` (Korean): a table of delivered rows (form · row · file · frames · checks) and failed rows with reasons; `commit.ps1` that stages exactly `commit-paths.txt` (plus this card and its prompt) with `git add --pathspec-from-file`; no `git add -f`, nothing under `art/raw/`, no attempt dumps, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/{frey,luna,nova,rio,yuki}/<stem>-{dodge_roll,taunt,stun,crouch,run_start}-v1.*` (new files only), `art/raw/motions-92/**` (git-ignored), `reports/codex-art-92/**`, `design/tasks/CODEX-ART-92.md`, `design/tasks/CODEX-ART-92.prompt.md`. Nothing under `smash-nine-prototype/` or `tools/` changes; never overwrite an existing file.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads.
