# CODEX-ART-60 · Rio remake phase 1: the two anchors (male, female)

- Request: 사용자 2026-10-15 "다른 캐릭터들도 진행하고, 이후 Rio의 스프라이트 리메이크 진행. 완성 될 때 까지 루틴으로. 단, … 성공한 사례만 따라갈것."
- Method D35, exactly as Nova's anchors (`design/tasks/CODEX-ART-51.md`, `reports/codex-art-51/`). Rules D25, D32–D34; idle speed D37 (6.3 fps). **Candidates only**; nothing in `smash-nine-prototype/` changes.
- Unit: branch `codex/rio-60`, clone `SmashNine-units/builder-art/SmashNine`. Unit A runs walks (ART-59) in `builder-frey` at the same time; keep to your files.
- Rio has two bodies, `rio_male` and `rio_female` (sheets `smash-nine-prototype/assets/art/rio/rio_<body>_sheet.png`). Each gets its own anchor; the rows follow (ART-61).

## Rio
A magic-sword assassin from a knight academy (`smash-nine-prototype/characters/rio/Rio.md`): fast sword work, mana sword waves, short blink slashes, a rune shield. Take the look from the current sheets and `rio_<body>_illustration.png`:
- black armour with cyan trim lines and small cyan gems
- a dark cape with a blue inner lining
- a straight sword in the near hand, pointing forward-down, with a bright blue blade. Draw the blade as a solid bright blue shape, with no glow halo.
- blue eyes
- male: spiky dark-blue hair
- female: a long high dark-blue ponytail with a cyan tie

Both are 3 heads tall (D25).

## Each anchor: `rio_<body>-idle-v2`, 6 frames, loop, 6.3 fps
- Image 1 = that body's current `rio_<body>_sheet.png` idle frame 1, 4× nearest. It sets identity, proportions, head ratio and rendering detail, but not the pose.
- Image 2 = `rio_<body>_illustration.png`, for identity only.
- A calm ready stance, the sword low and forward as today, feet planted:
  1. neutral
  2. inhale, shoulders up slightly
  3. top of the breath, hair and cape lift
  4. exhale begins, hair and cape still lifted (they lag one frame)
  5. lowest
  6. between 5 and 1, for a seamless loop
- Settings: `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`.
- **Factor by the head:** `head_scale.py --anchor smash-nine-prototype/assets/art/rio/rio_<body>_sheet.png:0` must read 0.96–1.04.
  - If fewer than 2 frames score ≥ 0.6, compare the standing height and 4× head crops with the current idle, and say what you used.
  - The body height must then be male 95–101 px (today 98) and female 93–99 px (today 96). Otherwise regenerate, at most twice, stressing Image 1's 3-head proportions. Never squash.
- **Detail target:** ≥ 90 % of that body's current idle interior detail: **male ≥ 79, female ≥ 73**.
- No effects: no glow around the blade, gems or trim, no afterimages, no particles.
- **Checks:**
  - border clear, 4 px margin, spill 0
  - one face; hands, sword and boots intact
  - every frame at 4× next to the current idle

## Output
- `art/bakeoff/rio/rio_male-idle-v2.png` and `rio_female-idle-v2.png` (768×128). Each has a `.json` `{"note": "<plain Korean>", "fps": 6.3, "frames": 6}`.
- Raw generations go to `art/raw/rio-60/` (git-ignored).
- `reports/codex-art-60/<body>/`: `prompt.txt`, `compare.png` (4×), `metrics.json` (factor, head scale, body height, detail).
- `reports/codex-art-60/README.md` (Korean, short) and `commit.ps1`: no `git add -f`, nothing under `art/raw/`, no `__pycache__`.

## Writable
`art/bakeoff/rio/rio_male-idle-v2.*`, `art/bakeoff/rio/rio_female-idle-v2.*`, `art/raw/rio-60/**`, `reports/codex-art-60/**`. Hard stop: 40 minutes.
