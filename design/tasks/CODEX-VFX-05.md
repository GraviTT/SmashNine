# CODEX-VFX-05 · Nova: effects for her new kit — gravity stacks, orb, field, beam, sphere, five skill icons (candidates)

- Request: the user (2026-11-03): Nova's new kit is in the game (D47, `reports/nova-kit-2026-11-03/README.md`, captures `board.png`) with stand-in art; "Codex로 만들기" — make the art. **Candidates only**: the user picks, then the lead puts the picks in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-b/SmashNine`, branch `codex/vfx-05` (from main `e5df3cc1`). SKM-05 (Nova's body rows) runs at the same time in `vfx-a`; you share no files.

## The kit in short (what each effect is for; details in `design/SKILLS.md`, Nova section)
- Passive **중력 중첩 (Gravity Stacks):** her hits stack gravity on a foe, stage 1 to 3 (slower walk, lower jumps); stage 3 **roots** the foe in place for 2 s. Today: three code pips over the head and a code ring at the feet.
- K **중력 구체 (Gravity Orb):** a small orb flies ahead and bursts (the burst keeps today's `nova_gravity_burst`), pulling foes in.
- L **중력 필드 (Gravity Field):** a big round field (radius 300 px) for 6 s; inside it Nova flies, foes are slowed and monsters float.
- U **중력 광선 (Gravity Beam):** a beam from her palm with a tether; it drags a foe to her or slams one down.
- I **사건의 지평선 (Event Horizon):** a giant gravity sphere above her head; foes circle it at 112 px from its centre, then it drops and bursts (the burst keeps today's `nova_ult_burst`).

## Read first
- `smash-nine-prototype/scripts/Vfx.gd` (strip contract: frames in one horizontal strip, fps, anchor, additive), `smash-nine-prototype/assets/art/effects/README.md`, `smash-nine-prototype/assets/art/skill_icons/README.md`, `smash-nine-prototype/assets/art/ui/README.md` (status icons).
- Style references (Nova's adopted effects): `assets/art/effects/skill/nova_gravity_burst.png`, `assets/art/vfx/nova_ult_core.png`, `assets/art/vfx/nova_ult_burst.png`, `assets/art/effects/skill/nova_impact_star.png`; her idles `art/bakeoff/nova/nova_male-idle-v2.png` and `nova_female-idle-v2.png`. Palette: midnight indigo, violet, electric teal-cyan, white sparks, a little gold. The same pixel density as those files.

## Items (deliver in this order)

| Item | Shows | Contract | Replaces (where the pick goes) | Candidates |
| --- | --- | --- | --- | --- |
| Gravity stacks | a status mark over a stacked foe, one per stage: the same symbol filling up (e.g. a violet orbit ring with 1, 2, 3 bright satellites, or a gravity well that deepens); stage 3 the strongest. It must read apart from `ui/status/stun.png`, `super_armor.png`, `slow.png` (gold hourglass) and `luna_star_mark.png` (look at all four). And the **root ring** at a rooted foe's feet: a flat violet ring of gravity rings or chains around the feet | stages: three files 24×24, one frame each, centre (12,12). Root: 6 frames 96×32, 10 fps **loop**, anchor (48,16) = the feet, additive | `assets/art/ui/status/nova_gravity_{1,2,3}.png`, `assets/art/effects/skill/nova_gravity_root.png` | a, b (each a full set: three stages + root) |
| Gravity orb | the K orb flying right: a small dark sphere with a bright violet-cyan rim and particles spiralling into it | 4 frames 64×64, 16 fps **loop**, anchor (32,32), additive, shown 1× (hit box 45×45) | `assets/art/effects/nova_orb.png` | a, b |
| Gravity field | the L field: a thin bright rim at radius 300 with slow orbiting rings or glyph arcs riding on it, the inside only a faint violet haze (fighters inside must stay fully readable) | 6 frames 640×640, 8 fps **loop**, anchor (320,320), additive, drawn 1 art px = 1 screen px (rim radius 300) | `assets/art/effects/skill/nova_field.png` | a, b |
| Gravity beam | the U beam: a small bright violet-white **head** (a hook or star point aiming right) and a **tether tile**, a thin violet energy band with a bright core line that repeats seamlessly left to right | head: 4 frames 48×48, 16 fps loop, anchor (24,24), additive. Tile: one frame 64×16, seamless horizontally, additive; the game stretches it along a line from her hand to the head (up to about 620 px) | `assets/art/effects/nova_beam_head.png`, `assets/art/effects/nova_beam_tile.png` | a, b |
| Event horizon sphere | the I sphere: a black core about 110 px across with a violet-cyan accretion ring spinning round it (out to about 150 px from the centre) and small debris | 6 frames 320×320, 12 fps **loop**, anchor (160,160), **normal blend** (the core is black), shown 1× and drawn **behind** the fighters (foes circle at 112 px from the centre and must stay visible) | `assets/art/vfx/nova_sphere.png` | a, b |
| Skill icons | the HUD icons in the flat pixel style of the others (2-px clusters, 1-px dark navy outline, few colours): `nova_j` three quick punches with a short streak; `nova_k` a dark orb with an inward spiral; `nova_l` a round field dome with a small figure floating in it; `nova_u` a beam with a hook pulling back (a small arrow toward the caster); `nova_i` a big black sphere with orbiting dots | 40×40 each, one frame, centre (20,20) | `assets/art/skill_icons/nova_{j,k,l,u,i}.png` (`nova_u` is new) | one each |

Draw rules: transparent background, alpha 0/1, nearest filtering, 1-px border of every frame empty (the tile's left and right edges excepted: it must tile), no text, no glow halo outside the shape. Never upscale.

## Output
- Strips and stills: `art/bakeoff/effects/nova/<name>-<a|b>-v1.png` for `nova_gravity_root`, `nova_orb`, `nova_field`, `nova_beam_head`, `nova_beam_tile`, `nova_sphere`; `art/bakeoff/ui/status/nova_gravity_{1,2,3}-<a|b>-v1.png`; `art/bakeoff/skill_icons/nova/<name>-v1.png`. Each with a `.json` `{"note": "<plain Korean>", "replaces": "<path above>", "frames": N, "fps": F, "anchor": [x, y], "loop": bool}`.
- Boards in `reports/codex-vfx-05/`, each item drawn **where the game shows it** (real sprites from the sheets, composites):
  - stacks: each stage over a fighter's head next to `stun.png`, `super_armor.png`, `slow.png` and `luna_star_mark.png`, at 1× and 4×; the root ring at an idle fighter's feet, every frame, at 1× and 4×;
  - orb: the strip at 1× and 4×, next to Nova with a 45×45 box;
  - field: one frame at 1× around Nova's idle with another fighter inside it and the 300-px circle drawn thin, over a dark realm-like background; and the rim at 4×;
  - beam: the head with the tile repeated over 300 px from Nova's hand, at 1×, and the tile repeated three times at 4× to show the seam;
  - sphere: every frame at 1× with two fighters' idles at 112 px from the centre, drawn in front of it, and Nova's idle below;
  - icons: the whole icon set at 1× and 4× with each new icon in its slot (`nova_u` as a fifth Nova slot between L and I).
- `reports/codex-vfx-05/board.png`: one overview of all candidates side by side (A left, B right).
- `reports/codex-vfx-05/README.md` (Korean, short): what each candidate shows, the measurements (sizes, frames, alpha, border, anchor, seams), what a human should judge.
- `reports/codex-vfx-05/prompts.txt`; raw generations in `art/raw/vfx-05/` (git-ignored).
- `reports/codex-vfx-05/commit.ps1`: only your files and this card; no `git add -f`, nothing under `art/raw/`, no `__pycache__`. No line in a committed text file may end with spaces (the commit check rejects trailing whitespace).

## Writable
`art/bakeoff/effects/nova/**`, `art/bakeoff/ui/status/nova_gravity_*`, `art/bakeoff/skill_icons/nova/**` (new files only), `art/raw/vfx-05/**`, `reports/codex-vfx-05/**`. Nothing under `smash-nine-prototype/` changes. Hard stop: 110 minutes. Deliver in the table order and list the rest.
