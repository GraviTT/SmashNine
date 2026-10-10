# CODEX-ART-27 · Monster pairs, title background, HUD frames wired

- Request: same run as CODEX-ART-23..26 (사용자 2026-10-10 "코덱스 한도 소모를 위해, 코덱스에 이미지, 스프라이트 생성 명령 내릴것."; "Claude는 명령과 검수만"). Follows CODEX-ART-25 (merged `47602b5`).
- Unit: Builder (images + wiring) · Clone `SmashNine-units/builder-ui/SmashNine`, branch `codex/monsters-ui-27`
- Running at the same time: `codex/moves-23` (PlayerBase, Frey, Luna) and `codex/moves-26` (art only). You touch none of their files. Headless Godot only; use a unique `--log-file` per Godot run (ART-25 found the default log locked by the other builders).
- Read first: `reports/codex-art-25/README.md` (your last round, the lead accepted it), `design/tasks/CODEX-ART-25.md`.

## 1. Lead review items (required)
- `ui/title_bg.png` has a navy margin because the generation was smaller than 1920×1080. Pixel art may be enlarged by an **integer nearest** factor: make it at 960×540 (full bleed, no margin) and scale ×2 nearest to 1920×1080. Wire it as the start/result screen background behind the logo in `MatchHud` (fallback: today's overlay colour).
- `jotunheim` monster reads smaller than the others: redraw at the same visual weight as `mossling` (same cell, bigger silhouette).

## 2. HUD frames wired (required)
- Use the ART-25 9-slice frames (`ui/frames/`) with `NinePatchRect` in `MatchHud` for the skill slots, HP bar, card panel, result panel and menu buttons; keep today's `ColorRect` look as the fallback (F2 prototype or missing file). Text stays drawn in code and must stay readable (contrast).
- Extend `tests/test_realm_monsters.gd` or add `tests/test_hud_frames.gd`: frames used with the files, ColorRects without them (show it fails on the old code).

## 3. Second monster per realm (as many as time allows, in this order)
- Every realm gets its own pair: the kind it does not have yet. Order: Asgard, Niflheim, Alfheim, Svartalfheim, Vanaheim, Jotunheim, Yggdrasil Heart, then Midgard (ranged) and Muspelheim (melee). Same contract as ART-25; extend the catalog entry (e.g. `"monsters": {"melee": ..., "ranged": ...}`) and the spawner, keep the generic fallback, extend the test.

## Verify and report
- Contact sheets in `tests/art_preview/monsters_ui_27/`; `run_all.ps1 -SkipSoak` or the same list with unique log files: all pass apart from the known certificate line.
- Writable: `assets/art/monsters/**`, `assets/art/ui/**`, `scripts/realms/RealmCatalog.gd` (monster entries), `scripts/RealmMonsterSpawner.gd`, `scripts/RealmMonster.gd` (art loading), `scripts/ui/MatchHud.gd`, `tests/test_realm_monsters.gd`, `tests/test_hud_frames.gd`, `tests/art_preview/monsters_ui_27/**`, `reports/codex-art-27/**`. Keep image-gen originals named `*_source.png`.
- Hard stop 60 minutes after you start. Report `reports/codex-art-27/README.md` (Korean) + `commit.ps1` (writable paths only, message ending `Co-Authored-By: Codex <noreply@openai.com>`).
