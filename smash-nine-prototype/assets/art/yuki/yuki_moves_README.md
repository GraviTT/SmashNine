# Yuki sheets (redrawn 2026-10-14, D33–D37)

Both Yuki sheets were rebuilt from the accepted motion-viewer candidates (`art/bakeoff/yuki/`, cards `design/tasks/CODEX-ART-48.md` and `CODEX-ART-49.md`) with `tools/sprite_pipeline/assemble.py`, pixel for pixel. The method is the Frey and Luna method (`reports/frey-rework-2026-10-14.md`).

Detail target for Yuki: at least 90 % of her old idle's interior detail (≥ 80). Her black hair and dark clothes give less contrast than Frey's or Luna's, so the flat 90 does not apply.

## `yuki_sheet.png`: base sheet (128 px, feet y=120, rows `Yuki.SHEET_ROWS`)

| Row | Frames | FPS | Source |
| --- | ---: | ---: | --- |
| idle | 6 | 6.3 (D37) | `yuki-idle-v2` (the anchor, 2.5 heads) |
| walk | 6 | 10 | `yuki-walk-v1` |
| jump | 1 | 1 | `yuki-jump-v1` |
| fall | 1 | 1 | `yuki-fall-v1` |
| attack | 6 | 28.5 | `yuki-attack-v1`: a fallback only, since every J plays a talisman row |
| shield | 6 | 12 | `yuki-shield-v1` |
| hurt | 1 | 1 | `yuki-hurt-v1` |

## `yuki_moves_sheet.png`: move sheet (192 px, feet y=152, D34)

| Row | Frames | FPS | Move | Source |
| --- | ---: | ---: | --- | --- |
| `talisman_side` | 6 | 28.5 | neutral/side J: a quick straight throw | `yuki-talisman_side-v3` |
| `talisman_up` | 6 | 25 | up/air-up J | `yuki-talisman_up-v1` |
| `ground_ward` | 6 | 23.1 | down J: slaps a talisman on the ground | `yuki-ground_ward-v2` (re-normalised to the anchor head) |
| `talisman_air_side` | 6 | 33.3 | air-side J | `yuki-talisman_air_side-v1` |
| `talisman_air_down` | 6 | 22.2 | air-down J | `yuki-talisman_air_down-v2` (re-normalised to the anchor head) |
| `seal_place` | 6 | 18.7 | K: places a binding seal | `yuki-seal_place-v1` |
| `seal_activate` | 6 | 19.2 | L: hand sign, palms out | `yuki-seal_activate-v1` |
| `grand_ward` | 6 | 9.7 | I: the Four-Direction Grand Ward ritual | `yuki-grand_ward-v1` |
| `tumble` | 6 | 21, loop | **new** strong-launch hitstun (before: the hurt frame) | `yuki-tumble-v2` (re-normalised to the anchor head) |

No effects are drawn into these frames. The game draws the talismans in flight, the waves, the seals, the barrier and the pulses.
