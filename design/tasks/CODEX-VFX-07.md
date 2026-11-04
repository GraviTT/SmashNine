# CODEX-VFX-07 · Frey pilot: J follow-through and hit afterglow in pixelfx (candidate B)

- Request: the user (2026-11-04): "플레이어 캐릭터들의 기본 이펙트들의 pixelfx 스킬을 통한 보강 계획을 진행" → plan agreed with Codex (`reports/debate-pixelfx-basic/decision.md`, D49) → the user: "Frey부터 보강 시작."
- **This is the pilot.** The lead makes candidate A from the same spec, separately; you make candidate B **without looking at A** (do not open `art/bakeoff/effects/pixelfx/frey/a/` or any `sn-frey-*-a*` file). The user then compares now / A / B in the pick cup (`tools/pick_cup/`), and the lead compares the two authors (quality, fixes needed, cost) before splitting later work. **Candidates only**: nothing goes into the game until the pick cup verdict.
- Unit: Builder (pixelfx code + baked strips). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-a/SmashNine`, branch `codex/vfx-07` (from main). No other unit runs.

## Read first
- `reports/debate-pixelfx-basic/decision.md` (the plan and the rules), `reports/pixelfx-eval-2026-11-03/README.md` sections 11–14 (what worked, what the user said), `smash-nine-prototype/assets/art/effects/motion/README.md` (the strip contract of the effects already in the game).
- The example to learn from: `C:/Users/TH/Documents/AI/GameProject/pixelfx/src/fx/melee/sn-frey-slash-sparks.js` (Frey's ground-chain sparks, in the game since 11-04) and its bake in `reports/pixelfx-eval-2026-11-03/motions.mjs` (`bakeAll`, `CUTS`). The pixelfx API: `C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js` and its README/SKILL docs in that repo. **The pixelfx copy is read-only for you.**
- The bench helpers you can import: `reports/pixelfx-eval-2026-11-03/bench.mjs` (`bakeStrip(mod, opts, spec)`, `core`, `art`, `canvas`, `blit`, `drawStrip`, `realm`, `clip`, `savePNG`, `stripFrame`).
- The game side: `design/SKILLS.md` (Frey rows), `smash-nine-prototype/characters/frey/Frey.gd` (`_up_slash`, `_down_cut`, `_air_slash`), `characters/common/PlayerBase.gd` (`_draw_attack_art`: the slash strip at the body centre, turned to the aim, length = reach, 0.62 thick; on the ground a downward trail is shown at most 15° below level; `_spawn_hit_effect`: the 4-frame attacker hit spark `assets/art/effects/hit/frey_hit.png`, 44 fps, size from damage and knockback).
- Frey's look: palette gold/white/warm amber (`#3a2206 #7a4a10 #c08020 #f0c040 #fff0a0 #ffffff`), a sword arc; her sprites `smash-nine-prototype/assets/art/frey/frey_sheet.png`, `frey_moves_sheet.png`.

## Items

**1. J follow-through for the J moves that have none yet** (the ground chain already has sparks). Played at the same moment and place as the slash strip (the hit's active moment, her body centre), drawn facing right with the aim baked in (the game mirrors it for a left-facing Frey and does not rotate it), gravity always down.

| Strip | Move | Aim (facing right) | Slash shown at | Reach | Floor |
| --- | --- | --- | --- | --- | --- |
| `frey_jfx_up-b` | ↑J on the ground | (0.12, -1) | -83° | 155 px | bounce at +32 px (her feet) |
| `frey_jfx_up_air-b` | ↑J in the air | (0.12, -1) | -83° | 155 px | none |
| `frey_jfx_down-b` | ↓J on the ground | (0.3, 1) | +15° (ground rule) | 157 px | bounce at +32 px |
| `frey_jfx_down_air-b` | ↓J in the air | (0.3, 1) | +73° | 157 px | none |
| `frey_jfx_side_air-b` | J in the air | (1, -0.04) | -2° | 186 px | none |

**2. Hit afterglow** for Frey's hits, at the struck body's centre (where the attacker hit spark plays), starting as the 4-frame spark fades (about 0.06–0.09 s) so the two layer: what stays after the impact.

| Strip | When |
| --- | --- |
| `frey_hit_after-b` | a normal hit (most J hits) |
| `frey_hit_after_big-b` | a strong hit (knockback 480 or more: the third chain cut, the spike) |

## Rules (from the user's verdicts and the plan)
- Clearly visible (the user's v2 level: the first test was "too timid"), but the hit afterglow fires the most: small and short (at most 0.5 s; the big one at most 0.7 s). Follow-through at most 1.0 s.
- Visible from its first frame (no empty lead-in; the step dust peaked 0.2 s late and the user noticed).
- Frey's motion, not colour-swapped sparks: a sword's arc, gold steel sparks, glints along the cut.
- Never hide the body: keep the struck body's middle (about 40×60 px round the anchor) light.
- 1 art px = 1 screen px; additive strips: colour and light premultiplied into RGB, alpha 0/255, drop light under 40 (`bakeStrip(..., {additive: true, minLight: 40})`); 1-px empty border on every frame.
- No change to hit areas, damage, timing or hitstop: these are pictures only.

## How
- Write each effect as an ES module in `art/bakeoff/effects/pixelfx/frey/b/src/sn-frey-<name>-b.js` (same shape as the pixelfx effects: `export const meta`, `create(o)` or `draw(p, t, o)`), importing pixelfx by absolute URL (`file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js`).
- Bake with your own `art/bakeoff/effects/pixelfx/frey/b/bake.mjs` (import `bakeStrip` from the bench) into `art/bakeoff/effects/pixelfx/frey/b/<strip>.png` + `.json` `{"note": "<plain Korean>", "frames": N, "fps": F, "anchor": [x, y], "blend": "add", "attach": "<when and where>", "source": "<module path>"}`; fps 20 unless the timing needs otherwise.
- Check them on Frey with the bench (her real cells, the slash strip at its game size and angle, a struck fighter's cell for the hits), at 1x and 4x, every frame.

## Output
- The strips and json above, the modules, `bake.mjs`.
- `reports/codex-vfx-07/`: `board.png` (each strip on Frey at game timing, 1x and 4x, a few key frames), `README.md` (Korean, short: what each strip shows, measured duration / first visible frame / peak frame / size, anything you could not meet), `commit.ps1` (only your files and this card; no `git add -f`; no line ending in spaces, no blank lines at the end of committed text files).

## Writable
`art/bakeoff/effects/pixelfx/frey/b/**`, `reports/codex-vfx-07/**`. Nothing under `smash-nine-prototype/` or the pixelfx copy changes. Hard stop: 90 minutes.
