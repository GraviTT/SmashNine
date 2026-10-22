# UI font

`NotoSansKR-UI.ttf` is the game's UI font: Noto Sans KR (version 2.04) fixed at weight 500 and cut
down to the characters the game needs — ASCII, Latin-1, punctuation, arrows, Hangul compatibility
jamo, the 2,350 KS X 1001 syllables, and every character in `assets/i18n/strings.csv` and the
game's `.gd` files. 455 KB with 2,683 characters (the full variable font was 10.4 MB; user
2026-10-22 "폰트 부분 글꼴로 줄이는 것도 진행해"). It draws Hangul and Latin, so one font serves
both languages in the desktop and web builds (D42).

`ui_font.tres` wraps it as the project's default UI font (`gui/theme/custom_font`).

Rebuild after adding Korean text with `tools/font_subset/make_ui_font.py` (needs fontTools; the
source is the Noto Sans KR variable font from the Windows font folder). `tests/test_font_coverage.gd`
fails when the translation table uses a character the font lacks.

License: SIL Open Font License 1.1, copyright Adobe (Reserved Font Name 'Source') — `OFL.txt`
ships with the font. This subset is a Modified Version under the OFL and keeps the family name
Noto Sans KR (not the reserved name).
