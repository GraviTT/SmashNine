# CODEX-VFX-06 · Nova: the gravity beam that splits and wraps its target (candidates)

- Request: the user (2026-11-03), picking from CODEX-VFX-05: "중력 광선은 적에게 닿으면 끝에서 갈라지며 적을 감싼 뒤 자신의 앞으로 끌고오는 식으로." — when the beam reaches a foe, its tip **splits open and wraps the foe**, then the beam **drags the foe to just in front of Nova**. Neither VFX-05 beam (A trident tip with a twisted cord, B star tip with a beaded cord) was picked; this card replaces them. **Candidates only**: the user picks, then the lead puts the pick in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-b/SmashNine`, branch `codex/vfx-06` (from main). No other unit runs.

## How the game uses it (the lead is wiring it now with code shapes; `characters/nova/NovaBeam.gd`, `Nova.gd` `on_beam_hit`)
- The beam flies from her palm (body centre, 24 px ahead) at about 1725 px/s for up to 620 px: a **head** with a **tether** behind it back to her hand.
- On a grounded foe: the head **splits** into three or four claws/tendrils that close round the foe's body (about 0.1 s), stay **binding** it while the tether drags it to 46×1.5 px in front of her (up to 0.45 s), then let go.
- On a foe in the air the beam slams it down instead (not this card).

## Read first
- `design/tasks/CODEX-VFX-05.md` and `reports/codex-vfx-05/README.md` (the picked Nova set: stacks B, orb A, field B, sphere A; the beam boards `beams.png`), `smash-nine-prototype/scripts/Vfx.gd` (strip contract).
- Style references: `art/bakeoff/effects/nova/nova_orb-a-v1.png`, `nova_field-b-v1.png`, `nova_sphere-a-v1.png` (the picked Nova effects: keep their look), Nova's idle `art/bakeoff/nova/nova_male-idle-v2.png`, a foe's idle (e.g. `art/bakeoff/frey/frey-idle-v2.png`). Palette: midnight indigo, violet, electric teal-cyan, white sparks.

## Items

| Item | Shows | Contract | Replaces | Candidates |
| --- | --- | --- | --- | --- |
| Head | the closed tip in flight, pointing right: three or four claws folded together into a point (it can visibly open) | 4 frames 48×48, 16 fps **loop**, anchor (24,24), additive | `assets/art/effects/nova_beam_head.png` | a, b |
| Split | the tip opening and closing round a body: (1) the claws spring open, (2)-(3) they curl round a body about 60×90 px (body centre at the anchor), (4) closed round it. The tether arrives from the **left** (the game mirrors it when she is on the right) | 4 frames 160×160, 40 fps one-shot, anchor (80,80) = the foe's body centre, additive. Keep the middle 50×80 mostly clear so the foe stays readable | `assets/art/effects/skill/nova_beam_split.png` | a, b |
| Bind | the claws wrapped round the body while it is dragged: tightening and pulsing, a few sparks streaming back toward the tether (left) | 4 frames 160×160, 12 fps **loop**, anchor (80,80), additive, (1) matches the split's (4) | `assets/art/effects/skill/nova_beam_bind.png` | a, b |
| Tether | a thin violet energy cord with a bright core line, repeating seamlessly left to right | one frame 64×16, seamless horizontally, additive; the game stretches it along the line from her hand to the head or the bound foe | `assets/art/effects/nova_beam_tile.png` | a, b |

Draw rules: transparent background, alpha 0/1, nearest filtering, 1-px border of every frame empty (the tether's left and right edges excepted: it must tile), no text, no glow halo outside the shape. Never upscale.

## Output
- `art/bakeoff/effects/nova/<name>-<a|b>-v2.png` + `.json` (`nova_beam_head`, `nova_beam_split`, `nova_beam_bind`, `nova_beam_tile`): `{"note": "<plain Korean>", "replaces": "<path above>", "frames": N, "fps": F, "anchor": [x, y], "loop": bool}`. (v2: the VFX-05 beam files are v1.)
- Boards in `reports/codex-vfx-06/`, drawn **where the game shows it** (real sprites, composites, 1× and 4×): Nova's idle on the left, a foe's idle 300 px to the right on the same floor: (1) the head in flight at 150 px with the tether from her hand; (2) every split frame on the foe; (3) every bind frame on the foe, the tether from her hand; (4) the foe dragged half way (150 px) bound; (5) the foe arrived 69 px in front of her, still bound. Also the tether repeated three times at 4× to show the seam.
- `reports/codex-vfx-06/board.png` (overview, A left, B right), `reports/codex-vfx-06/README.md` (Korean, short: what each candidate shows, the measurements, what a human should judge), `prompts.txt`; raw generations in `art/raw/vfx-06/` (git-ignored).
- `reports/codex-vfx-06/commit.ps1`: only your files and this card; no `git add -f`, nothing under `art/raw/`, no `__pycache__`. No line in a committed text file may end with spaces or blank lines at the end (the commit check rejects them).

## Writable
`art/bakeoff/effects/nova/nova_beam_{head,split,bind,tile}-{a,b}-v2.*` (new files only), `art/raw/vfx-06/**`, `reports/codex-vfx-06/**`. Nothing under `smash-nine-prototype/` changes. Hard stop: 90 minutes.
