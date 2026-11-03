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

**2026-10-29:** Brave Luna's `luna_brave_j`, `_k`, `_l` were redrawn (CODEX-VFX-02, candidate A, user's pick) to show her moves: a gauntlet fist (J chain), a star-led body dash (K Comet Drive), a crescent kick arc (L Luna Breaker). Same canvas, outline and style; `luna_brave_i` is unchanged.

**2026-11-03:** Luna's `luna_j`, `luna_k`, `luna_l`, `luna_brave_k`, `luna_brave_l` were replaced for her new kit (D45; CODEX-VFX-04, the only candidates, user's pick): stars flying (Star Volley), a sparkle burst after a dotted jump (Twinkle Warp), a round star shield (Star Barrier), a gauntlet gripping with a throw arrow (Comet Catch), a whirlwind (Star Cyclone). Frey's `frey_k` (Whirl Wave, D44) still shows the old dash; its A/B candidates (CODEX-VFX-03) wait for the user's pick.

**2026-11-03 (later):** Nova's `nova_j`, `nova_k`, `nova_l`, `nova_i` were replaced and `nova_u` added for her new kit (D47; CODEX-VFX-05, the only candidates, the user's "추천대로"): three quick punches (Vector Chain), an orb with an inward spiral (Gravity Orb), a floating figure in a field (Gravity Field), a hook pulling back (Gravity Beam), a black sphere with orbiting dots (Event Horizon). The skill bar shows the U slot only for a fighter with a third skill.
