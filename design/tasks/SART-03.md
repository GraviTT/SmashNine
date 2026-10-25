# SART-03 · ART-70 repairs: the root picture's talismans, a start-card frame, a set audit (candidates)

- Request: the user, through the status-check session, 2026-10-25: the Codex quota was reset; work that needs no user decision, mainly image and sprite repairs and additions. Story mode area (D43): repair ART-70 where its pieces do not match.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine`, branch `codex/sart-03` (continues from `codex/sart-01`; all from tag `checkpoint-2026-10-25`). Lead: Claude (reviews every image at full size).
- Running at the same time: another SART unit in the other story clone. Other sessions run their own units. You share no files with anyone.
- **Candidates only.** Nothing under `smash-nine-prototype/` changes; `assets/art/story/` keeps today's files.
- Read first: `smash-nine-prototype/assets/art/story/README.md`, `reports/codex-art-70/README.md` and `PROMPTS.md`, `smash-nine-prototype/scripts/ui/StoryScreens.gd` `show_stage_card` (the start card: a plain panel at 900×520 today).

## 1. `cg_root` talismans (edit, not a new picture)

The papers floating around the broken seal ring read as archery targets (white squares with red concentric circles). In the story they are an onmyoji's talismans.

| Line | Spec |
| --- | --- |
| Base | `smash-nine-prototype/assets/art/story/cg_root.png`. Load it with `view_image` and **edit** it; keep everything else exactly: the root, ice, aurora, the broken cyan ring, the magenta light, the dark bottom quarter, the composition |
| Change | each paper becomes a **tall narrow paper strip** (about 1:3, portrait), off-white with a faint warm tint, one **abstract red brush swirl** in the middle and a short dark brush mark at the top; some strips curl or flutter; no concentric circles, **no readable writing or glyphs** |
| Size | 1600×900, opaque, as today |
| Output | `art/bakeoff/story/cg_root-v2.png` (+ `.json` with a Korean note), raw in `art/raw/story/` |
| Check | a side-by-side of today's and the edit at full size and at 1280×720, with crops of three papers at 3×; difference mask outside the papers should be near zero (report the mean difference outside a generous paper mask) |

## 2. A start-card frame (9-slice)

| Line | Spec |
| --- | --- |
| Purpose | the stage start card's panel (about 900×520 at the 1280×720 UI), in the same family as the dialogue box |
| Size | exactly **480×300**, transparent PNG, 9-slice margins **24 px** |
| Style | the same ornaments as `assets/art/story/dialogue_frame.png` (gold `#f3cd7c` / `#a8742c`, blue gem `#3d7bd9` / `#9fd2ff`, outline `#101827`), 1x pixel art; corners inside the 24×24 squares; plain stretchable double-line edges; a small centred gem on the top edge is allowed only if it stays inside the top margin and is drawn so that stretching keeps it single (else omit) |
| Centre | fully transparent |
| Output | `art/bakeoff/story/start_card_frame-v1.png` (+ JSON), a preview stretched to 900×520 with sample Korean text drawn by Pillow ("스테이지 3", "달빛 다리") |

## 3. ART-70 set audit (measure only, no changes)

Report a table for the six ART-70 files in `assets/art/story/`:
- scene pictures: size, mean brightness and saturation of the whole picture and of the bottom quarter, the contrast of white 24 px text over the bottom quarter with the dialogue backing at alpha 0.95
- frame and plate: transparent centre, every opaque pixel inside the margins, edge rows repeatable
- aura: 4 px empty margin per frame, loop seam (frame 6 vs 1), feet line y=160

Flag anything that looks out of family with the others. Fix nothing in this step; list proposals.

## Deliverables

- Candidates and JSON in `art/bakeoff/story/` (names above).
- `reports/codex-sart-03/`:
  - comparison sheets (JPEG quality 90, at most 2 MB each)
  - `README.md` in Korean: what changed, the measurements, the audit table, proposals, what a human should judge
- Commit on the branch, or `reports/codex-sart-03/commit.ps1` staging only the writable paths (not `art/raw/`), message ending `Co-Authored-By: Codex <noreply@openai.com>`.

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `art/bakeoff/story/cg_root-*`, `art/bakeoff/story/start_card_frame-*` | candidates and JSON |
| `art/raw/story/**` | raw generations (git-ignored) |
| `reports/codex-sart-03/**` | report and sheets |

Forbidden: `smash-nine-prototype/**`, `design/**`, other files in `art/bakeoff/`, other sessions' files, merging, pushing, installing packages, downloads.
