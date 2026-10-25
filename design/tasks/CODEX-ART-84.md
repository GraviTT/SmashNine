# CODEX-ART-84 · Dialogue portrait repairs: two hurt faces and the shadow faces

- Request: 점검 세션 "게임 상태 점검 및 정리", 사용자 요청 2026-10-25 — after the checkpoint `checkpoint-2026-10-25` (`c51a417f`), repair the sprites without needing the user. New files are **candidates** next to the old ones; the user picks later.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-b/SmashNine`, branch `codex/art-84` (from the checkpoint).
- Running at the same time: ART-85 (projectile repairs) in the other art clone. You share no files. Do not run Godot.
- Read first: `reports/codex-art-73/README.md` (the edit and composite method: the generated edit pasted onto the neutral through a feathered face mask, every pixel outside the mask equal to the neutral) and `reports/codex-art-80/README.md` (the shadow faces). Their raws are in this clone: `art/raw/faces-73`, `art/raw/faces-80`.
- Nothing under `smash-nine-prototype/` or `tools/` changes. **Never overwrite**: write the next free version.

## 1. Two hurt faces that read weakly (ART-73's own notes)
- `yuki/yuki_face-hurt-v1`: the pain is held back at the dialogue size (bangs and a small sweat drop). Make it read: brows up and together, eyes squeezed or half shut, mouth tight or open, a clearer sweat drop.
- `rio/rio_male_face-hurt-v1`: at the small size it reads as tired or frowning. Make it read as pain.
- The ART-73 method: an edit of the neutral face, composited through the face mask; outside the mask 0 changed pixels; the seam invisible at 4×.

## 2. Shadow faces (ART-80's own notes)
- All eight: skin and metal are a little bright for a shadow. Darken them toward the shadow palette (near-black violet, blue-grey, the game's shadow tint 0.42, 0.24, 0.62) while the eyes keep their glow. A tone curve in Python is allowed if it keeps every line and detail; otherwise an edit with the image tool.
- `yuki_face-shadow-v1`: the talisman competes with the eyes — tone the talisman down.
- `rio_female_face-shadow-v1`: the glowing eyes are small at the dialogue size — make the glow read.
- Keep each shadow lined up with the neutral (the same offset rule as ART-80) and transparent where the neutral is.

## Checks and output
- 256×256 RGBA; for part 1 the outside-mask change and the seam measure (as ART-73); for part 2 the alignment offset and a contrast measure (eye glow brightness against the face) before → after.
- Files: `art/bakeoff/<folder>/<stem>_face-<expression>-v2.png` + `.json` (`note` in Korean, `expression`, `edited_from`, `replaces`).
- Boards: `reports/codex-art-84/<stem>-<expression>.png` — v1 and v2 at 1×, at 142×164, and in a dialogue mock (the hero on the left, the speaker on the right).
- `reports/codex-art-84/README.md` (Korean), `prompts.txt`, `commit.ps1` (only your files, this card and its prompt included, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`).

## Writable
`art/bakeoff/{frey,luna,yuki,nova,rio}/*_face-*-v2.*` (new files), `art/raw/faces-84/**` (git-ignored), `reports/codex-art-84/**`, `design/tasks/CODEX-ART-84.md`, `design/tasks/CODEX-ART-84.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 120 minutes. Part 1 first.
