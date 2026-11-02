# CODEX-VFX-03 · Frey: effects for her new kit — wings, sword wave, descent light, slow mark, K icon (candidates)

- Request: the user (2026-11-03): Frey's new kit is in the game (D44, `reports/frey-kit-2026-11-03/README.md`, captures `board.png`) with stand-in art; "Codex로 만들기" — make the art. **Candidates only**: the user picks, then the lead puts the picks in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-b/SmashNine`, branch `codex/vfx-03` (from main `d911b52`). SKM-03 (Frey's body rows) runs at the same time in `vfx-a`; you share no files.

## Read first
- `design/SKILLS.md` (Frey section and its "이펙트가 따라야 할 값"), `smash-nine-prototype/characters/frey/Frey.gd` (`_play_wing_spread`, `_sword_wave`, `_dress_wave`, `_show_light`), `smash-nine-prototype/scripts/Vfx.gd` (strip contract: frames in one horizontal strip, fps, anchor, additive), `smash-nine-prototype/assets/art/effects/README.md`.
- Style references: Frey's adopted effects `assets/art/attack_vfx/frey_slash.png`, `frey_k.png`, `frey_l.png`, `assets/art/vfx/frey_ult_charge.png`, `frey_ult_wave.png`; her idle `art/bakeoff/frey/frey-idle-v2.png` and move sheet `assets/art/frey/frey_moves_sheet.png`. Gold, white and a little blue; the same pixel density as those files.

## Items (2 clearly different candidates each, a and b)

| Item | Shows | Contract | Replaces (where the pick goes) |
| --- | --- | --- | --- |
| Wings | golden-white feathered wings opening behind her while she hangs in the air (passive "발키리의 날개"). (1) folded, (2)-(3) opening, (4)-(6) fully spread with a soft feather shimmer. Behind the body: nothing may cover her face or the sword | strip of 6 frames 256×256, 20 fps (0.3 s, one-shot), anchor (128,240) = her feet line, drawn at 2× density like `frey_ult_charge` (displayed at half size: about 170 px wingspan on screen), wing roots at her back about 55 px (screen) above the feet | `smash-nine-prototype/assets/art/effects/skill/frey_wings.png` |
| Sword wave | the K "회오리 검기" projectile: a golden crescent wave flying right, sharp leading edge, trailing sparks; clearly Frey's gold, not Rio's blue mana wave | strip of 4 frames 128×128, 16 fps (loops while it flies), anchor (64,64), crescent about 100 px tall and 60 px thick on screen (displayed at 1×) — the hitbox is 45×96 screen px | `smash-nine-prototype/assets/art/effects/frey_wave.png` |
| Descent light | the I "발키리 강림" light: from a bright core a radiant ring spreads to the light's reach, with soft rays and falling feathers drawn inward (it pulls), the edge brightest at the end. Inside stays light so the fighters stay readable | strip of 6 frames 336×336, 13.3 fps (0.45 s, one-shot), anchor (168,168), displayed at 2× = 672 px diameter (the light's radius is 330 screen px) | `smash-nine-prototype/assets/art/vfx/frey_ult_light.png` |
| Slow mark | the status mark over a slowed fighter (K's 2 s slow), in the style of `assets/art/ui/status/stun.png` and `super_armor.png` (look at both): e.g. a gold hourglass, or heavy downward chevrons | 24×24, one frame | `smash-nine-prototype/assets/art/ui/status/slow.png` |
| K icon | the HUD skill icon for "회오리 검기": a spinning sword arc releasing a crescent wave. The same flat pixel style as the other 23 icons (`assets/art/skill_icons/README.md`, `reports/codex-art-18/`, `reports/codex-vfx-02/`): 2-px clusters, 1-px dark navy outline, few colours | 40×40, one frame, centre (20,20) | `smash-nine-prototype/assets/art/skill_icons/frey_k.png` |

Draw rules: transparent background, alpha 0/1, nearest filtering, 1-px border of every frame empty, no text, no glow halo outside the shape.

## Output
- Strips and stills: `art/bakeoff/effects/frey/<name>-<a|b>-v1.png` for `frey_wings`, `frey_wave`, `frey_ult_light`; `art/bakeoff/ui/status/slow-<a|b>-v1.png`; `art/bakeoff/skill_icons/frey/frey_k-<a|b>-v1.png`. Each with a `.json` `{"note": "<plain Korean>", "replaces": "<path above>", "frames": N, "fps": F, "anchor": [x, y]}`.
- Boards in `reports/codex-vfx-03/`, each item drawn **where the game shows it**:
  - wings: every frame behind Frey's hover pose (her `dash_strike` frame 1, or a `wing_hover` candidate if one exists in `art/bakeoff/frey/`) at 2×, at the anchor;
  - wave: the strip at 1× and 4×, and a frame next to Frey and a 45×96 box for the hitbox;
  - light: every frame at display size (2×) over a dark realm-like background with Frey at the centre and a fighter at 250 px;
  - slow mark: over a fighter's head next to `stun.png` and `super_armor.png`, at 1× and 4×;
  - K icon: the whole 6×4 icon set at 1× and 4× with each candidate in Frey's K slot.
- `reports/codex-vfx-03/README.md` (Korean, short): what each candidate shows, the measurements (sizes, frames, alpha, border, anchor), what a human should judge.
- `reports/codex-vfx-03/prompts.txt`; raw generations in `art/raw/vfx-03/` (git-ignored).
- `reports/codex-vfx-03/commit.ps1`: only your files and this card; no `git add -f`, nothing under `art/raw/`, no `__pycache__`.

## Writable
`art/bakeoff/effects/frey/**`, `art/bakeoff/ui/status/slow-*`, `art/bakeoff/skill_icons/frey/**` (new files only), `art/raw/vfx-03/**`, `reports/codex-vfx-03/**`. Nothing under `smash-nine-prototype/` changes. Hard stop: 120 minutes. Deliver in the table order and list the rest.
