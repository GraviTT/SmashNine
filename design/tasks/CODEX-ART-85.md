# CODEX-ART-85 · Monster projectile repairs and a shockwave for the root guardian

- Request: 점검 세션 "게임 상태 점검 및 정리", 사용자 요청 2026-10-25 — after the checkpoint `checkpoint-2026-10-25` (`c51a417f`), repair and extend the sprites without needing the user. New files are **candidates** next to the old ones; the user picks later.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-a/SmashNine`, branch `codex/art-85` (from the checkpoint).
- Running at the same time: ART-86 fix (fighter sheet repairs) and later ART-84 (portraits) in the other art clone. You share no files. Do not run Godot.
- Read first: `reports/codex-art-79/README.md` (how the projectiles were made and how the game draws them), `smash-nine-prototype/assets/art/monsters/README.md` (the adoption table of SYS-07: a strip's frame count is its width divided by its height; `bolt` kinds turn with their flight, `lob`, `bomb` and `homing` are not rotated). Their raws are in this clone: `art/raw/projectiles-79`.
- Nothing under `smash-nine-prototype/` or `tools/` changes. **Never overwrite**: write the next free version.

## Work
1. **Bomb** (`svartalfheim_cog_drone-projectile-v1`, 4 frames): the tumble jumps 90° per frame. Make it an **8-frame** tumble (45° steps) in 48-px cells so it reads smooth at 12 fps; the fuse spark flickers. The wiring plays any whole number of square frames.
2. **Ice shard** (`niflheim_frost_owl-projectile-v1`): the frosty tail changes too much between frames. Keep the shard identical and let only the tail shimmer a little.
3. **Root guardian shockwave** (new): `slam_shockwave-v1` is drawn in the rune golem's blue stone and gold rune colours, but the Yggdrasil root guardian uses the same slam. Make `yggdrasil_root_guardian-shockwave-v1.png` in the guardian's colours (its current sheet and its ART-76 rows: purple bark, teal roots, magenta glow): a crest of roots and earth, 4 frames, 64×48, floor at y=44, moving right. The game does not use a per-monster shockwave yet; say so in the note (the wiring comes when the user adopts it).
4. Look again at the other five projectiles at 1× and 36 px: if one has a defect you can see (a cut edge, a halo, a frame that jumps), fix it the same way; otherwise leave it and say so.

## Checks and output
As ART-79: transparent background, 2–3 px margin, spill 0, no text, readable at 36 px; a board per file with the old and the new version at 1×, 4× and in the in-context mock (`reports/codex-art-85/<id>.png`).
- Files: `art/bakeoff/monsters/<id>-projectile-v2.png` (+ `.json`: `note` in Korean, `frames`, `fps`, `cell`, `aim`, `replaces`), `art/bakeoff/monsters/yggdrasil_root_guardian-shockwave-v1.png` (+ `.json`).
- `reports/codex-art-85/README.md` (Korean), `prompts.txt`, `commit.ps1` (only your files, this card and its prompt included, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`).

## Writable
`art/bakeoff/monsters/*-projectile-v2.*`, `art/bakeoff/monsters/yggdrasil_root_guardian-shockwave-v1.*` (new files), `art/raw/projectiles-85/**` (git-ignored), `reports/codex-art-85/**`, `design/tasks/CODEX-ART-85.md`, `design/tasks/CODEX-ART-85.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 90 minutes.
