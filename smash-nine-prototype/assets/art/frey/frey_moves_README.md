# Frey sheets (redrawn 2026-10-13/14, D33–D35)

Both sheets were rebuilt from the accepted motion-viewer candidates (`art/bakeoff/frey/`, cards
`design/tasks/CODEX-ART-37.md` … `CODEX-ART-41.md`) with `tools/sprite_pipeline/assemble.py`.
Strips are stacked as they are; nothing was scaled or moved again.

## How the frames were made
- One generated image per motion: 512-px cells on chroma green, one pose line per frame, no effects. The game draws slashes, streaks and shockwaves.
- `tools/sprite_pipeline/normalize.py` settings: LANCZOS + unsharp 60, green despill, no palette map, binary alpha. Each sheet uses one factor, matched to the anchor idle head with `head_scale.py` (median 0.96–1.04 in every row).
- Every frame was checked by the lead at 2–4× and by measurement:
  - 1-px border empty, 4-px margin
  - no green, interior detail ≥ 90 (the old sheets: 102)

## `frey_sheet.png`: base sheet
- 768×896, 6 columns × 7 rows, 128-px cells, feet y=120.
- Rows (Frey's own table, `Frey.SHEET_ROWS`):

| Row | Frames | FPS | Source |
| --- | ---: | ---: | --- |
| idle | 6 | 10.5 | `frey-idle-v2` (the anchor) |
| walk | 6 | 10 | `frey-walk-v2` |
| jump | 1 | 1 | `frey-jump-v1` |
| fall | 1 | 1 | `frey-fall-v1` |
| attack | 6 | 21 | `frey-attack-v4` at 128 px (git `de2dde2`, head 0.92): the J chain's fallback only |
| shield | 6 | 12 | `frey-shield-v1` |
| hurt | 1 | 1 | `frey-hurt-v1` |

## `frey_moves_sheet.png`: move sheet
- 1152×1728, 6 columns × 9 rows, **192-px cells** (D34).
- Feet y=152 and torso centre x=96, the same place on screen as y=120 and x=64 in a 128 cell.
- Drawn 1:1 next to the base sheet, so big poses keep the idle head size.

| Row | Frames | FPS | Move | Source |
| --- | ---: | ---: | --- | --- |
| attack_up | 6 | 21 | up J | `frey-attack_up-v1` |
| attack_down | 6 | 21 | down J | `frey-attack_down-v1` |
| attack_air_side | 6 | 21 | air side J | `frey-attack_air_side-v1` |
| dash_strike | 6 | 21 | K: aim 1–2, dash 3–6 | `frey-dash_strike-v1` |
| rising_cleave | 6 | 16.8 | L | `frey-rising_cleave-v2` |
| spike_followup | 6 | 21 | L follow-up | `frey-spike_followup-v3` |
| descent | 6 | 14 | I: dive and sword slam | `frey-descent-v4` |
| tumble | 6 | 21, loop | strong-launch hitstun | `frey-tumble-v3` |
| attack_chain | 6 | 21 | neutral J chain: hits at 1–2, 3–4, 5–6 | `frey-attack-v4` |

Every motion that had 4 or 5 frames now has 6, and its length is unchanged. The game spreads a
move row over the move's own duration (`_play_sprite_pose`).

The ART-33 body/FX split sheets and `frey_moves_heads.json` described the old frames and were
removed (in git history before this change).
