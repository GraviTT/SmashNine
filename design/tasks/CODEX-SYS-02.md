# CODEX-SYS-02 · Front end: title menu, character select, options, results

- Request: 사용자 2026-10-22 (취침 루틴): "전체 몬스터와 맵, 맵 구조, 메인 화면과 결과 화면, 캐릭터 선택 창, 그 외 캐릭터와 관련되지 않은 요소들을 시스템적으로 강화 할 취침루틴을 실행해볼것. 일단 취침 루틴이니 루틴동안 나올 요소들은 자동 허가로 진행."
- Unit: Builder (UI code) · Lead: Claude (reviews, merges, checks the web build)
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-ui/SmashNine`, branch `codex/sys-02`
- Read first: `scripts/ui/MatchHud.gd` (`show_start_screen`, `show_results`, `_build_overlay`, `_show_portraits`, `_build_menu_frames`), `scripts/Main.gd` (`_handle_global_input`, `_start_match`, `_on_match_finished`, `player_count`, `bots_only`), `scripts/GameSpeed.gd`, `scripts/ArtSettings.gd`, `characters/CharacterRegistry.gd` and each `*Data.gd` (name, role, bodies), `design/SKILLS.md` (what each skill does — for short English blurbs), `assets/art/ui/` (title logo, title background, HUD frames), each character's `*_face.png` / main art (`*_illustration.png` or `*_main*.png`).
- Running at the same time: Codex unit `codex/sys-01` (monsters: `scripts/RealmMonster*.gd`, `scripts/monsters/`) and the lead (`scripts/realms/RealmHazards.gd`). Do not edit those.
- Timeout: given in the prompt.

## Today

The start screen is one text block over the title art (`[1] Frey - Valkyrie Bruiser`, `[V] Body…`, `[B]`, `[F2]`, `[T]`) with a strip of portraits; number keys start a match at once. The result screen is a title ("X WINS"), one line and a stats table. No menu, no character information, no options screen, no way back to the menu except reloading.

## Make (keyboard and mouse; in-game text in English)

1. **Title screen:** logo over the title background, menu: Play, Watch bots, Options, Controls. Arrow keys / W-S + Enter / J, mouse hover + click.
2. **Character select:** a grid of the five fighters (face portraits), the selected one's main art large, name, role, a two-line description and one line per skill (J, K, L, I and the passive if any) written from `design/SKILLS.md` in plain English; body switch for two-body fighters (V or a button, shows that body's art); Random; Back. Enter / J / click confirms and starts the match. Number keys 1–5 still pick and start at once from the title or select screen (players use them today).
3. **Options:** game speed (100/90/80/70 % through `GameSpeed.cycle()`; T still works anywhere), art style (F2 still works), number of fighters 4 / 6 / 8 (sets `Main.player_count` for the next match; default 8), bot panel on/off at start. Keep the choices for the session (game speed already saves itself).
4. **Controls:** the key table (from `smash-nine-prototype/README.md` "Controls").
5. **Results screen:** the winner's main art with "<NAME> WINS" (or DRAW), standings with portraits and places, the stats you have today per row (KOs, damage dealt, souls, cards, survival time), three awards (most damage, most KOs, longest survival), buttons Rematch (same fighter and body), Character select, Title. R still rematches.
6. Keep: `test_restart` (restarts return to the same node count), the bot panel (F4), F3 debug, H dummy, the HUD during matches. **Do not rewrite the soul-card offer panel or the HP bar** (a pending bug-fix branch touches them); call them as they are.
7. Use the existing art (`assets/art/ui/frames/`, title art, portraits). New small UI images, if needed, go in `assets/art/ui/menu/` (your image tool is fine; 1x pixel style like the HUD frames).

## Tests and checks

- New `tests/test_frontend_flow.gd` (add to `tests/run_all.ps1` before `test_restart`): title → select → confirm starts a match with the chosen fighter and body; number keys still start at once; options change `player_count` and game speed; results → Rematch / Character select / Title each land where they should; no orphan nodes after going around twice (compare node counts like `test_restart`).
- Whole `tests/run_all.ps1` passes ("ALL PASSED"; the certificate-store ERROR is known noise).
- Captures (windowed, briefly, one at a time): title, select (two fighters), options, controls, results, saved to `reports/codex-sys-02/` with a contact sheet.

Writable: `smash-nine-prototype/scripts/ui/**`, `smash-nine-prototype/scripts/Main.gd` (flow and input only), `smash-nine-prototype/scenes/**` (new scenes only if you need them), `smash-nine-prototype/assets/art/ui/menu/**`, `smash-nine-prototype/tests/test_frontend_flow.gd`, `smash-nine-prototype/tests/run_all.ps1` (one entry), `smash-nine-prototype/README.md` (controls), `reports/codex-sys-02/**`. Report `reports/codex-sys-02/README.md` (Korean): screens built, input map, captures, what is not done. Commit, or `reports/codex-sys-02/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
