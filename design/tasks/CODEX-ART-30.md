# CODEX-ART-30 · Rio v2 live sheets + 4 px margin on the Frey/Luna/Brave move sheets

- Request: same run (사용자 2026-10-10 "코덱스 한도 소모를 위해 ..."; "Claude는 명령과 검수만"); approved spare-time item "Rio 공격·방어 줄 크기 복원".
- Unit: Builder · Clone `SmashNine-units/builder-art/SmashNine`, branch `codex/margins-30`. Running at the same time: `codex/moves-26` (Nova/Yuki/Rio *moves* sheets and `tests/test_sprite_frames.gd` — do not touch those) and `codex/monsters-31`. Headless Godot only, unique `--log-file`.
- Tools: `tests/art_preview/moves_23/edge_audit.gd` (cells with 3+ opaque pixels on an edge) and `tests/art_preview/margin_30/margin_audit.gd` (cells with opaque pixels closer than 4 px to an edge; the live-sheet contract of `tests/test_sprite_frames.gd`).

## Do (hard stop 40 minutes after you start)
1. `tests/art_preview/moves_23/rio_male_sheet_v2.png` (9 cells under 4 px) and `rio_female_sheet_v2.png` (2 cells, and 3 cells flagged "looks cut" by test_sprite_frames' frame audit): bring every cell to margin 4 without shrinking the body (trim or fade effect pixels with an irregular/dithered edge, never a straight cut), then copy them over `assets/art/rio/rio_male_sheet.png` / `rio_female_sheet.png` and make `tests/test_sprite_frames.gd` pass. These replace the shrunken attack/shield rows (open since 2026-10-08).
2. `assets/art/frey/frey_moves_sheet.png` (7 cells), `assets/art/luna/luna_moves_sheet.png` (4), `assets/art/luna/luna_brave_moves_sheet.png` (5): margin 4 the same way; edge_audit stays 0.
- Before/after sheets of every changed cell in `tests/art_preview/margin_30/`; `run_all.ps1 -SkipSoak` (or the same list with unique logs) passes.
- Writable: the five PNGs above (+ `.import`), `tests/art_preview/margin_30/**`, `tests/art_preview/moves_23/rio_*_v2.png`, `reports/codex-art-30/**`. Report `reports/codex-art-30/README.md` (Korean) + `commit.ps1` (message ending `Co-Authored-By: Codex <noreply@openai.com>`).
