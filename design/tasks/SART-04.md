# SART-04 · Story map ornaments and the shadow dissolve effect (candidates)

- Request: the user, through the status-check session, 2026-10-25: the Codex quota was reset; work that needs no user decision, mainly image and sprite repairs and additions. Story mode area (D43): presentation art.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-b/SmashNine`, branch `codex/sart-04` (continues from `codex/sart-02`; all from tag `checkpoint-2026-10-25`). Lead: Claude (reviews every image at 4×).
- Running at the same time: SART-03 in the story-art-a clone. Other sessions run their own units. You share no files with anyone.
- **Candidates only.** Nothing under `smash-nine-prototype/` changes.
- Read first:
  - `smash-nine-prototype/scripts/ui/StoryScreens.gd` `show_story_map`: today a 3×3 grid of 196×152 cells, each with the realm emblem at 96 px and a status word; a plain `Line2D` path (width 5, `#777255`) through the cell centres
  - `smash-nine-prototype/assets/art/story/README.md` (the shadow aura)
  - `smash-nine-prototype/assets/art/ui/README.md` (how the 1x pixel UI icons and frames were made)

## Why

The story map shows progress only with words ("CLEAR", "Next stage", "Locked") and a flat grey line. The stage 9 shadows simply fade when defeated. Small pixel ornaments would make both read at a glance.

## Image spec

Common to all:

| Line | Spec |
| --- | --- |
| Style | crisp **1x pixel art** like the realm emblems and status icons: 1–2 px dark outline `#101827`, no anti-aliased blur, transparent background. Refs: attached 1 `ui/realm_emblems/yggdrasil_heart.png`, 2 `story/dialogue_frame.png` (gold/blue palette), 3 `story/shadow_aura.png` (violet palette). Palette: gold `#f3cd7c` / `#a8742c`, blue `#3d7bd9` / `#9fd2ff`, violet `#3b1d5e` / `#6b2fa8` / `#b98af0`, heart pink `#ff4fd8` / `#ffd6f5`, dark `#101827` |
| Text | **none**, no letters or digits |
| Avoid | faces, figures, frames around the icon, drop shadows outside the canvas, halos |
| Method | generate large and reduce to the exact canvas (nearest-neighbour, with a palette cleanup), or draw on the exact canvas with Pillow, whichever matches the refs better; say which |

| Asset | Size | Must show |
| --- | --- | --- |
| `map_path_tile.png` | **32×12**, tiles seamlessly left↔right (it will repeat along a `Line2D` in tile mode) | a thin living root of the world tree with two small leaves and a faint pink soul glow running along its middle |
| `map_marker_next.png` | strip of **6 frames of 48×48** (288×48), looping at about 8 fps | a small pink-violet soul flame with a tiny heart-shaped core, gently flickering, for the stage you play next |
| `map_seal_clear.png` | **40×40** | a round gold seal with a simple rune mark (not a letter), cleared stage |
| `map_seal_locked.png` | **40×40** | a dark iron rune lock or chain knot, muted, locked stage |
| `shadow_dissolve.png` | strip of **6 frames of 192×192** (1152×192), played once at about 12 fps | a defeated shadow's body breaking into dark violet smoke that rises and scatters into pink motes, centred at (96,152) where the fighter's feet were; frame 6 almost empty; nothing touches the cell edges (4 px margin) |

## Variants, checks, deliverables

- Two variants per asset (`-v1`, `-v2`; an edit after your own review is `-v3`). Raws to `art/raw/story/` (git-ignored). Candidates to `art/bakeoff/story/<name>-vN.png`, each with a `.json`: a Korean note, size, frames/fps where it applies, method.
- Check: exact sizes, real alpha (transparent corners, no checkerboard, no halo), the path tile's seam (left column vs right column after wrapping), loop seam of the marker (frame 6 vs 1), dissolve margins.
- Contact sheet `reports/codex-sart-04/contact.png` (or JPEG ≤2 MB):
  - every variant at 1x and 4×
  - a **mock map**: three 196×152 dark cells joined by the path tile, one with the next marker, one with the clear seal, one with the locked seal, over the game's title background colour
  - the dissolve frames at 1x behind a grey 42×96 body box
  - an animated GIF each for the marker and the dissolve
- `reports/codex-sart-04/README.md` in Korean: per asset the variants, pass/fail, method, which you recommend and why, what a human should judge.

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `art/bakeoff/story/map_*`, `art/bakeoff/story/shadow_dissolve*` | candidates and JSON |
| `art/raw/story/**` | raw generations (git-ignored) |
| `reports/codex-sart-04/**` | report and sheets |

Forbidden: `smash-nine-prototype/**`, `design/**`, other files in `art/bakeoff/`, other sessions' files, merging, pushing, installing packages, downloads.

## Done when

- [ ] Ten candidates with JSON, the contact sheet with the mock map, two GIFs, the README.
- [ ] Commit on the branch, or `reports/codex-sart-04/commit.ps1` staging only the writable paths (not `art/raw/`), message ending `Co-Authored-By: Codex <noreply@openai.com>`.
