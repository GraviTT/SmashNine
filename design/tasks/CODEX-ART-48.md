# CODEX-ART-48 · Yuki phase 1: the anchor idle

- Request: 사용자 2026-10-14 "그 다음으로 Yuki를 같은 방식으로 작업 해볼 것." Method D35 (as Frey and Luna: `reports/frey-rework-2026-10-14.md`, cards `CODEX-ART-37` … `CODEX-ART-46`), rules D32–D34, idle speed D37 (6.3 fps). **Candidates only**; nothing in `smash-nine-prototype/` changes.
- Unit: branch `codex/yuki-48`, clone `SmashNine-units/builder-frey/SmashNine`. A main-art unit (`CODEX-ART-47.md`) runs at the same time in `builder-art`; keep to your files.
- This phase draws the anchor that every later Yuki row is measured against. The lead reviews it, then the rows follow.

## Yuki
An onmyoji (음양사) controller (`smash-nine-prototype/characters/yuki/Yuki.md`): talismans thrown at range and seals placed in advance. Take her look from the current `yuki_sheet.png` and `yuki_illustration.png`:
- long black hair with violet sheen
- a red bow with white dots and a gold bell ornament
- red eyes
- a red-and-black onmyoji outfit with long white sleeves
- red paper talismans with gold marks
- dark boots

She is 2.5 heads tall (D25).

## The anchor: `yuki-idle-v2`, 6 frames, loop, 6.3 fps
- Image 1 = the current `yuki_sheet.png` idle frame 1 ×4 nearest (identity, proportions, head ratio, rendering detail; not the pose).
- Image 2 = `yuki_illustration.png` (identity only).
- A calm, ready stance holding a fan of talismans in one hand as today; feet planted.
  1. neutral
  2. inhale, shoulders up slightly, sleeves and hair lift
  3. top of the breath, the bow ribbon tails float
  4. exhale begins, sleeves still lifted (they lag one frame)
  5. lowest
  6. between 5 and 1 for a seamless loop
- Settings: `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`.
- **The factor is chosen by the head:** `head_scale.py --anchor smash-nine-prototype/assets/art/yuki/yuki_sheet.png:0` must read 0.96–1.04. The body height must then be 85–91 px (today's idle is 88). If it is taller or shorter, the proportions are wrong: regenerate (at most twice), stressing her 2.5-head chibi proportions exactly as Image 1. Never squash.
- No effects: no glow, sparkles or floating talisman trails; the talismans are paper in her hand.
- Checks:
  - border clear, 4 px margin, spill 0, detail ≥ 90
  - one face; hands, talismans and boots intact
  - look at every frame at 4× next to the current idle

## Output
- `art/bakeoff/yuki/yuki-idle-v2.png` (768×128) + `.json` `{"note": "...", "fps": 6.3, "frames": 6}`.
- Raw generations go to `art/raw/yuki-48/` (git-ignored).
- `reports/codex-art-48/idle/`: `prompt.txt`, `compare.png` (4×), `metrics.json` (factor, head scale, body height).
- `reports/codex-art-48/README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/yuki/yuki-idle-v2.*`, `art/raw/yuki-48/**`, `reports/codex-art-48/**`. Hard stop 40 minutes.
