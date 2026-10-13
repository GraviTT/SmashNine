# CODEX-ART-37 · Frey only, phase 1: keep the detail, 6-frame rows (pipeline, anchor idle, J chain)

- Request: 사용자 2026-10-13 "전체적으로 캐릭터들의 디테일이 떨어졌다. 아무래도 한번에 여러 캐릭터들을 작업해서 그런 것으로 보인다. Frey만 재작업 해볼것. 그리고, 현재 4프레임인 동작을 6프레임 이상으로 할 것." Decision D33, sprite rules D32, method `reports/sprite-method-analysis-2026-10-13.md` and `design/tasks/CODEX-ART-36.md` (same method, changes below).
- **Candidates only.** Nothing in `smash-nine-prototype/` changes. The user picks in the motion viewer.
- Unit: one unit, branch `codex/frey-37`, clone `SmashNine-units/builder-frey/SmashNine`. No other unit runs; you have the machine.
- Phase 1 (this card): pipeline detail fix → Frey anchor `idle` (6) → J chain `attack` (6). The lead reviews; phase 2 (next card) draws Frey's other rows with the same settings.

## Why the detail dropped (lead measurement)
Same raw (`reports/codex-art-36a/frey-idle/prepared.png`, cell 0), same factor 0.18761726, against the current game idle (`frey_sheet.png` row 0 frame 0). "Interior detail" = mean |4-neighbour Laplacian| of luminance over opaque pixels whose 4 neighbours are opaque.

| Version | Colours | Interior detail |
| --- | ---: | ---: |
| current game idle | 1405 | 102.0 |
| ART-36 `frey-idle-v1` (BOX + 192-colour palette) | 180 | 65.3 |
| BOX, no palette | 5165 | 63.9 |
| LANCZOS, no palette | 5193 | 69.4 |
| LANCZOS + unsharp mask (radius 1, 60 %, threshold 2) | 4928 | 99.5 |

The BOX average at ×0.19 blurs the drawing; the 192-colour map flattens the shading. Without the palette map, chroma green spills into the hair and shield edges (visible green fringe), so spill must be removed.

## Tasks
1. **`tools/sprite_pipeline/normalize.py`** (+ `test_normalize.py`, README):
   - `--resample box|lanczos` (default `lanczos`) and `--sharpen PERCENT` (unsharp mask radius 1, threshold 2, on RGB before the alpha cut; default 60; 0 = off).
   - `--despill auto`: remove background spill on pixels within 2 px of transparency (for green: G = min(G, max(R, B))). The summary reports remaining spill pixels (G > max(R, B) + 20) for every frame; for Frey it must be 0 (her design has no green).
   - `--palette none` keeps the colours (default for this card). The old path stays available: `--resample box --sharpen 0 --palette <file>`.
   - Metrics per frame: `interior_detail` and colour count; with `--reference`, the reference row's values and the ratio.
   - Tests: the existing ones still pass; add tests for lanczos + sharpen, despill, palette none and the metric (synthetic images).
   - Reproduce the table above with your code: `reports/codex-art-37/detail-baseline.md`.
2. **Anchor `idle`: 6 frames, loop, 10.5 fps** (the same 0.57 s cycle as 4 frames at 7 fps). One generation (a second only if the first fails). 512 px cells, 3×2 (1536×1024). Image 1 = current game idle frame ×4 nearest (identity, proportions, head ratio, rendering detail; do not copy the pose). Image 2 = Frey's illustration (identity only). Feet planted in the same spot in all six; sword and shield grip as in Image 1. Pose lines:
   1. neutral guard stance, weight centred, cape and hair resting back
   2. inhale: chest and shoulders rise slightly, hair tips start to lift
   3. top of the breath: shoulders highest, cape hem swings slightly back
   4. exhale begins: shoulders settle, hair still lifted (lags one frame)
   5. lowest: knees soften slightly, hair and cape settle
   6. between 5 and 1, so the loop is seamless
   
   Normalise with `--scale-by height:100` (the current idle body height) and record the factor.
3. **J chain `attack`: 6 frames, 21 fps** (same length as 4 at 14). The game plays two frames per hit: hit 1 = frames 1–2, hit 2 = 3–4, finisher = 5–6, so each pair must read on its own. Feet on the floor line.
   1. cut 1 wind-up: sword drawn back at hip level, shield forward, small step
   2. cut 1 active: fast horizontal forward slash at chest height, sword arm extended
   3. cut 2 wind-up: sword raised above the shoulder, torso turning back
   4. cut 2 active: diagonal downward cut forward, blade ending low in front
   5. finisher wind-up: deep twist, sword pulled far back low behind the body, front knee bent
   6. finisher active: wide forward sweep, fully extended, lunge step; cape and hair trail behind
   
   One factor for the sheet, matched to the anchor's head on the clearest frame (as in ART-36). If a frame does not fit, regenerate with a tighter pose; never shrink one frame.
4. **Check** both rows on a 4× board (current game frame | new frame) plus metrics:
   - interior detail ≥ 90 % of the current idle (≥ 92)
   - colour count
   - one face per frame, head size like the anchor
   - no green fringe
   - D32 ① border clear, 4 px margin

## Prompt changes from ART-36
- Style line: crisp pixel art rendered **exactly like Image 1**, with the same detail density and the same shading softness. Keep every detail in every frame:
  - individual hair strands with dark separation lines
  - bright rim highlights on the armour plates, gold trim
  - the four-point star emblems on the shield and on the cape
  - the white wing feathers on the circlet helmet
  - the same 1-px dark outline weight
  
  Do not simplify the costume in action frames. Drop "chunky clusters, limited palette".
- Everything else as in ART-36: one motion = one generated image, chroma `#00FF00` background, subject invariants listed from the sheet and `characters/frey/Frey.md`, side view facing right, no effects (no slash arcs, glows, sparks or dust; the game draws them), no text.

## Output
- `art/bakeoff/frey/frey-idle-v2.png` + `frey-idle-v2.json` `{"note": "...", "fps": 10.5, "frames": 6}`.
- `art/bakeoff/frey/frey-attack-v4.png` + `.json` `{"note": "...", "fps": 21, "frames": 6, "hits": [[0, 1], [2, 3], [4, 5]]}`.
- Raw generations and prepared sheets go to `art/raw/frey-37/<row>/` (git-ignored; the lead reads them in your clone). In `reports/codex-art-37/<row>/`: `prompt.txt`, `compare.png` (4×), `metrics.json`. Keep `reports/` small: no raw or prepared images there.
- Report `reports/codex-art-37/README.md` (Korean): the table, the settings used, per-row notes (one face, head size, limbs, does it read as the move, joins to idle), what is still wrong. Plus `commit.ps1` (message ends `Co-Authored-By: Codex <noreply@openai.com>`).

## Writable
`tools/sprite_pipeline/**`, `art/bakeoff/frey/*` (new files only; leave `art/bakeoff/frey/retired/` alone), `art/raw/frey-37/**`, `reports/codex-art-37/**`. Hard stop 50 minutes: deliver the finished parts.

## Phase 2 (next card, for context)
Same settings, one motion per generation, in this order. Rows that are 4 or 5 frames today become 6; the length stays the same (fps × 6 / old frames).
- `walk` 6 @10
- `shield` 6 @12
- `jump` / `fall` / `hurt`: 1 pose each, in one image
- `attack_up` 6 @21
- `attack_down` 6 @21
- `attack_air_side` 6 @21
- `dash_strike` 6 @21
- `rising_cleave` 6 @16.8
- `spike_followup` 6 @21
- `descent` 6 @14
- `tumble` 6 loop @21
