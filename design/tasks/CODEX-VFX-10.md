# CODEX-VFX-10 · Xion: effects for her kit — shotgun blast, recoil blast, point-blank hit, reload, hologram cast, dive trail, barrage shot, five skill icons (candidates)

- Request: the user (2026-11-18, relayed by the 총괄 session) asked for Xion's effects to be made with Codex and picked in the pick cup (D49). Her kit is in the game (D51, `reports/xion-kit-2026-11-18/README.md`, captures `board.png`). Her own B look is in the game since 2026-11-24 (main `b8594ca5`). Every effect of hers is still drawn by code. **Candidates only**: the user picks, then the lead puts the picks in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-b/SmashNine`, branch `codex/vfx-10`. CODEX-SKM-06 (her body rows) runs at the same time in `vfx-a`; you share no files.

## The kit in short (what each effect is for; details in `design/SKILLS.md`, Xion section)
- **J 산탄 사격:** twin pump shotguns, one shot per press, two a second. The blast reaches about 250 px from her centre, aimed in 45° steps. Today: five thin gold lines fanning 28° and a small star flash (`Xion._play_shotgun_blast`).
- **L 반동 도약:** every round fired down at once and she rises. The blast fills about 140×84 px under her feet. Today: the same lines pointing down.
- **Passive 더블 샷건:** hits from up close deal up to 2x. A hit at 1.6x or more is marked on the struck body. Today: a crimson ring (`Xion._mark_point_blank`).
- **Reload:** with no rounds left she reloads for 3 s. A small mark over her head fills as she reloads. Today: a code arc with a shell (`Xion._update_reload_ring`).
- **U 도플갱어:** the Xion of another timeline appears as a **crimson hologram**. The game draws her figure with `characters/xion/XionDouble.gd`: one crimson tone by brightness, every third screen row darker, a bright band sweeping down, alpha 0.62. U again: Xion dives to her in 0.2 s. Today: a crimson ring when she appears, and a crimson line for the dive.
- **I 이퀄리브리엄:** 2.5 s of shots all round from her and the hologram. Each shot is a small bullet at 900 px/s that lives 0.3 s. Today: a tiny coloured rectangle.

## Read first
- `smash-nine-prototype/scripts/Vfx.gd`: the strip contract (frames in one horizontal strip, fps, anchor, additive).
- READMEs: `smash-nine-prototype/assets/art/effects/README.md`, `smash-nine-prototype/assets/art/skill_icons/README.md`, `smash-nine-prototype/assets/art/ui/README.md` (status icons).
- `characters/xion/Xion.gd` and `XionDouble.gd`: what is drawn today and where.
- **Her look:** `smash-nine-prototype/assets/art/xion/xion_sheet.png` and `art/bakeoff/xion/b/xion-idle-b2.png`. A black bob with a silver streak, a crimson scarf, a short black coat with silver trim, a pump shotgun in each hand.
- **Style references:**
  - `assets/art/effects/skill/rio_rune_burst.png`
  - `assets/art/vfx/rio_ult_impact.png`
  - `assets/art/effects/skill/nova_gravity_burst.png`
  - Luna's star shots: `assets/art/effects/luna_*`
- **Palette:** crimson and deep red, gold-white flashes, a little silver. The hologram items use crimson with dark scan lines, like the double. Use the same pixel density as those files.

## Items (deliver in this order)

| Item | Shows | Contract | Replaces (where the pick goes) | Candidates |
| --- | --- | --- | --- | --- |
| Shotgun blast | The J shot, aimed right. (1) A white-gold flash at the muzzle. (2)–(4) A cone of crimson-gold pellet streaks spreading out to about 230 px, ±14°. (5)–(6) A few wisps fading. | 6 frames, 256×128, 30 fps, no loop. Anchor (8,64) = the muzzle. Additive. 1 art px = 1 screen px. The game rotates it in 45° steps and mirrors it for left. | `assets/art/effects/xion_blast.png` | a, b |
| Recoil blast | The L blast under her feet. (1)–(2) A flat shock ring at her feet. (2)–(5) A cone of pellets and flame pointing down, about 140 px deep and ±70 px wide. (6) Fading. | 6 frames, 192×176, 30 fps, no loop. Anchor (96,16) = her feet. Additive. | `assets/art/effects/skill/xion_recoil_blast.png` | a, b |
| Point-blank hit | The 2x mark on a body hit from up close: a sharp crimson starburst with a bright core and a thin ring. It must be gone in 0.15 s and must not sit on the face. | 5 frames, 112×112, 36 fps, no loop. Anchor (56,56) = the body centre. Additive. | `assets/art/effects/skill/xion_point_blank.png` | a, b |
| Reload mark | Over her head for the 3 s reload: a small shotgun shell in the middle and a ring that fills clockwise in crimson. It must read apart from `ui/status/stun.png`, `super_armor.png`, `slow.png`, `luna_star_mark.png` and `nova_gravity_1..3.png` (look at all of them). | 8 frames, 24×24 each (a 192×24 strip). Frame k is shown at k/8 of the reload. Centre (12,12). Normal blend. | `assets/art/ui/status/xion_reload.png` | a, b |
| Hologram cast | U: where her double appears, crimson hologram scan lines and glitch columns rise and resolve. The figure itself is drawn by the game. | 6 frames, 128×176, 24 fps, no loop. Anchor (64,160) = the feet. Additive. | `assets/art/effects/skill/xion_double_in.png` | a, b |
| Dive trail | U again: a crimson streak with hologram scan lines, fading from the start. The game stretches it along the dive, like `rio_blink_trail`. | 5 frames, 256×48, 31 fps, no loop. Anchor (128,24). Additive. | `assets/art/effects/skill/xion_dive_trail.png` | a, b |
| Barrage shot | One shot of I: a short crimson-gold tracer, the bright head on the right. | 2 frames, 24×8, 20 fps, loop. Anchor (12,4). Additive. The game turns it to its flight. | `assets/art/effects/xion_bullet.png` | a, b |
| Skill icons | HUD icons in the flat pixel style of the others: 2-px clusters, 1-px dark outline, few colours.<br>`xion_j`: two crossed shotguns with a blast.<br>`xion_k`: a curled roll arrow with two shells.<br>`xion_l`: a blast pointing down under an up arrow.<br>`xion_u`: a crimson hologram silhouette of her.<br>`xion_i`: a ring of bullet streaks around a centre. | 40×40 each, one frame, centre (20,20) | `assets/art/skill_icons/xion_{j,k,l,u,i}.png` | one each |

**Draw rules:**
- Transparent background, alpha 0 or 1, nearest filtering.
- The 1-px border of every frame stays empty.
- No text, and no glow halo outside the shape.
- Never upscale.
- Small items (the barrage shot, the reload mark, the icons) are usually better drawn pixel by pixel with Python + Pillow than with image_gen. Choose per item and say which you used.

## Output
- **Strips:** `art/bakeoff/effects/xion/<name>-<a|b>-v1.png` for `xion_blast`, `xion_recoil_blast`, `xion_point_blank`, `xion_double_in`, `xion_dive_trail` and `xion_bullet`.
- **Reload marks:** `art/bakeoff/ui/status/xion_reload-<a|b>-v1.png`.
- **Icons:** `art/bakeoff/skill_icons/xion/<name>-v1.png`.
- **Metadata:** each file has a `.json`: `{"note": "<plain Korean>", "replaces": "<path above>", "frames": N, "fps": F, "anchor": [x, y], "loop": bool}`.
- **Boards** in `reports/codex-vfx-10/`. Draw each item **where the game shows it**, as a composite with her real sprites from `xion_sheet.png`:
  - **Blast:** every frame at 1× and 4×, from the muzzle of her aiming pose (attack row), with a 250-px reach line.
  - **Recoil:** every frame under her jump frame, at 1× and 4×.
  - **Point blank:** every frame over another fighter's body centre (an idle from the sheets), at 1× and 4×.
  - **Reload:** every frame over her head at 1× and 4×, next to the five status icons listed above.
  - **Cast:** every frame at her doppelganger's feet. Make the doppelganger by turning her idle crimson by brightness, darkening every third row, at alpha 0.62.
  - **Dive trail:** stretched between two points 300 px apart, at 1×.
  - **Barrage shot:** twelve shots around her idle in a ring, at 1×.
  - **Icons:** the bar `j k l u i` at 1× and 4×.
- **Overview:** `reports/codex-vfx-10/board.png`, all candidates side by side (A left, B right).
- **README:** `reports/codex-vfx-10/README.md` in Korean, short. Say what each candidate shows, give the measurements (sizes, frames, alpha, border, anchor) and list what a human should judge.
- **Prompts:** `reports/codex-vfx-10/prompts.txt`. Raw generations go in `art/raw/vfx-10/` (git-ignored).
- **Commit script:** `reports/codex-vfx-10/commit.ps1`.
  - Stage only your files and this card.
  - No `git add -f`, nothing under `art/raw/`, no `__pycache__`.
  - No line in a committed text file may end with spaces: the commit check rejects trailing whitespace.

## Writable
- New files only: `art/bakeoff/effects/xion/**`, `art/bakeoff/ui/status/xion_reload-*`, `art/bakeoff/skill_icons/xion/**`, `art/raw/vfx-10/**`, `reports/codex-vfx-10/**`.
- Nothing under `smash-nine-prototype/` changes.
- **Hard stop: 140 minutes.** Deliver in the table order and list the rest.
