# CODEX-ART-66 · Basic-attack (J) effects redrawn to the new sprites' level, every character

- Request: 사용자 2026-10-15 "일단 기본 공격부터 진행." Effect work starts with the basic attacks (`design/SKILLS.md`, "이펙트 스프라이트 작업 목록", item 1).
- Unit: branch `codex/art-66`, clone `SmashNine-units/builder-art/SmashNine`. A tool unit (TOOL-01, game clips with effects on/off) runs in `builder-ui`; you share nothing. **Candidates only**; nothing under `smash-nine-prototype/` changes.

## Why
Every character was redrawn on 2026-10-13~15 at a higher detail level (D33–D37): 6-frame motions, 192-px move cells, LANCZOS + sharpen, and their own palettes. The J effects date from 2026-10-08~10 (ART-16/20/28) and were drawn against the old sprites. They must now look like the same game as the new bodies.

## The files (keep each file's contract)
Every new file has exactly the current file's size, frame count, frame size, anchor and playback, so the game code does not change. Read the contracts in `assets/art/effects/README.md` and `assets/art/attack_vfx/` (and the code that draws them; `design/SKILLS.md` names the functions).

| Character | Files used by J moves |
| --- | --- |
| Frey | `attack_vfx/frey_slash.png` |
| Luna | `attack_vfx/luna_slash.png`, `effects/skill/luna_star_bloom.png` |
| Brave Luna | `attack_vfx/luna_brave_slash.png` (the star bloom is shared with Luna) |
| Yuki | `effects/yuki_talisman.png`, `attack_vfx/yuki_slash.png`, `attack_vfx/yuki_l.png` (the ↑J and air ↓J burst; L uses it too) |
| Nova | `attack_vfx/nova_slash.png`, `effects/skill/nova_vector_streak.png`, `effects/skill/nova_impact_star.png`, `effects/skill/nova_gravity_burst.png` (↓J and meteor landing; L uses it too) |
| Rio | `attack_vfx/rio_slash.png`, `effects/rio_mana_wave.png` |

## How
- **Style anchor:** the character's new sprites. Use its idle frame 0 and the J rows (`attack_chain`, `attack_up`, … from the sheets in `smash-nine-prototype/assets/art/<id>/`) at 4× nearest as Image 1, for palette, outline weight and rendering detail.
- **Shape and timing reference:** the current effect file at 4× nearest as Image 2. Keep its silhouette idea, frame order and timing unless `design/SKILLS.md` says the move does something else.
- **Each effect must follow its row's "이펙트가 따라야 할 값"** in `design/SKILLS.md`: hitbox size and path, direction, active time, colour.
- **Draw rules:**
  - transparent background, hard alpha 0/1, nearest filtering
  - no text, no background, no glow halo outside the shape
  - the effect is drawn separately from the body (D32 ③)
- **Normalise to the contract:** use your own script, recorded in the report. Check every frame:
  - size and frame grid exact
  - anchor pixel where the contract says
  - alpha binary, no 1-px fringe
  - 1-px border clear

## Review boards (for the lead and the user)
For every file, write `reports/codex-art-66/<id>/<file>-compare.png` with:
- the current file over the J frame where the game shows it, 4×
- the new file the same way
- each frame of both strips side by side

Place the effect on the body frame where the code places it: origin, offset, rotation and scale from the drawing function.

## Output
- `art/bakeoff/effects/<id>/<file stem>-v1.png`, with a `.json` `{"note": "<plain Korean>", "replaces": "<asset path>", "frames": N, "fps": F}`
- `reports/codex-art-66/<id>/*-compare.png`, `prompts.txt`
- `reports/codex-art-66/README.md` (Korean, short)
- `reports/codex-art-66/commit.ps1`: no `git add -f`, nothing under `art/raw/`, no `__pycache__`
- Raw generations go to `art/raw/fx-66/` (git-ignored)

## Writable
`art/bakeoff/effects/**`, `art/raw/fx-66/**`, `reports/codex-art-66/**`. Hard stop: 120 minutes. Deliver finished characters in the table order and list the rest.
