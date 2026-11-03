# Nova female sheets (redrawn 2026-10-14, D33–D37)

Both sheets were rebuilt from the accepted motion-viewer candidates (`art/bakeoff/nova/nova_female-*`, cards `design/tasks/CODEX-ART-51.md` and `CODEX-ART-52.md`) with `tools/sprite_pipeline/assemble.py`, pixel for pixel. The method is the Frey method (`reports/frey-rework-2026-10-14.md`).

## `nova_female_sheet.png`: base sheet (128 px, feet y=120, rows `Nova.SHEET_ROWS`, shared by both bodies)

| Row | Frames | FPS | Source |
| --- | ---: | ---: | --- |
| idle | 6 | 6.3 (D37) | `nova_female-idle-v2` (the anchor, 2.5 heads) |
| walk | 6 | 10 | `nova_female-walk-v1` |
| jump | 1 | 1 | `nova_female-jump-v1` |
| fall | 1 | 1 | `nova_female-fall-v1` |
| attack | 6 | 35.25 | `nova_female-attack-v1`: a fallback only |
| shield | 6 | 12 | `nova_female-shield-v1` |
| hurt | 1 | 1 | `nova_female-hurt-v1` |

## `nova_female_moves_sheet.png`: move sheet (192 px, feet y=152, D34)

| Row | Frames | FPS | Move | Source |
| --- | ---: | ---: | --- | --- |
| `vector_side` | 6 | 35.25 | neutral/side J: a dashing punch | `nova_female-vector_side-v3` |
| `vector_upper` | 6 | 33 | up J: a rising uppercut | `nova_female-vector_upper-v1` |
| `compression_stomp` | 6 | 26.1 | down J: a gravity stomp | `nova_female-compression_stomp-v1` |
| `air_side` | 6 | 40 | aerial side J: a flying punch | `nova_female-air_side-v1` |
| `meteor_kick` | 6 | 30 | aerial down J: the meteor kick | `nova_female-meteor_kick-v1` |
| `vector_shift` | 6 | 27.3 | no longer played (was K Pure Acceleration before D47) | `nova_female-vector_shift-v1` |
| `gravity_brake` | 6 | 14.3 | no longer played (was L Gravity Brake, then the D47 orb stand-in) | `nova_female-gravity_brake-v1` |
| `slingshot_start` | 6 | 14 | ultimate, first press: conjuring the core | `nova_female-slingshot_start-v1` |
| `tumble` | 6 | 21, loop | **new** strong-launch hitstun | `nova_female-tumble-v1` |
| `orb_throw` | 6 | 16 | K Gravity Orb: hands gathered, the throw at frame 3 | `nova_female-orb_throw-v1` (CODEX-SKM-05) |
| `gravity_beam` | 6 | 18 | U Gravity Beam: aim, palm shot, hold (1–3); on a hit the fist pull and the catch (4–6) | `nova_female-gravity_beam-v1` (CODEX-SKM-05, lead-passed) |
| `field_fly` | 6 | 10, loop | L field: flying in her own field, off the floor | `nova_female-field_fly-v1` (CODEX-SKM-05) |
| `zero_gravity` | 6 | 13 | L Gravity Field cast: hands pushed up | `nova_female-zero_gravity-v1` |

The last four rows were added 2026-11-03 (the lead's pick for the user's playtest); the sheet is now 1152×2496, 13 rows.

No effects are drawn into these frames. The game draws the trails, shockwaves, bursts and the gravity core.
