# Nova male sheets (redrawn 2026-10-14, D33–D37)

Both sheets were rebuilt from the accepted motion-viewer candidates (`art/bakeoff/nova/nova_male-*`, cards `design/tasks/CODEX-ART-51.md` and `CODEX-ART-52.md`) with `tools/sprite_pipeline/assemble.py`, pixel for pixel. The method is the Frey method (`reports/frey-rework-2026-10-14.md`).

## `nova_male_sheet.png`: base sheet (128 px, feet y=120, rows `Nova.SHEET_ROWS`, shared by both bodies)

| Row | Frames | FPS | Source |
| --- | ---: | ---: | --- |
| idle | 6 | 6.3 (D37) | `nova_male-idle-v2` (the anchor, 2.5 heads) |
| walk | 6 | 10 | `nova_male-walk-v1` |
| jump | 1 | 1 | `nova_male-jump-v1` |
| fall | 1 | 1 | `nova_male-fall-v1` |
| attack | 6 | 35.25 | `nova_male-attack-v1`: a fallback only |
| shield | 6 | 12 | `nova_male-shield-v1` |
| hurt | 1 | 1 | `nova_male-hurt-v1` |

## `nova_male_moves_sheet.png`: move sheet (192 px, feet y=152, D34)

| Row | Frames | FPS | Move | Source |
| --- | ---: | ---: | --- | --- |
| `vector_side` | 6 | 35.25 | neutral/side J: a dashing punch | `nova_male-vector_side-v1` |
| `vector_upper` | 6 | 33 | up J: a rising uppercut | `nova_male-vector_upper-v1` |
| `compression_stomp` | 6 | 26.1 | down J: a gravity stomp | `nova_male-compression_stomp-v1` |
| `air_side` | 6 | 40 | aerial side J: a flying punch | `nova_male-air_side-v1` |
| `meteor_kick` | 6 | 30 | aerial down J: the meteor kick | `nova_male-meteor_kick-v1` |
| `vector_shift` | 6 | 27.3 | K: pure acceleration | `nova_male-vector_shift-v1` |
| `gravity_brake` | 6 | 14.3 | L: a full stop and a burst | `nova_male-gravity_brake-v1` |
| `slingshot_start` | 6 | 14 | ultimate, first press: conjuring the core | `nova_male-slingshot_start-v1` |
| `tumble` | 6 | 21, loop | **new** strong-launch hitstun | `nova_male-tumble-v1` |

No effects are drawn into these frames. The game draws the trails, shockwaves, bursts and the gravity core.
