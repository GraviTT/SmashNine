# CODEX-SYS-07 · Monster projectile strips and the slam shockwave sprite (wiring with fallback)

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 2 (monsters). ART-79 (merged `20f70aa`) made candidate projectiles as 4-frame strips and a shockwave strip (`art/bakeoff/monsters/*-projectile-v1.*`, `slam_shockwave-v1.*`, `reports/codex-art-79/README.md`). The user picks them in the motion viewer.
- **Goal: adopting a pick is a file copy.** The game keeps its look until files are copied. Do not copy any candidate into `assets/` yourself.
- Unit: Builder (code). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/sys-07` (from the latest main). You write the product code; the lead reviews and merges.
- Running at the same time: image units in other clones. **You are the only unit running Godot.** Other sessions edit `characters/<name>/` and `scripts/story/`: do not edit those.

## Adoption (what the lead will copy later)
| Candidate | Copied to |
|---|---|
| `art/bakeoff/monsters/<id>-projectile-v1.png` (192×48, 4 frames) | `assets/art/monsters/<id>_projectile.png` (replaces the 24×24 still) |
| `art/bakeoff/monsters/ember_imp-projectile-v1.png` | `assets/art/monsters/ember_fireball.png` |
| `art/bakeoff/monsters/slam_shockwave-v1.png` (256×48, 4 frames, floor at y=44) | `assets/art/monsters/slam_shockwave.png` (new) |

## The code
Read `scripts/RealmMonster.gd` `_spawn_ecology_projectile()`, `scripts/Projectile.gd` `set_art()`, `scripts/ArtSettings.gd` `aimed_sprite()`.

1. **Strips, monsters only.** In `_spawn_ecology_projectile`, a monster projectile image whose width is a whole multiple (2 or more) of its height is a strip: frames = width / height, played as a loop at 12 fps. A square image stays a still sprite exactly as today. Fighters' projectiles keep calling `set_art` unchanged (some fighter images are not square and are not strips): add a separate entry such as `set_art_strip(path, frames, fps, aimed)` rather than changing `set_art`'s behaviour.
2. **Orientation by kind.** `bolt` (fireball, ice, lightning) turns with its flight direction, as today. `lob`, `bomb` and `homing` are round: not rotated, only mirrored by their horizontal direction.
3. **Size.** One frame shows as big on screen as the old still (the same formula, with the frame width in place of the texture width).
4. **Shockwave.** When `assets/art/monsters/slam_shockwave.png` exists, an animated sprite replaces the code-drawn `Line2D` crest: its floor line on the ground, mirrored for the wave going left. When the file is missing, today's crest.
5. Hit boxes, speeds, damage, timing and AI do not change.

## Tests
- `tests/test_projectile_art.gd`, added to `tests/run_all.ps1`. Make the test strips in code (`Image` → `ImageTexture`, injected the way you choose; say how), never by copying candidates:
  - a 4-frame strip animates (the frame changes over time) at the old on-screen size
  - a square image stays a still sprite (today's path)
  - a bolt turns with its direction; a lob, a bomb and a homing orb do not
  - the shockwave sprite replaces the crest, sits on the floor, mirrors for the left wave; without the file the crest is back
  - a fighter projectile (`set_art`) is unchanged
- The full suite `tests/run_all.ps1` passes. Run it once at the end and report its last lines.

## Output
- the code and the test
- `assets/art/monsters/README.md`: the adoption table above
- `reports/codex-sys-07/README.md` (Korean)
- `commit.ps1`: only your files, no `git add -f`, no `__pycache__`, no logs

## Writable
`smash-nine-prototype/scripts/RealmMonster.gd` (`_spawn_ecology_projectile` and helpers it needs), `smash-nine-prototype/scripts/Projectile.gd`, `smash-nine-prototype/scripts/ArtSettings.gd` (a strip helper, if needed), `smash-nine-prototype/tests/test_projectile_art.gd`, `smash-nine-prototype/tests/run_all.ps1`, `smash-nine-prototype/assets/art/monsters/README.md`, `reports/codex-sys-07/**`.

Godot: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`, headless only, `--import` first. Hard stop: 120 minutes.
