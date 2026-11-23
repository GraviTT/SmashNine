# Xion art (2026-11-24)

Xion's own art is **B, the short coat**. The user picked it in the pick cup (round `2026-11-19`, item `xion-concept`: 5 wins of 5). It was drawn by Codex:

- ART-94: the B look
- ART-96: the idle anchor with the full scarf, and the illustration with her hologram double
- ART-97: every other row

`reports/xion-art-2026-11-19/install_b.py` installs it from `art/bakeoff/xion/b/`. The report is `reports/xion-art-2026-11-19/README.md`.

| File | From | Notes |
|---|---|---|
| `xion_sheet.png` | `xion-idle-b2`, `-walk-b2`, `-attack-b2`, `-shield-b2`, and frames of `-jump-b2` (2), `-fall-b2` (1), `-hurt-b2` (1) | 128-px cells, feet y=120, rows as `Xion.SHEET_ROWS` (idle 6, walk 8 over two rows, jump, fall, attack 6, shield 6, hurt) |
| `xion_jump.png`, `xion_fall.png`, `xion_hurt.png`, `xion_land.png` | `xion-{jump,fall,hurt,land}-b2` | the shared motion rows (`OPTIONAL_MOTION_ROWS`), 128-px cells |
| `xion_victory.png`, `xion_defeat.png` | `xion-{victory,defeat}-b2` | 192-px cells, feet y=152 |
| `xion_illustration.png` | `xion_illustration-b2` | 1024×1536. Her other-timeline double stands behind her as a crimson hologram, drawn with the game's hologram formula (`XionDouble.gd`) |
| `xion_face.png` | `xion_face-b` | 256×256, cut from her figure only |

Still stand-ins:

- `xion_moves_sheet.png`: Nova's female rows recoloured, under Xion's row names (`Xion.MOVE_SHEET_ROWS`). The skill session makes the real rows, effects and icons from this look with Codex, and the user picks them in the pick cup (D49). `reports/xion-kit-2026-11-18/make_standin_art.py` rebuilds the stand-in.
- `xion_portrait.png`: only a fallback; the menus use `xion_face.png`.

The game draws her double from her own frames with a code hologram (`characters/xion/XionDouble.gd`), so it has no art of its own.
