# CODEX-ART-51 · Nova phase 1: the two anchors (male, female)

- Request: 사용자 2026-10-14 "다음은 Nova." Method D35 (as Frey, Luna, Yuki: `reports/frey-rework-2026-10-14.md`, `reports/yuki-rework-2026-10-14.md`), rules D25, D32–D34, idle speed D37 (6.3 fps). **Candidates only**; nothing in `smash-nine-prototype/` changes.
- Unit: branch `codex/nova-51`, clone `SmashNine-units/builder-frey/SmashNine`. A main-art unit (`CODEX-ART-53.md`) runs at the same time in `builder-art`; keep to your files.
- Nova has two bodies, `nova_male` and `nova_female` (sheets `smash-nine-prototype/assets/art/nova/nova_<body>_sheet.png`). Each gets its own anchor; the rows follow after the lead's review (ART-52, two units).

## Nova
A superhero, a gravity-vector aerial chaser (`smash-nine-prototype/characters/nova/Nova.md`). Take the look from the current sheets and `nova_<body>_illustration.png`:
- a dark navy bodysuit with white-silver chest and shoulder armour plates
- a cyan core on the chest
- cyan armoured gauntlets and boots with gold accents
- teal eyes
- male: short spiky dark-blue hair; female: longer dark-blue hair and a slimmer waist

Both are 2.5 heads tall (D25).

## Each anchor: `nova_<body>-idle-v2`, 6 frames, loop, 6.3 fps
- Image 1 = that body's current `nova_<body>_sheet.png` idle frame 1 ×4 nearest (identity, proportions, head ratio, rendering detail; not the pose).
- Image 2 = `nova_<body>_illustration.png` (identity only).
- A light, ready hero stance with fists up as today, feet planted.
  1. neutral
  2. inhale, shoulders up slightly
  3. top of the breath, hair lifts
  4. exhale begins, hair still lifted (it lags one frame)
  5. lowest
  6. between 5 and 1 for a seamless loop
- Settings: `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`.
- **Factor by the head:** `head_scale.py --anchor smash-nine-prototype/assets/art/nova/nova_<body>_sheet.png:0` must read 0.96–1.04.
  - If fewer than 2 frames score ≥ 0.6, do not trust the median. Compare the standing height and 4× head crops with the current idle and say what you used.
  - Then the body height must be male 89–95 px (today 92), female 87–93 px (today 90). Otherwise regenerate (at most twice) stressing the 2.5-head proportions of Image 1. Never squash.
- **Detail target:** ≥ 90 % of that body's current idle interior detail: **male ≥ 84, female ≥ 79**.
- No effects: no glow halo around the core, gauntlets or boots, no afterimages. The core is a solid cyan shape.
- Checks:
  - border clear, 4 px margin, spill 0
  - one face; hands, gauntlets and boots intact
  - every frame at 4× next to the current idle

## Output
- `art/bakeoff/nova/nova_male-idle-v2.png` and `nova_female-idle-v2.png` (768×128), each with a `.json` `{"note": "<Korean>", "fps": 6.3, "frames": 6}`.
- Raw generations go to `art/raw/nova-51/` (git-ignored).
- `reports/codex-art-51/<body>/`: `prompt.txt`, `compare.png` (4×), `metrics.json` (factor, head scale, body height, detail).
- `reports/codex-art-51/README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/nova/nova_male-idle-v2.*`, `art/bakeoff/nova/nova_female-idle-v2.*`, `art/raw/nova-51/**`, `reports/codex-art-51/**`. Hard stop 45 minutes.
