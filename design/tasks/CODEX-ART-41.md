# CODEX-ART-41 · Frey `descent`: a dive that slams the sword down, not a landing

- Request: 사용자 2026-10-14 "전체적으로 바뀐 버전이 매우 마음에 든다. 딱 하나, decent만 이전의 검을 아래로 내려 찍는 급강하가 아닌 자연스러운 착지 처럼 느껴지니 그것만 변경하면 완성 될 것 같다." Every other Frey row from ART-37–40 is accepted; this is the last one. Rules: D32, D33, D34 (192-px move cell, feet y=152, torso x=96), head scale 0.96–1.04.
- Unit: one unit, branch `codex/frey-41`, clone `SmashNine-units/builder-frey/SmashNine`. No other unit runs.
- Settings as ART-40: `--cell 192 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`. Factor: one for the sheet, matched with `tools/sprite_pipeline/head_scale.py --anchor art/bakeoff/frey/frey-idle-v2.png:0`.

## What is wrong with `frey-descent-v3`
It reads as a natural landing:
- F4 is a soft squash with the sword low in front, F5 is braced, and F6 rises to guard.
- The dive does not lead with the sword, and the sword never slams into the ground.

The user wants the old move's feel (the current game row, `smash-nine-prototype/assets/art/frey/frey_moves_sheet.png` row 7): power gathers, she goes up, dives straight down with the sword thrust below her, and the sword is driven into the ground.

## The move (Frey.md, I — Descent)
- On the ground: a short gather, then she smashes the ground; the game adds the shockwaves.
- In the air: she cuts gravity, dives straight down, and the same shockwave fires on landing.

The same row serves both, and the game plays the whole row over 0.95 s on the ground and 1.45 s in the air.

## Pose lines (6 frames, 14 fps)
1. **Charge on the ground:** deep crouch, sword held low behind, shield forward, body coiled.
2. **Spring:** leaving the ground, sword swung up over the head in both hands, knees tucked.
3. **Turn over:** in the air at the top, the sword flips point-down with both hands on the hilt at chest height, body upright and compact.
4. **Plunge:** body straight and vertical, the sword thrust straight down below her feet leading the dive, hair and cape streaming upward with the speed.
5. **Slam:** the sword is driven point-first into the ground right in front of her. She lands on one knee in a deep crouch, both hands pushing down on the hilt; cape and hair flare out. Heavy and violent, not soft.
6. **Planted:** the same kneeling pose pressed a little lower, sword still buried, hair settling. She does **not** stand up in this row (the game returns her to idle).

## Constraints
- In frames 5–6 the buried part of the blade is not drawn: the blade ends at the floor line as if stuck in the ground. Her knee, foot and the blade end sit on the floor line (y=152).
- No effects: no light pillar, burst, shockwave, dust, glow, sparks, speed lines or wings. The game draws them.
- Same detail and invariants as the accepted rows (style line from `reports/codex-art-37/idle/prompt.txt`). Image 1 = the anchor `frey-idle-v2` (size, look, detail). Image 2 = the current game descent row ×4 (the move; ignore its effects).
- Head-scale median 0.96–1.04. All frames fit the 192 cell: border clear, 4 px margin. Spill 0, detail ≥ 90. One face; arms, sword and shield intact.
- Up to 2 generations. Keep the one that reads most clearly as a slam.

## Output
- `art/bakeoff/frey/frey-descent-v4.png` (1152×192) + `.json` `{"note": "...", "fps": 14, "frames": 6, "cell": 192, "feet": 152}`.
- Raw generations go to `art/raw/frey-41/` (git-ignored).
- `reports/codex-art-41/`: `prompt.txt`, `compare.png` (4×: anchor | current game row | v4), `metrics.json` (factor, lift scale, head scale), `README.md` (Korean: per-frame check, what is still wrong), `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/frey/frey-descent-v4.*`, `art/raw/frey-41/**`, `reports/codex-art-41/**`. Hard stop 45 minutes.
