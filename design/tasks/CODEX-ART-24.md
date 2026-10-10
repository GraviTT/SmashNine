# CODEX-ART-24 · Skill effects still drawn as shapes + realm markers, with wiring

- Request: 사용자 2026-10-10 20:00 "코덱스 한도 소모를 위해, 코덱스에 이미지, 스프라이트 생성 명령 내릴것." + "Claude는 명령과 검수만" — so this card includes the wiring code. Run plan: `routine/2026-10-10-work/README.md`.
- Unit: Builder (images + wiring) · Lead: Claude (reviews, merges, runs the full tests)
- Clone: `SmashNine-units/builder-frey/SmashNine`, branch `codex/skill-fx-24`
- Running at the same time: builders `codex/moves-23` (edits `PlayerBase.gd` sheet/pose functions, `Frey.gd`, `Luna.gd` pose calls) and `codex/monsters-ui-25`. Stay inside the functions named below. No windowed Godot runs; headless only.
- Read first: `assets/art/effects/README.md` (effect contract), `scripts/Vfx.gd` (SPECS, AUTHORED_WIDTH, spawn/available), how CODEX-ART-20 replaced coloured rectangles (`reports/codex-art-20/README.md`, `PlayerBase._spawn_landing_puff`, `_play_parry_effect`), the character docs `characters/*/*.md`, the attack art `assets/art/attack_vfx/` and ultimate art `assets/art/vfx/` (match their style and palette).

## Part 1 — skill effects that are always shapes today (required)
New strips in `assets/art/effects/skill/` (horizontal strips of equal frames, 1 art px = 1 screen px like ART-20, alpha 0/1 or the additive look the effects README allows, no text). For each, read the current function, match the shape's on-screen size, colour, direction and lifetime, and write the derivation in the README.

| Character | Function (file) | What it shows |
| --- | --- | --- |
| Luna | `_play_star_bloom` (Luna.gd) | star bloom of her J echo / transform charge (her signature hit) |
| Luna | `_play_moon_ring_flash` (Luna.gd) | Moon Ring (L) flash ring |
| Luna | `_create_transformation_aura` (Luna.gd) | Brave Luna looping aura (star + circle) |
| Luna | `_spawn_trail`, `_spawn_bloom_flash` (LunaComet.gd) | comet trail sparkle, comet burst flash |
| Nova | `_spawn_gravity_burst` visual (Nova.gd) + `NovaGravityBurst.gd` ring | gravity burst |
| Nova | `_update_momentum_visual` | momentum trail |
| Nova | `_play_vector_flash`, `_play_shift_flash`, `_play_shift_recharge_flash`, `_play_impact_flash`, `_play_launch_flash` | vector streak, shift dash, shift ready ring, impact star, launch flash |
| Rio | `_show_rune` (loop), `_play_rune_burst`, `_play_blink_trail` (Rio.gd) | rune counter stance, rune burst, blink afterimage |
| Rio | `_make_gem_sword` | overdrive orbit swords: use the existing `effects/rio_gem_sword.png` (wiring only) |
| Yuki | `YukiGrandWard.gd` ring and talismans (`_ready`) | grand ward ring + orbiting talismans |
| Common | `PlayerBase._create_guard_visual`, `_update_guard_visual` | guard bubble (idle, hit, parry-ready states as today's colours) |
| Common | `Attack._spawn_trail_afterimage` | attack afterimage |

- Wiring: add each to `Vfx.gd` SPECS/AUTHORED_WIDTH (`EFFECTS_DIR` with `skill/<name>`), draw the art in those functions and **keep today's shape as the fallback** (missing file or F2 prototype style). Do not change hitboxes, damage, timings or the bot.
- New test `tests/test_skill_fx_art.gd`: each listed function puts an art node (not the shape) when the file exists, and the shape when it does not. Show it fails on the old code. The lead adds it to `run_all.ps1`.
- Check: `tests/run_all.ps1 -SkipSoak` passes in your clone.

## Part 2 — realm markers (do right after Part 1)
- `assets/art/realm_center/portal_anim.png`: animated portal strip (6–8 frames, 96×96 like `portal.png`; still tinted toward the destination in code). Wire in `RealmWorld._create_portal_visual` (fallback: today's still sprite).
- `assets/art/effects/realm/`: `seal_barrier` (looping, tiles over a sealed realm), `collapse_cracks` (overlay for a collapsed realm), `warning_edge` (pulsing border for a realm about to close). Wire in `RealmWorld._create_state_overlay` above the dark tint; keep the text labels drawn in code.

## Verify and report
- Contact sheet per part in `tests/art_preview/skill_fx_24/`: every strip at 1x and 2x on three realm backgrounds next to a 128 px fighter cell for scale; headless runtime captures of a few effects in place if you can.
- Measure size, frame count, alpha, palette distance; say which ones you think are weak.
- Writable: `assets/art/effects/skill/**`, `assets/art/effects/realm/**`, `assets/art/realm_center/portal_anim.png` (+ `.import`), `assets/art/effects/README.md` (append), `scripts/Vfx.gd`, the functions named above in `characters/luna/Luna.gd`, `characters/luna/LunaComet.gd`, `characters/nova/Nova.gd`, `characters/nova/NovaGravityBurst.gd`, `characters/rio/Rio.gd`, `characters/yuki/YukiGrandWard.gd`, `characters/common/PlayerBase.gd` (guard-visual functions only), `scripts/Attack.gd` (afterimage only), `scripts/realms/RealmWorld.gd` (portal + overlay only), `tests/test_skill_fx_art.gd`, `tests/art_preview/skill_fx_24/**`, `reports/codex-art-24/**`. Keep image-gen originals named `*_source.png`; previews under ~15 MB.
- Report `reports/codex-art-24/README.md` (Korean). Commit, or `reports/codex-art-24/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
