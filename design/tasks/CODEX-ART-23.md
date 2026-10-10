# CODEX-ART-23 · Per-move sprite rows (Frey, Luna, Brave Luna) + wiring

- Request: 사용자 2026-10-10 20:00 "코덱스 한도 소모를 위해, 코덱스에 이미지, 스프라이트 생성 명령 내릴것." + "Claude는 명령과 검수만" — so this card includes the wiring code. Run plan: `routine/2026-10-10-work/README.md`.
- Unit: Builder (images + wiring) · Lead: Claude (reviews, merges, runs the full tests)
- Clone: `SmashNine-units/builder-art/SmashNine`, branch `codex/moves-23`
- Running at the same time: builders `codex/skill-fx-24` (effects; also edits `PlayerBase.gd` guard-visual functions and some Luna effect functions) and `codex/monsters-ui-25`. Keep your edits inside the functions named below so the merges stay clean. No windowed Godot runs; headless only.
- Read first: `reports/codex-art-21/README.md` ("기술별 추가 행 제안" — your row list), `assets/art/frey/README.md`, `assets/art/luna/README.md`, `assets/art/luna/luna_brave_README.md`, `characters/frey/Frey.md`, `characters/luna/Luna.md`, `characters/common/PlayerBase.gd` (`ORIGINAL_SHEET_ROWS`, `_configure_original_sheet`, `_add_sheet_animations`, `_play_sprite_pose`, `_start_attack`), `characters/frey/Frey.gd`, `characters/luna/Luna.gd` (every `_play_sprite_pose` / `_start_attack` pose).

## Today
Every sheet has 7 rows (idle, walk, jump, fall, attack 4, shield, hurt). All attacks reuse the 4-frame attack row (sliced per move since 2026-10-10), so up/down/air attacks, dash strike, rising cleave, spike, descent, star bloom, comet, moon ring, transform and every Brave move look alike.

## Part 1 — Frey (required)
- `assets/art/frey/frey_moves_sheet.png`: 6 columns × 7 rows of 128×128 (768×896), rows in this order, frames left-aligned, unused cells fully transparent:
  `attack_up` 4 · `attack_down` 4 · `attack_air_side` 4 · `dash_strike` 4 · `rising_cleave` 5 · `spike_followup` 4 · `descent` 6 (poses from the ART-21 proposal).
- Same character as `frey_sheet.png` (use it and `frey_illustration.png` as image references every time): head ratio 3, same palette, outline, pixel density and body size as the idle row. Ground poses: feet on y=120. Air poses: body centre at the same height as the jump/fall rows. Alpha 0/1, no stray pixels, no text. Weapon/effect pixels may leave the body but not the cell.
- `assets/art/frey/frey_moves_README.md`: row table (name, frames, fps, which move uses it), prompts, checks.
- Wiring (product code, only here):
  - `PlayerBase.gd`: load an optional second sheet `<id>[_<body>]_moves_sheet.png` (same cell size) with a per-character row table, adding animations `<id>_<row>`; a helper that plays a move row over the move's duration (same timing rule as `_play_sprite_pose`) and **falls back to the current attack-row slice when the row is missing**. A `ArtSettings.gd` helper for the path is fine.
  - `Frey.gd`: the row table and the pose call of each move. Do not change damage, hitboxes, timings, inputs or the bot.
  - New test `tests/test_moves_sheet.gd`: with the sheet, each Frey move plays its own row; without it (path override), it falls back to the attack row. Show it fails on the old code (say how). The lead adds it to `run_all.ps1`.
- Check: `tests/run_all.ps1 -SkipSoak` passes in your clone (lead runs the soak).

## Part 2 — Luna and Brave Luna (do right after Part 1)
- `assets/art/luna/luna_moves_sheet.png` (768×640): `star_up` 4 · `star_down` 4 · `star_comet` 4 · `moon_ring` 5 · `transform` 6.
- `assets/art/luna/luna_brave_moves_sheet.png` (768×1024): `brave_combo` 6 (guard → jab → kick wind-up → body kick → spin kick → recover; jab/body kick/spin kick must read apart at 1x) · `brave_upper` 4 · `brave_low` 4 · `brave_air_side` 4 · `brave_dive` 4 · `comet_drive` 4 · `luna_breaker` 6 · `heart_laser` 6.
- References: `luna_sheet.png` / `luna_brave_sheet.png` + `luna_illustration.png`. Same rules as Part 1. READMEs next to the sheets. Wire into `Luna.gd` (pose calls and row tables only — the effect functions belong to the other builder) and extend the test.

## Part 3 — only if time remains
- `tests/art_preview/moves_23/rio_{male,female}_sheet_v2.png`: Rio's attack and shield rows redrawn at the idle row's body size (today they were shrunk per frame to fit). Do not replace the live sheets; the lead swaps them.
- A row proposal table for Nova (both bodies), Rio (both bodies) and Yuki in your report, like ART-21's.

## Verify and report
- Contact sheets in `tests/art_preview/moves_23/`: each row at 1x and 4x next to the idle frame of the same sheet (size check), plus one strip per move from a headless runtime capture if you can. Measure: feet y, body height vs idle (±4 px), alpha 0/1, palette distance.
- Self-grade per row is fine, but list the rows you think are weak — the lead decides per row.
- Writable: the new sheets and READMEs above (+ `.import` files), `scripts/ArtSettings.gd`, `characters/common/PlayerBase.gd` (sheet loading + pose functions only), `characters/frey/Frey.gd`, `characters/luna/Luna.gd` (pose calls + row tables), `tests/test_moves_sheet.gd`, `tests/art_preview/moves_23/**`, `reports/codex-art-23/**`. Keep image-gen originals named `*_source.png`. Do not commit more than ~15 MB of previews.
- Report `reports/codex-art-23/README.md` (Korean). Commit, or `reports/codex-art-23/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
