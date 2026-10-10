# CODEX-ART-25 · Realm monsters + UI art, with wiring

- Request: 사용자 2026-10-10 20:00 "코덱스 한도 소모를 위해, 코덱스에 이미지, 스프라이트 생성 명령 내릴것." + "Claude는 명령과 검수만" — so this card includes the wiring code. Run plan: `routine/2026-10-10-work/README.md`.
- Unit: Builder (images + wiring) · Lead: Claude (reviews, merges, runs the full tests)
- Clone: `SmashNine-units/builder-ui/SmashNine`, branch `codex/monsters-ui-25`
- Running at the same time: builders `codex/moves-23` and `codex/skill-fx-24` (they edit character files, `PlayerBase.gd`, `Vfx.gd`, `RealmWorld.gd`). You do not touch those. No windowed Godot runs; headless only.
- Read first: `assets/art/monsters/README.md` (sheet contract), `scripts/RealmMonster.gd`, `scripts/RealmMonsterSpawner.gd`, `scripts/realms/RealmCatalog.gd` (realm names, themes, accents), the realm art `assets/art/realm_*/`, the concept art `smash-nine/Concept1.png`, `Concept2.png`, `assets/art/ui/README.md`, `scripts/ui/MatchHud.gd`.

## Today
Every realm spawns the same two monsters, alternating (`RealmMonsterSpawner.gd:35`): `mossling` (melee) and `ember_imp` (ranged, `ember_fireball.png`). HUD panels, minimap, cut-in band and menus are coloured rectangles; `assets/art/vfx/ult_cutin_band.png` exists but is not used.

## Part 1 — a monster of their own for seven realms (required)
- One new monster per realm for Asgard, Niflheim, Alfheim, Svartalfheim, Vanaheim, Jotunheim and Yggdrasil Heart (center). Midgard keeps `mossling`, Muspelheim keeps `ember_imp`. You choose melee or ranged per realm so the set ends near 4 melee / 3 ranged; ranged ones get a projectile PNG like `ember_fireball.png`.
- Same sheet contract and size class as `mossling_sheet.png` / `ember_imp_sheet.png` (576×384, rows idle/walk/attack/hurt per the README), same outline weight and pixel density; readable silhouette at game size; themed on the realm's background and accent colour; no text.
- Wiring (skin only, behaviour unchanged): a per-realm entry in `RealmCatalog.gd` (e.g. `"monster": {"skin": "...", "kind": "melee"|"ranged"}`), `RealmMonsterSpawner.gd` picks the realm's own skin in place of the matching generic type, `RealmMonster.gd` loads the skin's sheet/projectile and falls back to the generic art. Stats, AI, hitboxes stay those of `mossling` / `ember_imp`.
- New test `tests/test_realm_monsters.gd`: each of the seven realms spawns its own skin (and the fallback works without the file). Show it fails on the old code. The lead adds it to `run_all.ps1`.
- Check: `tests/run_all.ps1 -SkipSoak` passes in your clone.

## Part 2 — UI art (do right after Part 1)
- `assets/art/ui/realm_emblems/<realm>.png` × 9 (32×32, readable on the minimap; no letters). Wire them into the minimap (`MatchHud.rebuild_minimap`, fallback today's boxes).
- Cut-in: use the existing `vfx/ult_cutin_band.png` in `MatchHud._build_cutin` / `show_ultimate_cutin` (tinted by the fighter colour as today; fallback the ColorRect).
- `assets/art/ui/status/`: icons 24×24 for super armor, stun, Luna star charge, Frey pursuit mark, shield break, low HP (no letters). Art only.
- `assets/art/ui/frames/`: 9-slice frames for the skill slot, HP bar, card panel, result panel, menu button (with margins in the README). Art only.
- `assets/art/ui/title_bg.png`: a 1920×1080 start-screen background (the nine realms around Yggdrasil, room for the logo in the upper centre, no text). Art only.

## Part 3 — only if time remains
- A second skin per realm (the other kind), so every realm has its own pair; wire the same way.

## Verify and report
- Contact sheets in `tests/art_preview/monsters_ui_25/`: monsters per realm on that realm's background next to a 128 px fighter cell and the existing two monsters (size check); UI pieces at 1x on the game HUD colours; a headless HUD capture with emblems and the cut-in if you can.
- Measure size, alpha, palette distance; say which ones you think are weak.
- Writable: `assets/art/monsters/**`, `assets/art/ui/**` (new files + README append), `scripts/realms/RealmCatalog.gd` (monster entries only), `scripts/RealmMonsterSpawner.gd`, `scripts/RealmMonster.gd` (art loading only), `scripts/ui/MatchHud.gd` (minimap emblems + cut-in only), `tests/test_realm_monsters.gd`, `tests/art_preview/monsters_ui_25/**`, `reports/codex-art-25/**`. Keep image-gen originals named `*_source.png`; previews under ~15 MB.
- Report `reports/codex-art-25/README.md` (Korean). Commit, or `reports/codex-art-25/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
