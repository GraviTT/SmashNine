# CODEX-VFX-09 · Luna's steps and jumps, Brave Luna's J follow-through and hit afterglow in pixelfx (candidates A and B)

- Request and setup: the same as `design/tasks/CODEX-VFX-08.md` (read it first: the two letters, the blindness, the rules, the output shape). This is the second card of the 2026-11-05 night routine; you are the same letter as on VFX-08 and keep the same direction:
  - **A, "the sharp moment"**: the instant of contact reads crisp and bright, short.
  - **B, "the directional linger"**: what stays follows the motion's direction, softer and longer.
- Your own VFX-08 work is a good start for the look; the other letter's is off limits.

## Items (strip names end in `-a` or `-b`)

**Luna** (folder `art/bakeoff/effects/pixelfx/luna/<letter>/`; pink, violet, gold and white stars and stardust)

| Strip | When and where | Notes |
| --- | --- | --- |
| `luna_step` | while she runs, on the walk drawings where the front foot lands (the 4th and 8th of 8), at that foot (17 and 18 px ahead of her feet), once per step | The game plays it over exactly one step (4 walk drawings, 0.35 s), whatever its own length: make it read in that time, visible from the first frame. Drawn facing right; it trails behind (toward −x) |
| `luna_jump` | she leaves the floor with a jump: at her feet | facing right |
| `luna_air_jump` | her air jump: at her feet, in the air | facing right |

**Brave Luna** (folder `art/bakeoff/effects/pixelfx/luna_brave/<letter>/`; her look: `smash-nine-prototype/assets/art/luna/luna_brave_sheet.png`, her strike art `assets/art/attack_vfx/luna_brave_slash.png`, her hit spark `assets/art/effects/hit/luna_brave_hit.png`; a brawler: punches and kicks, star bursts, pink and gold)

The follow-through plays where and when her strike strip (`luna_brave_slash`) starts: her body centre (32 px above her feet), drawn facing right with the strike's angle drawn in (the game mirrors it and never turns it), gravity down, no floor bounce.

| Strip | Move | Shown at | Reach |
| --- | --- | --- | --- |
| `brave_rush_1` | J rush, hit 1: jab | −1° | 131 px |
| `brave_rush_2` | J rush, hit 2: body kick | −3° | 147 px |
| `brave_rush_3` | J rush, hit 3: spinning kick, launches (strong) | −22° | 157 px |
| `brave_up` | ↑J uppercut, launches (ground or air) | −83° | 156 px |
| `brave_low` | ↓J low sweep (at her feet level) | −3° | 157 px |
| `brave_side_air` | air J flying kick | −5° | 170 px |
| `brave_down_air` | air ↓J dive kick | +81° | 206 px |

| Strip | When |
| --- | --- |
| `brave_hit_after` | a Brave melee hit lands: at the struck body's centre (where her hit spark plays), once per hit |
| `brave_hit_after_big` | a strong hit (base knockback 400 or more: the spinning kick 520, the uppercut 430, the dive kick 475) |

## Rules
All of CODEX-VFX-08's rules apply (visible from the first frame, the user's v2 strength, nothing round the head and face, never hide the body, 1 art px = 1 screen px, additive strips premultiplied with alpha 0/255 and light under 40 dropped, normal strips may be translucent, a 1-px empty border, avoid the option names `x` `y` `flip` `angle`, **save every text file as UTF-8**, pictures only).

## Output
- Strips, json, modules and bake scripts in your letter's folders above (json as in VFX-08).
- `reports/codex-vfx-09-<letter>/`: `board.png` (each strip on the real sprites at game timing, 1x and 4x), `README.md` (Korean, short, the same measurements as VFX-08), `commit.ps1` (only your files and this card).

## Writable
`art/bakeoff/effects/pixelfx/luna/<your letter>/**`, `art/bakeoff/effects/pixelfx/luna_brave/<your letter>/**`, `reports/codex-vfx-09-<your letter>/**`. Nothing under `smash-nine-prototype/` or the pixelfx copy changes. Hard stop: 50 minutes.
