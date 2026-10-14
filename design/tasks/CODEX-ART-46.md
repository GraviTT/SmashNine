# CODEX-ART-46 · Luna's special transformation: 12 frames, normal Luna → Brave Luna (②)

- Request: 사용자 2026-10-14 "추가로, Luna가 궁극기를 사용할 때 변신하는 특별 모션이 있으면 좋겠다." Brave design D36 (② ponytail combat outfit). Method D35, rules D32–D34. **Candidates only**; nothing in `smash-nine-prototype/` changes.
- Anchors:
  - `art/bakeoff/luna/luna-idle-v3.png` (normal Luna, ART-43)
  - `art/bakeoff/luna/luna_brave-idle-v4.png` (Brave ②)
  
  Both heads equal the current Luna's.
- The row replaces the move row `transform` (today 6 frames over 0.52 s, effects baked in). The lead will play it over about 1.0 s at 12 fps. The game puts the transformation burst at frame 9 and draws the light, sparkles and flash itself.

## The 12 frames (12 fps)
1. Normal Luna, eyes closed, both hands holding the star wand at her chest, calling the power.
2. She raises the wand high over her head, looking up, rising onto her toes.
3. She lets the wand go upward; it hovers just above her open hand; arms spread.
4. The spin begins, lifted a little off the ground: 3/4 back view, arms crossed over her chest, the long hair swirling loose (normal outfit).
5. Spin, back view: the hair whips around and gathers up behind her head as the bow rises to tie it; the dress flares.
6. Spin, side view: the high ponytail is tied with the bow and the gold star. The armoured gauntlets are on her crossed fists, and the dress has become the short combat outfit with the scarf.
7. Spin, front 3/4 view: Brave ② complete, arms still crossed, eyes closed.
8. The spin ends: arms uncross, fists out to the sides, ponytail and scarf swinging.
9. She lands in a crouch, one fist planted on the ground (the game's burst).
10. She rises from the crouch, punching one fist up and forward.
11. Hero pose: one fist forward, the other on her hip, a confident grin, a wink.
12. The same hero pose settling: ponytail and scarf come to rest, ready to fight.

Rules:
- Frames 1–4 are normal Luna (`luna-idle-v3`: dress, long loose hair, wand). Frames 6–12 are Brave ② (`luna_brave-idle-v4`). Frame 5 is the hidden change.
- The head size is the anchors' in all 12 frames.
- No light, sparkles, ribbons of light, glow or burst. The crossed arms and the turning body carry the change.
- Frames 4–8 float a little (lifted in the cell); 9–12 stand on the floor line.

## How
- Two generations of 6 (3×2, 512-px cells): frames 1–6, then 7–12.
  - First: Image 1 = `luna-idle-v3` ×4, Image 2 = `luna_brave-idle-v4` ×4.
  - Second: Image 1 = the first generation's sheet (the spin and the size continue), Image 2 = `luna_brave-idle-v4` ×4.
  - Up to two tries per half.
- `normalize.py --cell 192 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`.
- One factor per half, each matched with `head_scale.py`: frames 1–4 against `luna-idle-v3.png:0`, frames 6–12 against `luna_brave-idle-v4.png:0`, median 0.96–1.04.
- Join the halves into one 12-cell strip, 2304×192 (feet y=152).
- Checks: border clear, 4 px margin, spill 0, detail ≥ 90, one face, hands and gauntlets intact. Look at every frame at 4×, and make a 12-frame looping preview (GIF or a strip at 2×) to judge the flow.

## Output
- `art/bakeoff/luna/luna-transform-v2.png` (2304×192) + `.json` `{"note": "특별 변신 12프레임 …", "fps": 12, "frames": 12, "cell": 192, "feet": 152}`.
- Raw generations go to `art/raw/luna-46/` (git-ignored).
- `reports/codex-art-46/`: `prompt-1.txt`, `prompt-2.txt`, `compare.png` (4×), `preview.gif` or `preview.png`, `metrics.json`, `README.md` (Korean: per-frame check, what is still wrong), `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/luna/luna-transform-v2.*`, `art/raw/luna-46/**`, `reports/codex-art-46/**`. Hard stop 60 minutes.
