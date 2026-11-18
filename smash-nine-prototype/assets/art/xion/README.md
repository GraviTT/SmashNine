# Xion art (stand-in, 2026-11-18)

Everything here is a stand-in until Xion's own art arrives:

- the main illustration, face and base sheet from the image/sprite owner;
- the skill rows, effects and icons from Codex, chosen in the pick cup (D49).

These files are Nova's female drawings recoloured black, silver and crimson. Nova's female body holds no weapon, so she reads as unarmed rather than as a swordswoman. Blue and purple become charcoal, cyan glow becomes crimson, and white plates become silver. Skin is unchanged.

Rebuild them with `reports/xion-kit-2026-11-18/make_standin_art.py`.

| File | From | Notes |
|---|---|---|
| `xion_sheet.png` | `nova_female_sheet.png` | Same rows as Nova (`Xion.SHEET_ROWS`). |
| `xion_moves_sheet.png` | Rows of `nova_female_moves_sheet.png` | 11 rows under Xion's names (`Xion.MOVE_SHEET_ROWS`): `shot`, `shot_alt`, `shot_up`, `shot_down`, `shot_air_down`, `tumble`, `recoil_jump`, `double_cast`, `dive`, `barrage`, `double_float`. |
| `xion_jump.png`, `xion_fall.png`, `xion_land.png`, `xion_victory.png`, `xion_defeat.png` | Nova female strips | — |
| `xion_portrait.png` | `nova_female_portrait.png` | The menus use it until a painted face exists. |

When the real art comes, replace the files under the same names. The move sheet's row table is in `characters/xion/Xion.gd`.
