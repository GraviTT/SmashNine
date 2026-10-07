# CODEX-ART-02 · Original Frey sprite sheet (replacement candidate)

- Request: 사용자 "다음 작업은? 가능하면 그래픽, 캐릭터 개발, 대규모 수정 쪽으로." (2026-10-07, 근무 루틴 `routine/2026-10-07-work/`)
- Unit: Builder · Lead (integrates, decides): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine`, branch `codex/frey-art-01`
- Running at the same time: Codex builder `codex/art-01` (center realm art). The lead edits product source meanwhile. **This task does not edit product source.**
- Timeout: 90 minutes. Deliver whatever is finished before then.

## Read first

1. `AGENTS.md`, `smash-nine-prototype/characters/frey/Frey.md` (identity: Valkyrie bruiser, sword + shield, heavy, readable)
2. `smash-nine/Concept1.png`, `Concept2.png` (attached): Frey in the roster panel (blonde Valkyrie) and the art-style panel
3. The current placeholder (third-party Viking art, to be replaced): `smash-nine-prototype/assets/characters/frey/frey_prototype.png` and how it is cut in `characters/frey/Frey.gd` `configure_character_sprite()`; draw settings in `characters/common/PlayerBase.gd` `get_character_sprite_style()` (position (0,-32), scale 2, nearest filter); collision box 42x64 with feet at y=0

## Goal

An **original** Frey sprite sheet that is a drop-in replacement for `frey_prototype.png`: same layout so the lead only swaps the texture.

| Row (6 columns, 64x64 cells, sheet 384x448) | Frames | Notes |
| --- | --- | --- |
| 0 idle | 4 | breathing, sword lowered, shield forward |
| 1 walk | 6 | run cycle |
| 2 jump | 1 | rising |
| 3 fall | 1 | falling |
| 4 attack | 4 | horizontal sword swing, clear wind-up -> active -> recovery |
| 5 shield | 6 | guard pose, shield raised (frames may repeat) |
| 6 hurt | 1 | knocked back |

Unused cells transparent. Facing right. Feet on the same bottom row and the character centred at the same x in every frame, so the game's feet-at-origin placement holds. Pixel art, limited palette, blonde Valkyrie with winged helm, sword and round shield; must read clearly at 2x scale on dark backgrounds. Identity must stay consistent across frames (same proportions, colours, gear).

Generate larger and reduce to the 64x64 grid with nearest-neighbour; clean with Godot's Image API from a script or the bundled runtime; do not install packages.

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `smash-nine-prototype/assets/art/frey/**` | `frey_sheet.png` (+ `.import`), `README.md`, intermediate frames |
| `smash-nine-prototype/tests/art_preview/frey/**` | preview scripts (e.g. play the animations in Godot) |
| `reports/codex-art-02/**` | report, contact sheet, screenshots, an animated preview if you can |

Forbidden: product source, existing tests, `design/`, merging, pushing, installing packages, downloading files.

## Verification

- A preview script that loads `frey_sheet.png` with the same AnimatedSprite2D cut as `Frey.gd` and screenshots each animation at 2x next to the old placeholder, on a dark background.
- Report measured facts (cell alignment: feet row and centre x per frame) separately from taste. Taste is the user's call.

## Done when

- [ ] `frey_sheet.png` 384x448, `reports/codex-art-02/README.md` in Korean (prompts, consistency issues, alignment table, what a human must judge)
- [ ] Commit, or `reports/codex-art-02/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`
