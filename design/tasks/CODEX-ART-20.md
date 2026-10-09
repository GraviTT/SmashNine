# CODEX-ART-20 · Short flashes: screen check and art for the last rectangles

- Request: 사용자 2026-10-09 "다음 세션에 할 것 진행." — item "사각형 대체 그림 점검: 짧게 번쩍이는 효과의 `ColorRect`를 Codex 화면 점검으로 확인" (`reports/debate-bot-ai/decision.md`); standing request 2026-10-08 "그림이 어색해지는 것은 모두 Codex에게 맡기고".
- Unit: Builder (image) + screen check · Lead (code and integration): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/flash-art-20`
- Read first: `smash-nine-prototype/assets/art/effects/README.md` (the effect art contract and palette), `scripts/Vfx.gd` (how strips are played), the functions named below, `tests/test_flash_art.gd`.
- Running at the same time: Codex analyst (bot matches, CPU heavy). **This task does not edit product source or existing tests.**
- Timeout: given in the prompt.

## Where things stand

The lead read every `ColorRect` the game creates for an effect (2026-10-09):

| Effect | Code | Today | Status |
| --- | --- | --- | --- |
| Frey ultimate charge glow, release flash | `characters/frey/Frey.gd` `_play_ultimate_charge`, `_play_ultimate_release` | a rectangle on top of the existing art | fixed by the lead: rectangle only without art |
| Yuki grand ward ending | `characters/yuki/YukiGrandWard.gd` `_play_final_effect` | a 615 px translucent square on top of `yuki_ult_burst` | fixed by the lead |
| Yuki seal burst | `characters/yuki/YukiSeal.gd` `_play_burst_effect` | a square behind `yuki_l` | fixed by the lead |
| **Parry flash** | `characters/common/PlayerBase.gd` `_play_parry_effect` | yellow 92 px square grows to 161 px in 0.13 s, centred 32 px above the feet | **needs art** |
| **Landing puff** | `PlayerBase._spawn_landing_puff` | flat 44×8 orange bar at the feet, 0.08 s, when landing out of an air attack | **needs art** |
| **Hit streak** | `PlayerBase._spawn_hit_slash` | thin pale-yellow bar (69–138 × 9 px, tilted ±26°) across the hit point, 0.07 s, with the hit spark | **needs art** |
| **Seal break** | `YukiSeal._play_break_effect` | 38 px square squashed flat in 0.12 s when a seal is hit | **needs art** |

Attack hitboxes and projectiles hide their rectangle when they draw art (`Attack.art_drawn`); hazard warning bands are deliberate telegraphs (CODEX-ART-17).

## Task 1 · Screen check (current main, before your art)

A capture script under `smash-nine-prototype/tests/art_preview/flash_art_20/` (windowed Godot, short runs) that triggers each short flash in a small arena — every row above, plus: a hit (spark + streak) at light and heavy knockback, a guard block, each fighter's basic, K, L and ultimate (`tests/capture_attacks.gd`, `tests/capture_ultimates.gd` show how), a monster bite and fireball, Yuki's seal placed / pulled / burst / broken, hazard warnings — and saves frames every 1/60 s while the flash lasts. One contact sheet per group under `reports/codex-art-20/before/`. List **every** flash that still shows a rectangle or another placeholder shape (plain bar, square, untextured polygon), with file:function, size and duration. Measured from the frames, not guessed from code.

## Task 2 · Art for the four effects marked "needs art"

| Item | Parry flash | Landing dust | Hit streak | Seal break |
| --- | --- | --- | --- | --- |
| File | `parry_flash.png` | `landing_dust.png` | `hit_streak.png` | `yuki_seal_break.png` |
| Strip | 6 frames, 128×128 cells | 5 frames, 96×32 cells | 4 frames, 160×24 cells | 5 frames, 96×96 cells |
| Anchor | centre (64,64) | bottom centre (48,31) | centre (80,12) | centre (48,48) |
| Shown | 1 art px = 1 screen px, 0.15 s | 1:1 at the feet, 0.12 s | 1:1, x stretched by the code to 69–138 px, rotated, 0.08 s | 1:1, 0.15 s |
| Look | a perfect block "clang": a gold-white ring shockwave and a sharp 4-point glint, clearly not the hit spark (white-gold starburst) | two small dust puffs rolling out left and right, warm grey with light highlights | a sharp white-gold slash line tapering to points at both ends, brightest in the middle | Yuki's waiting seal (`yuki_seal_idle.png`, ivory paper, vermilion marks) tearing into 4–6 fragments with light-blue sparks |
| Blend | additive | normal | additive | normal |

Common: the contract in `assets/art/effects/README.md` — RGBA, transparent background, binary alpha, crisp hand-clustered pixel art, dark navy outline where the shape needs one, no text, no frame, nothing touching the cell edge except deliberate glows. Last frame mostly faded. Generate with your image tool and post-process with Godot's Image API (scripts in your art_preview folder); no package installs, no downloads. Contact sheet per asset (all frames at 1x and 4x on the realm background colours `#1A1F2E` and `#7A8899`) under `reports/codex-art-20/contact/`. Add the four rows to `assets/art/effects/README.md` (file contract table and prompts).

## Writable paths

| Path | For |
| --- | --- |
| `smash-nine-prototype/assets/art/effects/parry_flash.png`, `landing_dust.png`, `hit_streak.png`, `yuki_seal_break.png`, `README.md` | the four strips and their contract rows |
| `smash-nine-prototype/tests/art_preview/flash_art_20/**` | capture and build scripts |
| `reports/codex-art-20/**` | report, before frames, contact sheets |

Forbidden: product source (`scripts/`, `characters/`, `scenes/`, `project.godot`), existing tests, other art files, merging, pushing, installing packages, downloads.

## Report (`reports/codex-art-20/README.md`, Korean)

The screen-check table (every remaining placeholder flash: what, where, size, duration, frame file), the four assets (contact sheets, measured checks: size, frame count, alpha, palette, edge margin), integration notes for the lead (anchor, scale, fps, blend), what a human must judge. Commit, or `reports/codex-art-20/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
