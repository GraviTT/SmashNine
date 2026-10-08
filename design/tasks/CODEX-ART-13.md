# CODEX-ART-13 · Basic attack and skill effects (attack range x2)

- Request: routine 2026-10-08 work. 사용자: "캐릭터들의 공격 범위와 이펙트들이 지금보다 최소 2배씩은 더 넓어야 할 것으로 보인다. 이전의 간단한 모습에서 본격적인 모습으로 바뀌니 매우 좁고 하찮아 보이는 느낌이다." · "루틴으로 시작하고, 맵 1.5배로."
- Unit: Builder · Lead (integrates): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/attack-vfx-a`
- **This task does not edit product source.** The lead is changing the combat scale in code at the same time.
- Timeout: given in the prompt.

## Why

Ultimates got effect art last night (`assets/art/vfx/`, `CODEX-ART-10`), but every basic attack and skill still draws as a translucent coloured rectangle from the prototype (the hitbox itself). Next to the detailed v2 fighters (about 100 px tall at 1x) attacks look tiny and cheap. Today the lead doubles every attack's reach and hit area; these strips replace the rectangles.

## Scale to draw for (new)

1 art pixel = 1 screen pixel, like the v2 fighters (`assets/art/<id>/<id>_sheet.png`, 128 px cells, feet y=120). After today's change a typical melee hit reaches **about 200 px** in front of the fighter's centre and covers **about 70–90 px** of height; sweeps travel from the body to that reach in 0.08–0.2 s. Ultimate strips (`assets/art/vfx/`) show the expected quality and style: pixel art, limited palette, bright core, readable silhouette, transparent background, at least 3 px empty margin.

## Deliverables (`smash-nine-prototype/assets/art/attack_vfx/`)

Horizontal strips of equal frames, drawn **facing right** (the lead mirrors for left and rotates for up/down attacks). Read each character's doc (`smash-nine-prototype/characters/<id>/<Id>.md`) and code to match what the move does.

| File | Frames | Frame size | What |
| --- | ---: | --- | --- |
| `frey_slash.png` | 6 | 192x128 | Golden-white sword arc (J chain, also used for her other melee hits) |
| `frey_k.png` | 6 | 224x96 | Directional dash strike: speed streak + blade flash |
| `frey_l.png` | 6 | 128x192 | Rising cleave: vertical upward arc |
| `yuki_slash.png` | 6 | 192x128 | Snowy paper-talisman swipe (her melee hits) |
| `yuki_k.png` | 6 | 128x128 | Binding talisman: seal snapping shut on a target |
| `yuki_l.png` | 6 | 192x192 | Release the wards: icy burst ring |
| `luna_slash.png` | 6 | 192x128 | Star-wand swipe with sparkles (normal form) |
| `luna_k.png` | 6 | 160x96 | Star comet launch flash |
| `luna_l.png` | 6 | 192x192 | Moon ring |
| `luna_brave_slash.png` | 6 | 224x128 | Radiant rush (Brave form): pink-gold heavy arc |
| `nova_slash.png` | 6 | 160x128 | Gravity punch / kick impact: cyan shock arc |
| `nova_k.png` | 6 | 224x96 | Vector shift dash trail |
| `nova_l.png` | 6 | 192x192 | Gravity brake / stomp shock ring (seen from the side: flat ellipse on the ground) |
| `rio_slash.png` | 6 | 192x128 | Mana blade arc (blue-violet) |
| `rio_k.png` | 6 | 256x96 | Dimension slash: thin teleport cut line with rift sparks |
| `rio_l.png` | 6 | 128x160 | Rune shield: hexagonal rune barrier flaring |

Plus `README.md` in the same folder in the format of `assets/art/vfx/README.md`: file, frames, frame size, suggested FPS, **anchor** (for slashes: the point at the fighter's body, e.g. left-middle), additive or not, loop or not. A `preview.png` contact sheet next to a v2 fighter frame at the same 1x scale (in `reports/codex-art-13/`).

Generate with your image tool; post-process with Godot's Image API (scripts under `smash-nine-prototype/tests/art_preview/attack_vfx_a/`); do not install packages or download files. Keep big inspection images out of `smash-nine-prototype/` (put them under `reports/codex-art-13/`).

## Writable paths

`smash-nine-prototype/assets/art/attack_vfx/**`, `smash-nine-prototype/tests/art_preview/attack_vfx_a/**`, `reports/codex-art-13/**`. Everything else is read-only.

## Report (`reports/codex-art-13/README.md`, Korean)

What was made (files, frames, sizes), the preview, anchors, what a human must judge. Commit, or `reports/codex-art-13/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
