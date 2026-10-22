# CODEX-LANG-01 · Korean and English: every player-facing string through the translation table

- Request: 사용자 2026-10-22: "그리고 지금 인게임이 계속 영어로 써져 있는데, 한글과 영어판 2가지 선택 가능하게 해줘."
- Unit: Builder (code + Korean text) · Lead: Claude (font, language setting, review, merge)
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-ui/SmashNine`, branch `codex/lang-01`
- Already on `main` (the lead): `scripts/Language.gd` (locale `en`/`ko`, `load_saved()`, `cycle()`, `label()`; saved in `user://`, headless and tests stay English), the UI font `assets/fonts/ui_font.tres` (Noto Sans KR weight 500, project `gui/theme/custom_font`; draws Hangul and Latin, also in the web build), the translation table `assets/i18n/strings.csv` (columns `keys,en,ko`; keys are the English source strings; Godot imports it to `strings.en.translation` / `strings.ko.translation`, registered in `project.godot`). `Main._ready` loads the saved language.
- Read first: `scripts/Language.gd`, `assets/i18n/strings.csv`, `scripts/ui/FrontendMenu.gd`, `scripts/ui/MatchHud.gd`, `scripts/Main.gd`, `scripts/match/MatchDirector.gd`, `scripts/match/SoulCards.gd`, `scripts/realms/RealmCatalog.gd`, `scripts/realms/RealmHazards.gd`, `scripts/RealmMonster.gd`, `scripts/RealmMonsterSpawner.gd`, `scripts/monsters/`, `characters/*/*Data.gd`, `characters/common/PlayerBase.gd` (float texts), `design/SKILLS.md`.
- Timeout: given in the prompt.

## Make

1. **Every string a player reads goes through the table**, in both languages: title, character select (names, roles, descriptions, skill lines), options, controls, results (columns, awards, buttons, "WINS"/"DRAW", reasons), the match HUD (phase names, clock line, next event, alive/status line, realm titles and subtitles, hazard texts and warnings, collapse/sudden-death banners, match messages and announcements, off-screen markers if they show words, skill bar labels, soul-card offer titles and descriptions), floating combat text (e.g. "PARRY!"), monster names (including "Elite …"), soul crystal and portal prompts.
   - Static texts: keep the English text and let Godot auto-translate, or call `tr()`. Text built in code: `tr("%s WINS") % name` style — translate the pattern, then format.
   - Character names in Korean: 프레이, 유키, 루나, 노바, 리오 (Brave Luna: 브레이브 루나). Realm names: 아스가르드, 미드가르드, 니플헤임, 알프헤임, 무스펠헤임, 스바르트알프헤임, 바나헤임, 요툰헤임, 이그드라실의 심장. Short, natural game Korean that fits the boxes.
   - The F3 debug panel and F4 bot panel are developer tools: they may stay English.
   - Do not rewrite the soul-card offer panel or the HP bar (a pending bug-fix branch touches them); only pass their strings through `tr()`.
2. **Language option:** Options gets "Language: English / 한국어" (`Language.cycle()`, then rebuild the screen the way the art-style switch reloads the front end). Show the language on the title screen footer next to the speed. A key is not needed.
3. **Switching updates everything:** after a switch, the next screen and the next match show the new language (texts built at match start may wait for the next match).
4. **Fit:** Korean text must not overflow its box (title menu, select panel, options rows, results table, HUD clock/status lines, banners, card offer). Adjust sizes/wrapping where needed.

## Tests and checks

- New `tests/test_language.gd` (add to `tests/run_all.ps1` before `test_restart`): every `tr("...")` literal in `scripts/` and `characters/` exists as a key in `strings.csv` with a non-empty `ko` value; switching to Korean changes the title menu, character select and results texts; switching back restores English; the saved choice is not written in headless runs.
- Whole `tests/run_all.ps1` passes (tests run in English).
- Captures (windowed, briefly): title, character select, options, a match HUD with a hazard warning, results — in Korean, plus the same title in English; contact sheet in `reports/codex-lang-01/`.

Writable: `smash-nine-prototype/scripts/ui/**`, `smash-nine-prototype/scripts/Main.gd`, `smash-nine-prototype/scripts/match/**`, `smash-nine-prototype/scripts/realms/RealmCatalog.gd`, `smash-nine-prototype/scripts/realms/RealmHazards.gd` (strings only), `smash-nine-prototype/scripts/RealmMonster.gd`, `smash-nine-prototype/scripts/RealmMonsterSpawner.gd`, `smash-nine-prototype/scripts/monsters/**` (strings only), `smash-nine-prototype/scripts/SoulCrystal*.gd` (strings only), `smash-nine-prototype/characters/*/*Data.gd` (name/role strings), `smash-nine-prototype/characters/common/PlayerBase.gd` (float-text strings only), `smash-nine-prototype/assets/i18n/**`, `smash-nine-prototype/tests/test_language.gd`, `smash-nine-prototype/tests/run_all.ps1` (one entry), `reports/codex-lang-01/**`. Do not change game rules or numbers. Report `reports/codex-lang-01/README.md` (Korean): what is translated, what stays English and why, captures, what is not done. Commit, or `reports/codex-lang-01/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
