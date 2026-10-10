# CODEX-ART-29 · Wire Nova, Yuki, Rio move rows

- Request: same run as CODEX-ART-23..28 (사용자 2026-10-10 "코덱스 한도 소모를 위해 ..."; "Claude는 명령과 검수만").
- Unit: Builder (wiring) · Clone `SmashNine-units/builder-art/SmashNine`, branch `codex/moves-wire-29`
- Running at the same time: `codex/moves-26` (fixing the Nova/Yuki/Rio sheets themselves in `SmashNine-units/builder-frey/SmashNine`, not merged yet) and `codex/monsters-ui-27`. No art this time.
- Read first: the ART-23 loader (`PlayerBase.get_move_sheet_rows`, `_configure_move_sheet`, `_start_attack(..., move_row, move_pose)`, `_play_move_sprite_pose`) and how `Frey.gd` / `Luna.gd` use it; the row tables in `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine/smash-nine-prototype/assets/art/{nova,yuki,rio}/*_moves_README.md` (read-only; the sheets keep these row names and order).

## Do
- `Nova.gd`, `Yuki.gd`, `Rio.gd`: the row table (`get_move_sheet_rows`) and the move row of each move's pose call, exactly like Frey/Luna. Both bodies of Nova/Rio share the table. Visual only: no change to damage, hitboxes, timings, inputs or the bot. With no moves sheet present (today in this clone), every move must fall back to today's attack-row pose.
- Extend `tests/test_moves_sheet.gd`: for each of the three, every row name in the table is played by at least one move when a sheet exists (use a temporary generated sheet of the right size via `moves_sheet_path_override` or similar), and the fallback works without one.
- `run_all.ps1 -SkipSoak` (or the same list with unique log files) passes apart from the known certificate line.
- Writable: `characters/nova/Nova.gd`, `characters/yuki/Yuki.gd`, `characters/rio/Rio.gd` (row tables + pose calls only), `tests/test_moves_sheet.gd`, `reports/codex-art-29/**`. Hard stop 30 minutes after you start. Report `reports/codex-art-29/README.md` (Korean) + `commit.ps1` (message ending `Co-Authored-By: Codex <noreply@openai.com>`).
