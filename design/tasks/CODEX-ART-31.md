# CODEX-ART-31 · Second monster per realm

- Request: same run (사용자 2026-10-10 "코덱스 한도 소모를 위해 ..."; "Claude는 명령과 검수만"); Part 3 of CODEX-ART-27, not reached there.
- Unit: Builder (images + wiring) · Clone `SmashNine-units/builder-ui/SmashNine`, branch `codex/monsters-31`. Running at the same time: `codex/moves-26`, `codex/margins-30` (character sheets only). Headless Godot only, unique `--log-file`.
- Read first: `reports/codex-art-25/README.md`, `reports/codex-art-27/README.md`, `design/tasks/CODEX-ART-27.md` part 3.

## Do (hard stop 40 minutes after you start)
- Every realm gets its own pair: the kind it does not have yet, in this order: Asgard, Niflheim, Alfheim, Svartalfheim, Vanaheim, Jotunheim, Yggdrasil Heart, then Midgard (ranged) and Muspelheim (melee). Same sheet contract as ART-25 (576×384, 96 px cells, rows idle/walk/attack/hurt; ranged ones with a 24 px projectile), same visual weight as `mossling`, themed on the realm's background/accent, no text.
- Wiring: extend the catalog entry to hold both kinds, the spawner picks the realm's skin for each kind, generic fallback kept; behaviour and numbers stay those of mossling / ember_imp. Extend `tests/test_realm_monsters.gd`.
- Contact sheet in `tests/art_preview/monsters_31/` (each realm's pair on its background next to a 128 px fighter cell); `run_all.ps1 -SkipSoak` (or the same list with unique logs) passes. Deliver finished realms only.
- Writable: `assets/art/monsters/**`, `scripts/realms/RealmCatalog.gd` (monster entries), `scripts/RealmMonsterSpawner.gd`, `scripts/RealmMonster.gd` (art loading), `tests/test_realm_monsters.gd`, `tests/art_preview/monsters_31/**`, `reports/codex-art-31/**`. Report `reports/codex-art-31/README.md` (Korean) + `commit.ps1` (message ending `Co-Authored-By: Codex <noreply@openai.com>`).
