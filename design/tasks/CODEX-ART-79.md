# CODEX-ART-79 · Monster projectiles and the slam shockwave at the new art level

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 2 (monsters). The new monster rows (ART-71/74/76) draw no projectile: "the projectile is separate art". This card makes that art.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/auditor/SmashNine`, branch `codex/art-79` (from the latest main).
- Running at the same time:
  - ART-74 and ART-76 (monster rows) in builder-art and tester; they write other files in `art/bakeoff/monsters/`
  - ART-75, ART-77, ART-78 (character motions)
  - SYS-05 (sound wiring, the only unit running Godot) in analyst
  - You share no files.
- **Candidates only, art only.** Nothing under `smash-nine-prototype/` changes. The wiring (animated strips, the shockwave sprite) comes in a later card.

## How the game draws them now (read the code)
- `scripts/RealmMonster.gd` `_spawn_ecology_projectile()`: `assets/art/monsters/<id>_projectile.png` (24×24, one image), or `ember_fireball.png` (36×36), shown about 36 screen px wide, rotated to its flight direction (`scripts/Projectile.gd` `set_art`, `ArtSettings.aimed_sprite`).
- The slam shockwave (`jotunheim_rune_golem`, `yggdrasil_root_guardian`) is a code-drawn yellow line crest running along the ground both ways for 0.42 s.
- The drone's bomb uses `svartalfheim_cog_drone_projectile.png`.

## What to make

| Id | Used by | Kind | Shape |
|---|---|---|---|
| `ember_imp` | bolt | fireball | flies right; a flame tail behind |
| `niflheim_frost_owl` | bolt, slows | ice shard | flies right; a frosty trail |
| `jotunheim_storm_wisp` | bolt | lightning | flies right; a crackling spark |
| `midgard_rooftop_slinger` | lob | stone | round; tumbles |
| `vanaheim_seed_sprite` | lob, three at once | seed pod | round; spins |
| `svartalfheim_cog_drone` | drops a bomb | bomb | round with a fuse spark; tumbles |
| `yggdrasil_root_oracle` | homing, slow | seeking orb | round, a pulsing glow |
| `slam_shockwave` | slam | ground crest | a crest of rock and dust moving right along the floor; its bottom on the floor line |

- Each is a **strip of 4 frames** (flicker, spin or pulse) in square cells of 48 px (the shockwave: 64 wide × 48 high, floor at y=44).
- Frame 1 must also work alone, because the game shows one still image until the wiring lands.
- Things that fly right are drawn pointing right (+x); round things look the same in any rotation.
- Colours from each monster's own palette (look at its current sheet and its new candidate rows in `art/bakeoff/monsters/`).
- Detail like the new monster rows, but **readable at 36 px**: a clear silhouette and one bright core; no tiny noise.

## Checks
- Transparent background, 2 px margin, spill 0, no text.
- A board per projectile: `reports/codex-art-79/<id>.png` with
  - the 4 frames at 1× and 4×
  - the old image next to it
  - an in-context mock: the monster's attack frame (the new candidate if there is one, else the current sheet) with the projectile in flight at game scale, on a dark realm-coloured background
- Up to 3 generations per projectile.

## Output
- `art/bakeoff/monsters/<id>-projectile-v1.png` (the strip) + `.json` (`note` in Korean, `frames: 4`, `fps`, `cell`, `aim`: `"right"` or `"none"`); the shockwave as `art/bakeoff/monsters/slam_shockwave-v1.png` + `.json`.
- `reports/codex-art-79/README.md` (Korean), `prompts.txt`, an overview board of all eight.
- `commit.ps1`: only your files, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/monsters/*-projectile-v1.*`, `art/bakeoff/monsters/slam_shockwave-v1.*` (new files), `art/raw/projectiles-79/**` (git-ignored), `reports/codex-art-79/**`.

Hard stop: 120 minutes. In the table order.
