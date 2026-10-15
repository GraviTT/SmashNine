# CODEX-TOOL-02 · Game clips of the effects around the characters (guard, auras, orbits, marks, seals, ultimates)

- Request: 사용자 2026-10-15 "캐릭터 주위에 들어가는 장식물, 이펙트, 오오라 등 부터 먼저" and "이펙트 볼수 있게 on/off 추가". The candidates are in `art/bakeoff/effects/` (ART-67, `reports/codex-art-67/README.md`). The user picks them by watching the game.
- Unit: branch `codex/tool-02`, clone `SmashNine-units/builder-ui/SmashNine`. No other unit runs.
- **Extend** `smash-nine-prototype/tests/capture_move_clips.gd` (TOOL-01, fixed by the lead: fighters stand on the floor; camera zoom 1.8) and `reports/codex-tool-01/encode_clips.py`. Keep the J clips exactly as they are.

## New scenes ("scenario" entries, same fx/nofx capture, same 30 fps WebP)
Each scene plays the game's own code; do not fake an effect. Where a scene needs a target, put a **training dummy** (`PLAYER_FACTORY.create()` + `setup_dummy`, as `tests/test_hit_sparks.gd` does) in front of the fighter. Keep the dummy visible in both fx and nofx. Use whatever input or state the game uses.

| Form | Scene (move id) | Shows |
| --- | --- | --- |
| all six forms | `guard` | hold guard 0.6 s, take a hit, then a parry hit (guard bubble idle/block/parry, `parry_flash`) |
| frey | `pursuit` | ↑J launches the dummy (pursuit mark above it) |
| frey | `spike` | L hits, the re-press window ring shows, L again |
| frey | `ultimate` | I on the ground (charge and waves) |
| luna | `star-charge` | J hits until 3–5 stars orbit |
| luna | `transform` | I: the 12-frame transformation |
| luna_brave | `aura` | Brave idle 1.5 s with the aura |
| yuki | `seals` | K twice (two seals idle), then a hit breaks one |
| yuki | `ultimate` | I: the grand ward seal field |
| nova | `momentum` | run at full speed 1 s (the trail), then K (shift dash), then the shift-ready signal |
| nova | `ultimate` | I, I, I: core, orbit, launch |
| rio | `rune` | L while the dummy hits it (rune guard and burst) |
| rio | `ultimate` | I: circle and six gem swords |
| one form | `status` | stunned and super-armored once each (the status icons) |

- The camera may follow a scene (or zoom out) when the action leaves the box. Record the zoom in the manifest.
- Write the scenes into the same `art/clips/manifest.json`, with a `group`: `j` for the J clips, `around` for these. Rows can be empty.

## The viewer
`tools/motion_viewer`: the **게임 화면** section shows the two groups under their own headings, **기본 공격** and **캐릭터 주위 이펙트**. Keep the `끔 / 지금 / 새 후보` modes; `art/clips-new` is filled by the lead later.

## Checks
- Every scene shows its effect in the fx clip, and nofx shows none. Measure the difference around the fighter and the dummy.
- Every scene starts and ends in a steady state. The fighter never leaves the clip, and no clip times out.
- **Look at a middle frame of every new clip yourself.** TOOL-01 shipped 72 clips without a fighter in them because nobody looked.
- The full Godot suite still passes.

## Output
- the extended `capture_move_clips.gd`, the encoder if changed
- the new clips in `art/clips/<form>/<scene>-{fx,nofx}.webp` and the manifest
- the viewer changes
- `reports/codex-tool-02/README.md` (Korean, short)
- `reports/codex-tool-02/commit.ps1`: no `git add -f`, no `__pycache__`

## Writable
`smash-nine-prototype/tests/capture_move_clips.gd`, `reports/codex-tool-01/encode_clips.py`, `art/clips/**`, `tools/motion_viewer/build.mjs`, `tools/motion_viewer/index.html`, `tools/motion_viewer/README.md`, `reports/codex-tool-02/**`. Hard stop: 110 minutes.
