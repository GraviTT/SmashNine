# CODEX-VFX-04 · Luna: effects for her new kit — star barrier, cyclone, warp burst, star shots, star mark, skill icons (candidates)

- Request: the user (2026-11-03, night routine `routine/2026-11-03-night/README.md`, the concept is quoted there): Luna gets a new kit "the same way as Frey" — in the game first with stand-in art, then Codex makes the art. **Candidates only**: the user picks, then the lead puts the picks in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-b/SmashNine`, branch `codex/vfx-04` (from main `47f5334c`). SKM-04 (Luna's body rows) runs at the same time in `vfx-a`; you share no files.

## The kit in short (what each effect is for)
- Normal J **별빛 연사 (Star Volley)**: three small magic stars one after another, then a big star that explodes. A fighter hit gets a **star mark** for 10 s; marked fighters take 10% more damage (passive **별의 마법**).
- Normal K **반짝 도약 (Twinkle Warp)**: she vanishes and reappears a short way off; a **star burst** around her at the arrival hits whoever is close.
- Normal L **별의 방어막 (Star Barrier)**: a round **shield** around her for 5 s: it stops projectiles, nudges away foes who touch it, and breaks after taking enough damage.
- Brave L **별의 회오리 (Star Cyclone)**: Brave Luna spins inside a **magic whirlwind** for up to 3 s (it stops projectiles), then the whirlwind flies forward; whoever it hits is stunned, then thrown upward.
- Brave K **혜성 붙잡기 (Comet Catch)**: dash, grab, throw. Brave J **브레이브 러시**: short dash then a punch or kick.

## Read first
- `smash-nine-prototype/scripts/Vfx.gd` (strip contract: frames in one horizontal strip, fps, anchor, additive), `smash-nine-prototype/assets/art/effects/README.md`, `smash-nine-prototype/assets/art/skill_icons/README.md`.
- Style references (Luna's adopted effects): `assets/art/effects/skill/luna_star_bloom.png`, `luna_moon_ring.png`, `luna_comet_burst.png`, `luna_brave_aura.png`, `assets/art/effects/luna_star.png`, `assets/art/vfx/luna_ult_transform.png`; her idles `art/bakeoff/luna/luna-idle-v3.png` and `art/bakeoff/luna/luna_brave-idle-v4.png`. Pink, pale cyan and gold with white sparkles; the same pixel density as those files.

## Items (deliver in this order)

| Item | Shows | Contract | Replaces (where the pick goes) | Candidates |
| --- | --- | --- | --- | --- |
| Star barrier | a round shimmering shield around normal Luna: a thin bright rim of pale cyan and pink with small gold stars riding on it and a faint inner film; inside almost clear so she stays readable. And its **break**: the shield shattering into star shards flying outward | `luna_barrier`: 6 frames 256×256, 10 fps **loop**, anchor (128,128) = her body centre (34 px above her feet), additive; the rim's diameter 210 px at 1× (radius 105 = the barrier's reach on screen). `luna_barrier_break`: 6 frames 256×256, 24 fps one-shot, anchor (128,128) | `assets/art/effects/skill/luna_barrier.png`, `assets/art/effects/skill/luna_barrier_break.png` | a, b |
| Cyclone | Brave Luna's magic whirlwind: a vertical swirl of pink-gold wind ribbons with sparkles, open in the middle so she shows inside it | 6 frames 192×192, 20 fps **loop**, anchor (96,96), additive. One strip used twice: around her while she spins (1.25×: about 240 px tall, centred on her body centre) and as the fired whirlwind (1×: its hit box is 105×150 screen px) | `assets/art/effects/skill/luna_cyclone.png` | a, b |
| Warp burst | the arrival of 반짝 도약: a ring of light and star sparkles bursting out from her body; it *is* the hit, 195×165 screen px around her body centre | 6 frames 256×256, 24 fps one-shot, anchor (128,128), additive, displayed 1× | `assets/art/effects/skill/luna_warp.png` | a, b |
| Star shots | the J stars flying right: `luna_star_shot` a small spinning magic star with a short sparkle tail behind it; `luna_star_big` the last, big star, brighter, with a bigger tail (its explosion keeps today's `luna_comet_burst`) | `luna_star_shot`: 4 frames 48×48, 16 fps loop, anchor (24,24), 1× (hit box 33×33). `luna_star_big`: 4 frames 96×96, 16 fps loop, anchor (48,48), 1× (hit box 60×60) | `assets/art/effects/luna_star_shot.png`, `assets/art/effects/luna_star_big.png` | one each |
| Star mark | the status mark over a fighter marked by her stars: e.g. a small pink-gold star inside a thin target ring; it must read apart from `ui/status/stun.png`, `super_armor.png` and `luna_star_charge.png` (look at all three) | 24×24, one frame | `assets/art/ui/status/luna_star_mark.png` | one |
| Skill icons | the HUD icons in the flat pixel style of the other icons (2-px clusters, 1-px dark navy outline, few colours): `luna_j` small stars and a big star flying; `luna_k` a sparkle burst at the end of a dotted jump arc; `luna_l` a round star shield; `luna_brave_k` a gauntlet gripping with a throw arrow; `luna_brave_l` a whirlwind | 40×40 each, one frame, centre (20,20) | `assets/art/skill_icons/<name>.png` | one each |

Draw rules: transparent background, alpha 0/1, nearest filtering, 1-px border of every frame empty, no text, no glow halo outside the shape. Never upscale.

## Output
- Strips and stills: `art/bakeoff/effects/luna/<name>-<a|b>-v1.png` (or `<name>-v1.png` when one candidate), `art/bakeoff/ui/status/luna_star_mark-v1.png`, `art/bakeoff/skill_icons/luna/<name>-v1.png`. Each with a `.json` `{"note": "<plain Korean>", "replaces": "<path above>", "frames": N, "fps": F, "anchor": [x, y], "loop": bool}`.
- Boards in `reports/codex-vfx-04/`, each item drawn **where the game shows it** (real sprites from the sheets, composites):
  - barrier: every frame around Luna's idle at 1× and 2×, the 105-px reach circle drawn thin; the break strip too; and one frame over a dark realm-like background;
  - cyclone: every frame around Brave Luna's idle at 1.25×, and at 1× flying right beside a 105×150 box;
  - warp burst: every frame around Luna's idle with a 195×165 box centred on her body centre;
  - star shots: the strips at 1× and 4×, next to Luna with the 33×33 and 60×60 boxes;
  - star mark: over a fighter's head next to `stun.png` and `super_armor.png`, at 1× and 4×;
  - icons: the whole icon set at 1× and 4× with each new icon in its slot.
- `reports/codex-vfx-04/board.png`: one overview of all candidates side by side (A left, B right).
- `reports/codex-vfx-04/README.md` (Korean, short): what each candidate shows, the measurements (sizes, frames, alpha, border, anchor), what a human should judge.
- `reports/codex-vfx-04/prompts.txt`; raw generations in `art/raw/vfx-04/` (git-ignored).
- `reports/codex-vfx-04/commit.ps1`: only your files and this card; no `git add -f`, nothing under `art/raw/`, no `__pycache__`. No line in a committed text file may end with spaces (the commit check rejects trailing whitespace).

## Writable
`art/bakeoff/effects/luna/**`, `art/bakeoff/ui/status/luna_star_mark-*`, `art/bakeoff/skill_icons/luna/**` (new files only), `art/raw/vfx-04/**`, `reports/codex-vfx-04/**`. Nothing under `smash-nine-prototype/` changes. Hard stop: 95 minutes. Deliver in the table order and list the rest.
