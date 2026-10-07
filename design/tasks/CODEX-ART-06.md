# CODEX-ART-06 · Brave Luna sheet and title logo

- Request: 사용자 "특히 캐릭터 스프라이트 좋음." (2026-10-07, 근무 루틴 `routine/2026-10-07-work-2/`, 라운드 4 — 남는 시간 작업)
- Unit: Builder · Lead (integrates, decides): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/luna-brave-a`
- Running at the same time: Codex analyst `codex/review-b` (runs headless bot matches; keep your Godot runs short). The lead edits product source. **This task does not edit product source.**
- Timeout: given in the prompt. Priority: 1 Brave Luna sheet, 2 title logo.

## Read first

1. `smash-nine-prototype/characters/luna/Luna.md` (her ultimate turns her into "Brave Luna", a fast melee striker with punches and kicks for about 6 s) and `assets/art/luna/luna_sheet.png` + `README.md` (her accepted normal form).
2. `assets/art/frey/README.md`: the sheet contract every fighter uses.
3. `smash-nine/Concept1.png`, `Concept2.png` (attached): logo style in the top-left corner. Rolled at random: keep the broad frame, redesign freely.

## Deliverables

| File | Size | Contract |
| --- | --- | --- |
| `smash-nine-prototype/assets/art/luna/luna_brave_sheet.png` | 384x448 | Same contract as `luna_sheet.png` (6 columns x 7 rows of 64x64: idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1; facing right; feet at y=48; centre x≈32). Same girl, transformed: starlight gauntlets and boots, a fighter's stance; attack row = a fast punch/kick combo; shield row = crossed glowing arms. Must read as the same character as `luna_sheet.png` |
| `smash-nine-prototype/assets/art/ui/title_logo.png` | about 640x200, transparent | "SMASH NINE REALMS" pixel-art logo for the start screen, drawn at scale 1 over a dark painted background; must stay legible at 50% |

Generate larger and reduce with nearest-neighbour; clean with Godot's Image API from a script; do not install packages or download files.

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `smash-nine-prototype/assets/art/luna/luna_brave_*` | the Brave sheet, its generated source, notes appended to a new `luna_brave_README.md` |
| `smash-nine-prototype/assets/art/ui/title_logo*` | the logo and its source |
| `smash-nine-prototype/tests/art_preview/luna_brave_a/**` | preview / verification scripts |
| `reports/codex-art-06/**` | report, contact sheet |

## Verification and done

- Alignment table for the Brave sheet; a contact sheet with `luna_sheet.png` and `luna_brave_sheet.png` side by side at 2x; the logo at 100% and 50% on a dark background.
- `reports/codex-art-06/README.md` in Korean: what was made, verification, what a human must judge, what was not done.
- Commit, or `reports/codex-art-06/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
