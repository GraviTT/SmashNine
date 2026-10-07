# Smash Nine Realms Prototype

Godot 4.7 prototype of Smash Nine Realms: a 2D platform-brawler battle royale where
eight fighters start in the corner realms, the outer realms collapse in two waves,
and the last one standing in the heart of Yggdrasil wins.

Design decisions and their reasons: `../design/DECISIONS.md`. Milestones: `../design/ROADMAP.md`.

## Controls

| Key | Action |
|---|---|
| A / D | move |
| W | jump (one air jump; Sky Step card adds more) |
| S, S | drop through a thin platform |
| Space | guard (tap right before a hit to parry) |
| J | basic attack (direction keys change it) |
| K / L | skills |
| I | ultimate (30 s cooldown) |
| Q | use the portal you are standing on |
| 1 / 2 / 3 | pick a soul card when offered |
| H | spawn/remove a training dummy |
| F3 | debug panel |
| R | play again (result screen) |

Start screen: 1–4 picks Frey, Yuki, Luna or Nova; B watches a bots-only match; F2 switches between the prototype art and the original art (center realm, Frey).

## Match rules (M1)

- 8 fighters (you + 7 bots), two per corner realm. HP 0 is permanent elimination.
- Ring-out (falling or flying past the side lines) costs 20/25/30/40 HP by phase, then you respawn in the same realm with 1 s protection.
- 2:00 corner realms warn, 2:30 they collapse. 3:30 the center opens and the edge realms warn, 4:00 they collapse. Anyone caught loses 30 HP and is thrown to a safe realm.
- 6:00 sudden death: the safe band in the center shrinks. 7:00 the survivor with the most HP wins.
- Collapse and sudden death never take out the last fighter: if everyone left would fall, the healthiest keeps 1 HP. A same-frame double KO in combat is a draw.
- Souls come from damage, knock-outs and monsters. At 25/50/75 souls you pick one of three cards (5 s, then auto-pick); each pick also grows your character's base stats.
- Early phases forgive more: out-of-combat HP recovery until the edge realms fall, and bots mostly farm until provoked.
- Realm hazards: Niflheim floors are icy (you slide, knockback carries further); Muspelheim vents glow, then fire pillars launch anyone on them; Jotunheim rumbles, then a quake stuns everyone on the ground (jump to avoid it).

## Project layout

- `scripts/Main.gd` — match scene root (start screen, spawning, camera, input, wiring)
- `scripts/match/` — `MatchDirector` (rules and timeline), `SoulGrowth` + `SoulCards`
- `scripts/realms/` — `RealmCatalog` (realm data), `RealmLayout` (geometry), `RealmWorld` (scene nodes)
- `scripts/ui/MatchHud.gd` — HUD, card panel, start and result screens
- `scripts/EnemyAI.gd` — bots; `scripts/RealmMonster*.gd` — neutral monsters
- `characters/` — `common/PlayerBase.gd` and one folder per fighter (see `characters/README.md`)
- `tests/` — headless tests, bot soak, screenshot capture, `run_all.ps1`

## Tests

From this folder (Godot path in `../AGENTS.md`):

- Everything: `powershell -ExecutionPolicy Bypass -File tests/run_all.ps1 [-SoakRuns 3]`
- Bot soak with telemetry: `<godot> --headless --path . --fixed-fps 60 -s tests/soak_match.gd -- --seed=7 --players=8`
- Screenshots (windowed): `<godot> --path . -s tests/capture_screens.gd -- --out=../reports/screens`

Temporary third-party character art and its licenses: `assets/THIRD_PARTY_ASSETS.md`.

## Web build

- Build and zip: `powershell -ExecutionPolicy Bypass -File tools/build_web.ps1` (from the repo root) → `build/web/` and `build/SmashNine-web.zip` (~10 MB, ready for an itch.io HTML5 upload or any static host).
- Local check: `node tools/serve_web.js build/web 8060`, then open http://localhost:8060.
- Publish to GitHub Pages: `powershell -ExecutionPolicy Bypass -File tools/deploy_pages.ps1` (builds, then replaces the one-commit `gh-pages` branch). Site: https://gravitt.github.io/SmashNine/
- Uses the Compatibility renderer and a no-threads web template, so it needs no special server headers. Requires the Godot 4.7.stable web export templates in `%APPDATA%\Godot\export_templates\4.7.stable`.
