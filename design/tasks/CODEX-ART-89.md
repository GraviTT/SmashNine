# CODEX-ART-89 · Character motions, second try: the rows ART-82 could not repair

- Request: 점검 세션 "게임 상태 점검 및 정리", 사용자 요청 2026-10-25 — after the checkpoint `checkpoint-2026-10-25` (`c51a417f`), repair the sprites without needing the user. New files are **candidates**; the user picks later.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-a/SmashNine`, branch `codex/art-89`. Its base already holds the ART-82 and ART-86 candidates (merged in this clone only).
- Running at the same time: ART-84 (portrait repairs) in `art-b`. You share no files. Do not run Godot.
- Read first: `design/tasks/CODEX-ART-72.md`, `design/tasks/CODEX-ART-82.md` and what ART-82 found (`ref82/README-v2.md`, `ref82/README.md`, read-only copies), `reports/codex-art-86/README.md`. The raws are in this clone: `art/raw/motions-72`, `motions-75`, `motions-77`, `motions-78`, `motions-82`, `fighters-86`, `rio-61a`, `rio-61b`, `rio-65`.
- Nothing under `smash-nine-prototype/` or `tools/` changes. **Never overwrite**: write the next free version.

## Why a second try
ART-82 retried single frames. For six rows every frame retry broke the face or the pose, so nothing was delivered. This time **regenerate the whole row** in one generation (all frames in one image, as ART-72 first did), with the anchor idle as Image 1 and the current best version as Image 2 for the pose, then build it with one factor. Up to 3 whole-row generations per row; keep the best.

## Rows
| Row (current best) | Goal |
|---|---|
| `frey/frey-victory-v1` | every measurable frame's face 0.96–1.04; the one rising sword movement kept |
| `frey/frey-jump-v2` | face within the rule; take-off, rising, apex distinct |
| `luna/luna_brave-hurt-v2` | face within the rule; head snaps back, torso leans away, recovers |
| `luna/luna_brave-jump-v2` | face within the rule; take-off, tuck, apex distinct |
| `luna/luna_brave-fall-v3` | face within the rule; the two frames flutter differently |
| `yuki/yuki-victory-v1` | face within the rule; talisman flick, then the fan at the chin |
| `luna/luna-victory-v2` | one smooth twirl (no big F3→F4 jump), the wand in the same hand, star pose and wink |
| `nova/nova_female-victory-v2` | jab with alternating arms, then the raised fist and the wink |
| `rio/rio_male-victory-v2` | a smooth F3→F4 (the flourish into the planted sword) |
| `rio/rio_male-walk-v2` | the left/right leg alternation reads at 1× (8 frames, the size ART-86 restored) |

## Checks and output
As CODEX-ART-72: the settings, the face check (`face_check.py`, the face decides; frames with a hidden or closed eye are reported, not failed), costume exactly as the idle, border clear, 4 px margin, spill 0, detail ≥ 79, feet on the line where grounded. Deliver a row only if every measurable frame is within 0.96–1.04 and the motion goal is met; otherwise report the best attempt and why.
- Files: the next free version, `art/bakeoff/<folder>/<stem>-<row>-v<n>.png` + `.json` (`note` in Korean with the per-frame face ratios; `replaces`: the current best file).
- A 4× board per row: anchor, current best, new (`reports/codex-art-89/<stem>-<row>.png`).
- `reports/codex-art-89/README.md` (Korean), `prompts.txt`.
- `reports/codex-art-89/commit.ps1`: stage with `git add --pathspec-from-file`; only your files (this card and its prompt included; not `ref82/`), no per-attempt dumps, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/{frey,luna,yuki,nova,rio}/**` (new files only), `art/raw/motions-89/**` (git-ignored), `reports/codex-art-89/**`, `design/tasks/CODEX-ART-89.md`, `design/tasks/CODEX-ART-89.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 150 minutes. Rows in the table order.
