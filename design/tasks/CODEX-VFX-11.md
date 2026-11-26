# CODEX-VFX-11 · Rio: effects for kit v3 — mana sword (flying, stuck), backstab mark, shadow blink, counter stance, decoy burst, five skill icons (candidates)

- Request: the user (2026-11-27, "지금 시작"; the 총괄 session recommended starting Rio's art after Xion's) asked for Rio's kit v3 art, made with Codex and picked in the pick cup (D49). The kit is in the game (D50, `reports/rio-kit-2026-11-18/README.md`). Its new effects are stand-ins: a tinted gem sword, code lines and a borrowed rune burst. **Candidates only**: the user picks, then the lead puts the picks in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-b/SmashNine`, branch `codex/vfx-11`. CODEX-SKM-08 (his body rows) runs at the same time in `vfx-a`; you share no files.

## The kit in short (details in `design/SKILLS.md`, Rio section)
- **K 마검 투척:** he throws a mana sword. It flies about 420 px in 0.4 s and sticks in the first foe, a wall or the floor, or stops where its flight ends. It waits there up to 3 s (in a foe it rides on him); K again blinks Rio to it. Today: the gem sword picture `assets/art/effects/rio_gem_sword.png` tinted sky blue (`characters/rio/RioSword.gd`).
- **Passive 급소:** a hit from behind a foe deals 1.5x and marks the struck body. Today: a blue code X that grows and fades in 0.32 s (`Rio._mark_backstab`).
- **Blinks:** K again, the L counter and I again make him vanish and reappear behind a foe. Today: `skill/rio_blink_trail.png` along the path, nothing where he vanishes or appears.
- **L 그림자 받아치기:** a 0.4 s stance that takes the first hit. Today: his drawing tinted shadow blue inside a code hexagon about 96 px across around his body (`Rio._show_stance`).
- **U 분신 바꿔치기:** he leaves a decoy (his frame, blue and see-through; the game keeps drawing it) and steps back. A foe's hit bursts the decoy, which knocks foes around it upward. Today: `skill/rio_rune_burst.png` at 0.6 scale.

## Read first
- `smash-nine-prototype/scripts/Vfx.gd`: the strip contract (frames in one horizontal strip, fps, anchor, additive).
- READMEs: `smash-nine-prototype/assets/art/effects/README.md`, `smash-nine-prototype/assets/art/skill_icons/README.md`.
- `characters/rio/Rio.gd`, `RioSword.gd`, `RioDecoy.gd`: what is drawn today and where.
- **His look:** `smash-nine-prototype/assets/art/rio/rio_male_sheet.png`, `rio_female_sheet.png`, `rio_{male,female}_moves_sheet.png`. Navy academy coat with teal panels and silver trim, a cyan diamond emblem, a slim silver sword with a cyan crystal guard.
- **Style references (his existing effects):** `assets/art/effects/skill/rio_blink_trail.png`, `skill/rio_rune_burst.png`, `skill/rio_air_step.png`, `assets/art/vfx/rio_ult_impact.png`, `assets/art/effects/rio_gem_sword.png`, `assets/art/attack_vfx/rio_slash.png`.
- **Palette:** cyan mana (`#39D8FF`), white-cyan highlights, teal, navy and shadow blue (`#4A5CFF` at most), silver. Same pixel density as those files.

## Items (deliver in this order)

| Item | Shows | Contract | Replaces (where the pick goes) | Candidates |
| --- | --- | --- | --- | --- |
| Mana sword | **Two strips per candidate.** *Flying:* a slim mana blade pointing right (+x), cyan crystal with a silver edge, a short streak behind it; a shimmer over the frames. *Stuck:* the same blade at rest, pulsing softly with a few small rune sparks, so it reads as "waiting" for up to 3 s. | Flying: 4 frames, 96×32, 20 fps, loop. Stuck: 4 frames, 96×32, 8 fps, loop. Anchor (48,16) for both. Additive or normal: say which. The game turns it to its flight and mirrors it for left. | `assets/art/effects/rio_mana_sword.png`, `assets/art/effects/rio_mana_sword_stuck.png` | a, b |
| Backstab mark | The 1.5x mark on a body hit from behind: a sharp cyan X cut with a bright core and a short flash. It must be gone in about 0.15 s and must not sit on the face. | 5 frames, 96×96, 36 fps, no loop. Anchor (48,48) = the struck body's centre. Additive. | `assets/art/effects/skill/rio_backstab.png` | a, b |
| Shadow blink | Where he vanishes and where he reappears (the same strip at both places): a burst of shadow-blue wisps and cyan slivers around a body-sized space, closing in or tearing open. Nothing of his figure is drawn. | 6 frames, 128×160, 30 fps, no loop. Anchor (64,144) = his feet. Additive or normal: say which. | `assets/art/effects/skill/rio_shadow_blink.png` | a, b |
| Counter stance | Around his body for the 0.4 s stance: a dark shadow-blue aura with a faint hexagonal rune ring about 96 px across, centred on his body. The game keeps tinting his figure shadow blue. | 6 frames, 192×192, 15 fps, loop. Anchor (96,152) = his feet (his body centre is about 50 px above them). Say the blend. | `assets/art/effects/skill/rio_counter_stance.png` | a, b |
| Decoy burst | His decoy pops when a foe hits it: shards of blue see-through glass flying up and out, a cyan ring, a short white flash. About 80×80 px of force, mostly upward. | 6 frames, 160×160, 30 fps, no loop. Anchor (80,80) = the decoy's body centre. Additive. | `assets/art/effects/skill/rio_decoy_burst.png` | a, b |
| Skill icons | HUD icons in the flat pixel style of the others: 2-px clusters, 1-px dark outline, few colours.<br>`rio_j`: a sword thrusting through an arrow (the pierce).<br>`rio_k`: a flying sword with a dotted blink arrow behind it.<br>`rio_l`: a shadow figure with a crescent cut behind it.<br>`rio_u`: a figure and its see-through blue double with a swap arrow between them.<br>`rio_i`: six small gem swords in a ring, points inward. | 40×40 each, one frame, centre (20,20) | `assets/art/skill_icons/rio_{j,k,l,u,i}.png` (`rio_u` is new; the others replace the old kit's icons) | one each |

**Draw rules:**
- Transparent background, alpha 0 or 1, nearest filtering.
- The 1-px border of every frame stays empty.
- No text, and no glow halo outside the shape.
- Never upscale.
- Small items (the icons, perhaps the backstab mark) are usually better drawn pixel by pixel with Python + Pillow than with image_gen. Choose per item and say which you used.

## Output
- **Strips:** `art/bakeoff/effects/rio/<name>-<a|b>-v1.png` for `rio_mana_sword`, `rio_mana_sword_stuck`, `rio_backstab`, `rio_shadow_blink`, `rio_counter_stance` and `rio_decoy_burst`.
- **Icons:** `art/bakeoff/skill_icons/rio/<name>-v1.png`.
- **Metadata:** each file has a `.json`: `{"note": "<plain Korean>", "replaces": "<path above>", "frames": N, "fps": F, "anchor": [x, y], "loop": bool, "blend": "additive|normal"}`.
- **Boards** in `reports/codex-vfx-11/`. Draw each item **where the game shows it**, as a composite with his real sprites from his sheets:
  - **Mana sword:** flying frames at 1× and 4× ahead of his throwing hand; stuck frames in a foe's body, in a wall and in mid-air.
  - **Backstab:** every frame over another fighter's body centre (an idle from the sheets), at 1× and 4×.
  - **Shadow blink:** every frame at his feet, at 1× and 4×.
  - **Counter stance:** every frame around his idle tinted shadow blue (0.45, 0.52, 1.0), at 1× and 4×.
  - **Decoy burst:** every frame over his idle drawn blue and see-through (0.5, 0.78, 1.0, alpha 0.62), at 1× and 4×.
  - **Icons:** the bar `j k l u i` at 1× and 4×.
- **Overview:** `reports/codex-vfx-11/board.png`, all candidates side by side (A left, B right).
- **README:** `reports/codex-vfx-11/README.md` in Korean, short. Say what each candidate shows, give the measurements (sizes, frames, alpha, border, anchor) and list what a human should judge.
- **Prompts:** `reports/codex-vfx-11/prompts.txt`. Raw generations go in `art/raw/vfx-11/` (git-ignored).
- **Commit script:** `reports/codex-vfx-11/commit.ps1`. It stages only the delivered files, the boards, the README, the scripts and this card. No line in a committed text file may end with spaces.

## Writable
- New files only: `art/bakeoff/effects/rio/**`, `art/bakeoff/skill_icons/rio/**`, `art/raw/vfx-11/**`, `reports/codex-vfx-11/**`.
- Nothing under `smash-nine-prototype/` changes.
- **Hard stop: 150 minutes.** Check the clock before each generation and after every image_gen call. Deliver in the table order and list the rest.
