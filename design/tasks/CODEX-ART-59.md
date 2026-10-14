# CODEX-ART-59 · 8-frame walks for Brave Luna, Yuki, Nova male and Nova female (the method that worked for Frey and Luna)

- Request: 사용자 2026-10-15 "일단 전보다는 나으니...일단 이렇게 하는 것으로 채택. 다른 캐릭터들도 진행하고… 단, 이번처럼 여러번 실패로 쓸데없는 컨텍스트 낭비는 하지 말고 성공한 사례만 따라갈것."
- The user adopted Frey `frey-walk-v6` and Luna `luna-walk-v5`. Do exactly what made them, in one pass per character. **Do not try other methods.**

| Unit | Branch | Clone | Characters, in order |
| --- | --- | --- | --- |
| A | `codex/walk-59a` | `SmashNine-units/builder-frey/SmashNine` | Brave Luna (`luna_brave`), then Yuki |
| B | `codex/walk-59b` | `SmashNine-units/builder-art/SmashNine` | Nova male (`nova_male`), then Nova female (`nova_female`) |

## Inputs per character

| Stem | Idle anchor (Image 1) | In-game walk (Image 4, legs together) | Output |
| --- | --- | --- | --- |
| `luna_brave` | `art/bakeoff/luna/luna_brave-idle-v4.png` | `art/bakeoff/luna/luna_brave-walk-v1.png` | `art/bakeoff/luna/luna_brave-walk-v2.png` |
| `yuki` | `art/bakeoff/yuki/yuki-idle-v2.png` | `art/bakeoff/yuki/yuki-walk-v1.png` | `art/bakeoff/yuki/yuki-walk-v2.png` |
| `nova_male` | `art/bakeoff/nova/nova_male-idle-v2.png` | `art/bakeoff/nova/nova_male-walk-v1.png` | `art/bakeoff/nova/nova_male-walk-v2.png` |
| `nova_female` | `art/bakeoff/nova/nova_female-idle-v2.png` | `art/bakeoff/nova/nova_female-walk-v1.png` | `art/bakeoff/nova/nova_female-walk-v2.png` |

## The method (ART-57 + ART-58; read both cards and `reports/codex-art-57/` + `reports/codex-art-58/`)
1. **Grey mannequin.**
   - Run ART-57's `make_walk_reference.py` with the character's proportions (head count as in its idle).
   - Near limbs light grey, far limbs dark grey, no hue.
   - Arms the way the character holds its prop in the idle: a held prop stays steady, and a free arm swings opposite the legs.
2. **Write the costume words from the idle** (Image 1) before generating:
   - boots, legs, outfit
   - the prop and how it is held
   - hair
   
   They go into every prompt. Say "Image 2 is only a pose guide; its greys are not clothing."
3. **Frame 1 first.**
   - Image 1 = idle frame 0 at 4× nearest; Image 2 = mannequin panel 1; Image 3 = in-game walk frame 0 at 4× nearest.
   - Accept it only when the costume matches the idle on a 4× board.
4. **Frames 2, 4, 5, 6, 8.** Image 3 = the accepted frame 1 for every frame. Never use the neighbour as Image 3.
5. **Frames 3 and 7, the passing pose.**
   - Images 1–3 as above, plus Image 4 = an in-game walk frame with the legs together. Choose it with `walk_feet.py`: the frame with one planted run near the centre.
   - Words (ART-58):
     - The standing leg is straight and vertical, its foot flat directly under the hips.
     - The swinging leg's knee is bent, its foot lifted 6–12 px right beside the standing ankle.
     - The two feet are almost at the same x; the lifted foot is not in front of the body.
     - Frame 3 stands on the near leg, frame 7 on the far leg.
6. **Normalise each generation.**
   - `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00 --ground-all`
   - One factor per generation, matched to the anchor head with `head_scale.py`, 0.96–1.04. When scores are below 0.6, use 4× head crops.
7. **Bob.** Assemble the 8 frames and run `tools/sprite_pipeline/walk_bob.py` once. Every shift must be within ±3 px.

## Acceptance (measure, then one 4× look)
- **Feet** (`walk_feet.py`):
  - Frames 3 and 7 have exactly one planted foot. Its centre is within ±6 px of the midpoint between the standing foot of frame 2 (or 6) and the rear foot of frame 4 (or 8).
  - On the onion board, no foot moves more than 25 px between two frames.
- **Costume board** against the idle: boots, legs, outfit, prop and hair match in all 8 frames.
- **Legs:** frames 1 and 5 lead with different legs; 3 and 7 lift the swinging leg.
- **Cleanup:**
  - border clear, 4 px margin, spill 0
  - detail at least 90 % of the idle anchor's (`normalize.py` metrics)
- **Retries:** up to 3 generations per frame. If a character still fails after that, stop it. Report the best attempt, deliver nothing for it, and go to the next character. **Do not start a second round.**

## Output per character
- The strip in the table: 1024×128, 8 cells.
- `.json` beside it, in the format of `art/bakeoff/frey/frey-walk-v6.json`: a plain Korean note, `"fps": 13.3`, `"frames": 8`.
- Raw generations go to `art/raw/walk-59/<stem>/`.
- `reports/codex-art-59/<stem>/`:
  - `costume.png`, `onion.png`, `feet.json`, `bob.png`, `bob.json`, `walk.gif`
  - `prompts.txt`, `README.md` (Korean, short)
- One `reports/codex-art-59/commit-<a|b>.ps1` per unit: no `git add -f`, nothing under `art/raw/`, no `__pycache__`.

## Writable
- **Unit A:**
  - `art/bakeoff/luna/luna_brave-walk-v2.*`, `art/bakeoff/yuki/yuki-walk-v2.*`
  - `art/raw/walk-59/{luna_brave,yuki}/**`
  - `reports/codex-art-59/{luna_brave,yuki}/**`, `reports/codex-art-59/commit-a.ps1`
- **Unit B:**
  - `art/bakeoff/nova/nova_male-walk-v2.*`, `art/bakeoff/nova/nova_female-walk-v2.*`
  - `art/raw/walk-59/{nova_male,nova_female}/**`
  - `reports/codex-art-59/{nova_male,nova_female}/**`, `reports/codex-art-59/commit-b.ps1`

Hard stop: 90 minutes per unit.
