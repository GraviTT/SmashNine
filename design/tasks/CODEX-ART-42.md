# CODEX-ART-42 · Luna phase 1: the two anchors (Luna idle, Brave Luna idle)

- Request: 사용자 2026-10-14 "Luna 진행. Brave까지. 추가로, Luna가 궁극기를 사용할 때 변신하는 특별 모션이 있으면 좋겠다." Method D35, the one that made Frey (`reports/frey-rework-2026-10-14.md`, cards `CODEX-ART-37.md` … `CODEX-ART-41.md`); rules D32–D34. **Candidates only**; nothing in `smash-nine-prototype/` changes.
- Unit: one unit, branch `codex/luna-42`, clone `SmashNine-units/builder-frey/SmashNine`. No other unit runs.
- This phase draws the two anchors that every later Luna row is measured against. The lead reviews them, then the rows and the special transformation follow (two units).

## Settings (as Frey)
- `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`.
- One factor per sheet.
- 512-px generation cells, 3×2 for 6 frames.
- Prompt structure as `reports/codex-art-37/idle/prompt.txt`, including the detail style line. Rewrite its Frey invariants for Luna:
  - long pink hair
  - the purple ribbon with a gold star
  - the purple magical-girl dress with white frills
  - the star wand (normal form) or the star gauntlets (Brave)
  - boots
  - exact colours from the current sheets and `luna_illustration.png`
- No effects: no sparkles, glow halos, light trails or auras. The game draws them. The wand's star and the gauntlets are solid objects with no glow around them.

## 1. Luna idle (anchor): 6 frames, loop, 10.5 fps
- Image 1 = the current `luna_sheet.png` idle frame 1 ×4 nearest (identity, proportions, head ratio, rendering detail; not the pose).
- Image 2 = `luna_illustration.png` (identity only).
- Breathing loop holding the star wand forward as today; feet planted.
  1. neutral
  2. inhale, shoulders up slightly, hair tips lift
  3. top of the breath, ribbon and hair float back
  4. exhale begins, hair still lifted (lags one frame)
  5. lowest, knees soften slightly
  6. between 5 and 1 for a seamless loop
- Normalise with `--scale-by height:82` (the current idle body height; it keeps her size in the game) and record the factor.

## 2. Brave Luna idle (anchor): 6 frames, loop, 10.5 fps
- Image 1 = the accepted Luna anchor (size, face, hair, detail).
- Image 2 = the current `luna_brave_sheet.png` idle frame 1 ×4 (the Brave outfit and stance).
- A light, bouncy fighting stance with the star gauntlets up; feet planted, small bounce.
  1. guard
  2. knees dip
  3. lowest
  4. rising
  5. top, hair and ribbon lag
  6. between 5 and 1
- **Same person, same head size:** the factor makes `head_scale.py --anchor art/bakeoff/luna/luna-idle-v2.png:0` read 0.96–1.04 on this row. The tool matched the current Brave sheet against the current Luna sheet at 0.96–1.00 with scores 0.73–0.77, so it works across the two outfits.

## Checks (both rows)
- head scale (Brave against the Luna anchor) 0.96–1.04
- border clear, 4 px margin, spill 0, detail ≥ 90
- one face; hands, wand or gauntlets, boots intact
- look at every frame at 4× next to the current sheet's idle

## Output
- `art/bakeoff/luna/luna-idle-v2.png` and `art/bakeoff/luna/luna_brave-idle-v2.png` (768×128), each with a `.json` `{"note": "...", "fps": 10.5, "frames": 6}`.
- Raw generations go to `art/raw/luna-42/` (git-ignored).
- `reports/codex-art-42/<row>/`: `prompt.txt`, `compare.png` (4×), `metrics.json` (factor, head scale).
- `reports/codex-art-42/README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/luna/*` (new files only; leave `retired/` alone), `art/raw/luna-42/**`, `reports/codex-art-42/**`. Hard stop 40 minutes.
