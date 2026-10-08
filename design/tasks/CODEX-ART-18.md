# CODEX-ART-18 · Skill icons for the bottom-right skill bar

- Request: 사용자 2026-10-08 "화면 오른쪽 아래에 조작키를 간단히 표시하고, 스킬 아이콘도 간단하게 나타내줘." (and earlier: "그림이 어색해지는 것은 모두 Codex에게 맡기고")
- Unit: Builder (image) · Lead (HUD code and integration): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/skill-icons-18`
- Running at the same time: Codex analyst (bot matches, CPU heavy). **This task does not edit product source.**
- Timeout: given in the prompt.

## What the game does with them

The HUD shows four slots at the bottom right for the fighter in focus: J (basic attack), K (skill 1), L (skill 2), I (ultimate). Each slot is a 48x48 dark rounded square drawn by the game, with the key letter in a corner badge and a cooldown shade drawn by the game. Your icon sits centred in it at **1 art px = 1 screen px** (40x40). While Luna is transformed (Brave Luna) her four slots switch to the Brave set.

## Deliverables: 24 icons, `smash-nine-prototype/assets/art/skill_icons/<file>.png`

| Character | J | K | L | I |
| --- | --- | --- | --- | --- |
| Frey | `frey_j` Valkyrie Sword Chain | `frey_k` Directional Dash Strike | `frey_l` Rising Cleave | `frey_i` Descent |
| Yuki | `yuki_j` Snow Talisman | `yuki_k` Binding Talisman | `yuki_l` Release The Wards | `yuki_i` Four-Direction Grand Ward |
| Luna | `luna_j` Star Echo | `luna_k` Star Comet | `luna_l` Moon Ring | `luna_i` Brave Luna (transformation) |
| Brave Luna | `luna_brave_j` Radiant Rush | `luna_brave_k` Comet Drive | `luna_brave_l` Luna Breaker | `luna_brave_i` Heart Laser |
| Nova | `nova_j` Vector Strike | `nova_k` Vector Shift | `nova_l` Gravity Brake | `nova_i` Event Horizon: Gravity Slingshot |
| Rio | `rio_j` Mana Slash | `rio_k` Dimension Slash | `rio_l` Rune Shield | `rio_i` Infinity Overdrive |

What each move does: `smash-nine-prototype/characters/<id>/<Id>.md` (sections "Controls And Skills" / "Normal Form" / "Ultimate").

## Spec

| Item | Value |
| --- | --- |
| Size | 40x40 px each, RGBA, transparent background; shown 1:1 (no scaling) |
| Style | the game's pixel art: same palette and line feel as `assets/art/attack_vfx/*.png`, `assets/art/vfx/*.png`, the fighters' sheets and portraits (`assets/art/<id>/`) |
| Read at a glance | one bold shape per icon (weapon, talisman, star, gravity well, rune...), 1 px dark outline, 3–5 colours plus highlights; readable at 40 px on a dark slot; the four icons of one fighter clearly different from each other |
| Colour | each fighter's accent: Frey gold / steel blue, Yuki ice blue / talisman red, Luna pink / star gold (Brave Luna brighter, with hearts), Nova violet / cyan, Rio mana blue / gem colours |
| Ultimates | a little richer than the other three (glow or radiating marks) so I stands out |
| Must not | letters, numbers or key names (the game draws the key); a frame, slot or background (the game draws it); detail smaller than 2 px that disappears at 1x |

Check at 1x and at 4x on the slot colour `#141824` and on a light grey: every icon distinct from its neighbours, nothing touching the 40 px border except deliberate glows. Contact sheet and the checks go under `reports/codex-art-18/`. A README in `assets/art/skill_icons/README.md` lists files, size and the HUD use.

Generate with your image tool; post-process with Godot's Image API (scripts under `smash-nine-prototype/tests/art_preview/skill_icons_18/`); do not install packages or download files.

## Writable paths

`smash-nine-prototype/assets/art/skill_icons/**`, `smash-nine-prototype/tests/art_preview/skill_icons_18/**`, `reports/codex-art-18/**`.

## Report (`reports/codex-art-18/README.md`, Korean)

The contact sheet (1x and 4x), per-icon notes (what it shows), checks, what a human must judge. Commit, or `reports/codex-art-18/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
