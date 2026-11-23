# CODEX-ART-96 · Xion B, stage 1: the idle anchor with the full scarf, and the main illustration with her hologram double

- Request: the user picked **B (the short coat)** in the pick cup. Round `2026-11-19`, item `xion-concept`: B won all 5 of its matches (15 points); the verdict is in `cup_verdicts`. Then the user said "전부 진행해" (2026-11-23, through the 총괄 session).
- The user's story (2026-11-19):
  - "한 소녀가 누군가에 의해 100년 간 시간의 개념이 없는 공간에서 시공간 괴물들을 사냥하며 살아남았고, 이후 현실로 돌아왔다"
  - "도플갱어는 협력하는 또 다른 시간선의 Xion … 일러스트에도 홀로그램 같은 모습으로"
- This card is stage 1 of her base art. Stage 2 (ART-97) draws every other row from the anchor made here.
- Method: D35 (anchor first) and ART-94 (`design/tasks/CODEX-ART-94.md`, B's own report `reports/codex-art-94b/`). Rules: D22, D25, D32–D35, D37. **Candidates only:** nothing under `smash-nine-prototype/` changes; the lead installs.
- Two units run at the same time on different files:

  | Unit | Job | Branch | Clone |
  | --- | --- | --- | --- |
  | `art-b` (B's author) | 1. the idle anchor v2 | `codex/xion-96b` | `SmashNine-units/art-b/SmashNine` |
  | `art-a` | 2. the illustration v2 with the double | `codex/xion-96a` | `SmashNine-units/art-a/SmashNine` |

## The design (B, unchanged)
- A black coat that ends at the hips, with silver lines.
- A long crimson scarf tied at the neck below the chin; its two tails trail behind her.
- Short black hair with one silver streak, grey eyes.
- Fingerless gloves, fitted trousers and buckled boots.
- One short pump shotgun in each hand: the same model, thick muzzle, small crimson mark.
- Sources: `art/bakeoff/xion/b/xion_illustration-b.png`, `xion_face-b.png`, `xion-idle-b.png`.
- The user left no note on B. Notes on the other concepts show what the user checks: "일러스트 팔 오류" (C), "일러스트 신체 비율 수정 필요" (D). Arms, hands and proportions must be right.

## 1. Idle anchor v2 (`art-b`): `art/bakeoff/xion/b/xion-idle-b2.png`
768×128: 6 frames, a loop at 6.3 fps.
- Redraw v1 (`xion-idle-b.png`) with one change: **the scarf tails as long as in the illustration.**
  - Measure, in the illustration, how far the tails reach behind the back of the neck, as a fraction of her standing height (crown to sole).
  - Draw the sprite's tails to the same fraction (±10 %). Today they are about 20 % shorter.
  - Two tails, trailing behind (toward −x, she faces right), lifting and settling with the breath. They lag one frame, as the hair does.
  - The scarf stays below the chin: the head and face remain clear.
- Everything else stays as in v1: pose, coat, hair, both guns in both hands, feet planted.
- References:
  - Image 1 = v1 frame 1 at 4× (identity, proportions, head size, detail)
  - Image 2 = the illustration (the scarf's length and its two tails)
- Size: 3 heads (D25), standing height 95–100 px, feet at y=120.
  - Head size: compare with Rio female's idle head at 4× and with `head_scale.py --anchor smash-nine-prototype/assets/art/rio/rio_female_sheet.png:0 --sheet <your strip>`. Report both and aim for about the same head (median 0.96–1.04).
  - Head scale between your own six frames: median 0.96–1.04.
  - Detail ≥ 90 % of Rio female's idle.
- Settings as ART-94: `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`. One generation; at most two more if a check fails.
- Checks: border clear, 4-px margin, green spill 0; one face; both hands and both guns intact; the scarf the same length in all six frames (±2 px); every frame at 4× beside v1.
- Output:
  - `xion-idle-b2.png` + `xion-idle-b2.json`: `{"note": "<Korean>", "fps": 6.3, "frames": 6, "loop": true}`
  - `reports/codex-art-96b/`: `compare.png` (v1 against v2 at 4×), `scarf.json` (illustration fraction, sprite fraction per frame), `metrics.json`, `idle-4x.gif`, `README.md` (Korean, UTF-8), `commit.ps1`

## 2. Illustration v2 with the double (`art-a`): `art/bakeoff/xion/b/xion_illustration-b2.png`
1024×1536 RGBA, transparent background.
- **Keep B's figure exactly as drawn.** You may scale it down to 90–95 % and move it right to make room, nothing else. Do not redraw her: her arms, hands and proportions are what the user picked.
- **The double:** another timeline's Xion, behind her and to the left, cooperating with her.
  - For example, back to back with her, aiming the other way with both shotguns.
  - The same person in B's design. She may differ in one detail that marks another timeline, for example a longer scarf, a scar, or hair tied back.
  - Draw her first as a normal full-colour figure: a new generation with B's illustration as the reference, checked for arms, hands and guns like the main figure.
- Turn her into the hologram **in code**, with the formula the game uses for the double (`smash-nine-prototype/characters/xion/XionDouble.gd`, commit `06b8041b`), so the picture and the game match:
  - colour = tint (0.96, 0.24, 0.34) × (0.42 + 0.85 × luminance); luminance = 0.299 R + 0.587 G + 0.114 B
  - two of every three rows at 0.55 alpha. Scale the row period so it still reads at the select screen's display size (a 6-px period, 4 px dim and 2 px full, is a good start); say what you used.
  - one bright horizontal band (× 1.6) across her
  - overall alpha 0.62
  - one or two thin horizontal slices shifted a few pixels (the flicker)
- She sits behind B: B's figure is composited over her. She never covers B's face or head.
- House style and checks as ART-94:
  - look at the whole picture at full size: B unchanged, the double's arms, hands and two guns
  - alpha, size, fringe 0
  - the picture on #2a2d34 and on #c8c4b8
- Face: `xion_face-b.png` stays as it is (cut from B's figure, without the double). Confirm that B's figure is unchanged, so the face still matches.
- Output:
  - `art/bakeoff/xion/b/xion_illustration-b2.png`
  - the double before the hologram: `art/bakeoff/xion/b/xion_double-b2-colour.png`
  - `reports/codex-art-96a/`: `hologram.py` (the treatment), `compare.png` (v1 against v2 at 50 %), `full-size-checks.png`, `README.md` (Korean, UTF-8), `commit.ps1`

## Both
- Raw generations go to `art/raw/xion-96<a|b>/` (git-ignored).
- `commit.ps1`: paths in a literal string array, only your files and this card, no `git add -f`, nothing under `art/raw/`, ending with `Co-Authored-By: Codex <noreply@openai.com>`. Do not run it.
- Separate what you measured from what you judged by eye.

## Writable
- `art-b`: `art/bakeoff/xion/b/xion-idle-b2.*`, `art/raw/xion-96b/**`, `reports/codex-art-96b/**`
- `art-a`: `art/bakeoff/xion/b/xion_illustration-b2.png`, `art/bakeoff/xion/b/xion_double-b2-colour.png`, `art/raw/xion-96a/**`, `reports/codex-art-96a/**`

Hard stop: 60 minutes.
