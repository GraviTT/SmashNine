# UI font

`NotoSansKR-VF.ttf` is Noto Sans KR (variable weight 100-900, version 2.04), copied from the
Windows font folder on 2026-10-22 for the Korean/English language option (user: "한글과 영어판
2가지 선택 가능하게"). It covers Hangul and Latin, so one font draws both languages in the
desktop and web builds (the web build has no system fonts — the reason the game was English-only,
D29). License: SIL Open Font License 1.1, copyright Adobe — `OFL.txt` must ship with it.

`ui_font.tres` is the project's default UI font (`gui/theme/custom_font`): the variable font at
weight 500 (its default instance is the thin weight 100).

Size: 10.4 MB. A subset (2,350 common syllables + Latin) would be about 1-2 MB; that needs
fontTools (not installed here).
