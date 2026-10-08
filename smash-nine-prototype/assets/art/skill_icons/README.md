# Skill icons

Bottom-right HUD skill bar icons for the focused fighter.

- Canvas: 40×40 px, RGBA8, transparent background
- Display: 1 art px = 1 screen px, centred in a 48×48 slot (4 px inset)
- Anchor: icon centre `(20, 20)`; each file contains one static frame
- The HUD draws the dark rounded slot, key badge and cooldown shade. These files contain only the skill mark.
- Brave Luna uses the `luna_brave_*` set while transformed.

| Fighter | J | K | L | I |
| --- | --- | --- | --- | --- |
| Frey | `frey_j.png` | `frey_k.png` | `frey_l.png` | `frey_i.png` |
| Yuki | `yuki_j.png` | `yuki_k.png` | `yuki_l.png` | `yuki_i.png` |
| Luna | `luna_j.png` | `luna_k.png` | `luna_l.png` | `luna_i.png` |
| Brave Luna | `luna_brave_j.png` | `luna_brave_k.png` | `luna_brave_l.png` | `luna_brave_i.png` |
| Nova | `nova_j.png` | `nova_k.png` | `nova_l.png` | `nova_i.png` |
| Rio | `rio_j.png` | `rio_k.png` | `rio_l.png` | `rio_i.png` |

Source and verification workflow: `tests/art_preview/skill_icons_18/build_skill_icons.gd`.
