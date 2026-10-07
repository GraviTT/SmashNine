# CODEX-ART-07 · Realm hazard effect art

- Request: 사용자 "더 오래 할수 있도록 아직 구현 안된 부분들을 더 추가하여 계획서를 작성" (2026-10-07, 근무 루틴 `routine/2026-10-07-work-2/`, 라운드 5 — 남는 시간 작업)
- Unit: Builder · Lead (integrates, decides): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/hazards-a`
- Running at the same time: Codex analyst `codex/review-b` (headless matches). **This task does not edit product source.**
- Timeout: given in the prompt (short). Priority order below; deliver what is finished.

## Read first

`smash-nine-prototype/scripts/realms/RealmHazards.gd` (how each hazard is drawn now: coloured rects and particles), `RealmCatalog.gd` (hazard sizes), the accepted realm art in `assets/art/realm_{vanaheim,asgard,muspelheim}/`.

## Deliverables (PNG RGBA, transparent, nearest-neighbour pixel art, in `smash-nine-prototype/assets/art/hazards/`)

| # | File | Size | Use |
| --- | --- | --- | --- |
| 1 | `vine_bridge.png` | 3-slice strip 24 px tall: 24 px left cap, 48 px repeatable middle, 24 px right cap (96x24) | Vanaheim's temporary one-way vine bridge (150–400 px wide in game) |
| 2 | `light_beam.png` | 64x128, tiles vertically | Asgard's falling light column (stretched to 70 px wide, any height) |
| 3 | `fire_pillar.png` | 64x128, tiles vertically | Muspelheim's fire pillar (stretched to 80 px wide, 460 px tall) |
| 4 | `vent_glyph.png` | 80x16 | glowing spot on the platform under a warning column (gold for Asgard if tinted, orange as drawn) |

`README.md` in the folder: prompts, how each file tiles or slices.

## Writable paths

`smash-nine-prototype/assets/art/hazards/**`, `smash-nine-prototype/tests/art_preview/hazards_a/**`, `reports/codex-art-07/**`. Everything else is read-only.

## Done

- A preview composing each item at game size on its realm background; `reports/codex-art-07/README.md` in Korean.
- Commit, or `reports/codex-art-07/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
