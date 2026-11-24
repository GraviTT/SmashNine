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

**Move rows (2026-11-24):** `xion_moves_sheet.png` holds the user's pick in the pick cup round `2026-11-24` (item `xion-moves`, the new rows won against the stand-in). Ten rows of CODEX-SKM-06 (`art/bakeoff/xion/b/xion-<row>-v1.png`, drawn from the B look) sit in their `Xion.MOVE_SHEET_ROWS` slots: 192-px cells, six frames, feet y=152. The skill session rebuilt the sheet; the report is `reports/xion-skill-art-2026-11-24/README.md`.

Still stand-ins:

- the `shot_air_down` row of `xion_moves_sheet.png` (row 5): Nova's female drawing recoloured. Both SKM-06 drafts rose 15 px with the recoil (about 4 px asked), so it waits for a redraw. `reports/xion-kit-2026-11-18/make_standin_art.py` made it.
- `xion_portrait.png`: only a fallback; the menus use `xion_face.png`.

The game draws her double from her own frames with a code hologram (`characters/xion/XionDouble.gd`), so it has no art of its own.
