# CODEX-ART-67 · Effects around the characters (auras, orbits, marks, shields, seals) to the new sprites' level

- Request: 사용자 2026-10-15 "기본공격 전에, 캐릭터 주위에 들어가는 장식물, 이펙트, 오오라 등 부터 먼저 Codex에 명령해줘." These go before the basic-attack effects (ART-66 candidates wait).
- Unit: branch `codex/art-67`, clone `SmashNine-units/builder-art/SmashNine`. No other unit runs. **Candidates only**; nothing under `smash-nine-prototype/` changes.
- **Method: exactly ART-66** (`design/tasks/CODEX-ART-66.md`, `reports/codex-art-66/README.md`, its `build_fx66.py`):
  - the new sprites as the style anchor
  - the current file as the shape and timing reference
  - each file's contract kept exactly
  - compare boards on the body frame where the game shows the effect

## Which files
Every effect the game draws **on or around the fighter's body**, not along an attack path. Find them in `design/SKILLS.md` (the "이펙트" column and the passive/state rows) and in the code that parents them to the fighter or keeps them at the fighter's position. At least:

| Character | Around the body |
| --- | --- |
| all | `effects/skill/guard_bubble.png` (guard: idle, block and parry frames), `effects/parry_flash.png`, the status icons above the head if they are effect art (`StatusIcon`) |
| Frey | `effects/passive/frey_pursuit_mark.png`, `effects/passive/frey_spike_ring.png`, `vfx/frey_ult_charge.png` |
| Luna | `effects/passive/luna_star_charge.png` (the orbiting stars), `effects/skill/luna_brave_aura.png`, `vfx/luna_ult_transform.png` |
| Yuki | `effects/yuki_seal_idle.png`, `effects/yuki_seal_break.png` (placed seals), `vfx/yuki_ult_seal.png` |
| Nova | `effects/skill/nova_momentum_trail.png`, `effects/skill/nova_shift_ready.png`, `vfx/nova_ult_core.png` |
| Rio | `effects/skill/rio_rune_guard.png`, `vfx/rio_ult_circle.png`, `effects/rio_gem_sword.png` (the six orbiting swords; keep it greyscale, the game tints it) |

List anything else you find in the report, and do it if it is drawn around the body.

## Each effect follows its row
- **Size and centre:** the orbit radius, the body centre `GAME_SCALE.BODY_CENTRE`, and the head height for marks.
- **Frames and playback** as the code plays them.
- **The character's palette** from the new sprites.
- **It must not hide the body.** Keep it thin or translucent-looking in pixel terms (dithered or open shapes; alpha stays 0/1). Check at 1× and 4× on the idle and on a busy frame.

## Output (as ART-66)
- `art/bakeoff/effects/<id>/<file stem>-v1.png` (or the next free version), plus `.json` `{"note": "<plain Korean>", "replaces": "<asset path>", "frames": N, "fps": F}`
- `reports/codex-art-67/<id>/<file>-compare.png`, `prompts.txt`
- `reports/codex-art-67/README.md` (Korean, short)
- `reports/codex-art-67/commit.ps1`: no `git add -f`, nothing under `art/raw/`, no `__pycache__`
- Raw generations go to `art/raw/fx-67/` (git-ignored)

## Writable
`art/bakeoff/effects/**` (new files only), `art/raw/fx-67/**`, `reports/codex-art-67/**`. Hard stop: 120 minutes. Deliver finished characters in the table order and list the rest.
