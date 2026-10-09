# CODEX-ART-21 · Frey and Luna sprites, frame by frame

- Request: 사용자 2026-10-10 (취침 루틴) "스프라이트의 완성도를 각 스프라이트 1프레임씩 자세히 확인하여 끌어 올렸는지" — one of seven criteria for finishing a character; Frey and Luna first. Standing request 2026-10-08: "그림이 어색해지는 것은 모두 Codex에게 맡기고".
- Unit: Builder (image) · Lead (verifies and merges): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/sprite-review-21`
- Read first: `design/DECISIONS.md` D20, D22, D25 (original art, body types, art v2 head ratios: Frey 3, Luna 2.2, 128 px cells), the character docs `smash-nine-prototype/characters/frey/Frey.md`, `luna/Luna.md` (who they are and what each move does), the illustrations `assets/art/frey/frey_illustration.png`, `assets/art/luna/luna_illustration.png` (the reference for face, costume and proportions).
- Running at the same time: Codex analyst `codex/char-qa-17` (headless matches, CPU heavy) and the lead changing Frey/Luna code. **This task does not edit product source or existing tests.**
- Timeout: given in the prompt.

## The sheets

| Sheet | Used frames (rows of a 6×7 grid, 128 px cells, feet at y=120, facing right) |
| --- | --- |
| `assets/art/frey/frey_sheet.png` | idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1 (23) |
| `assets/art/luna/luna_sheet.png` | same layout (23) |
| `assets/art/luna/luna_brave_sheet.png` | same layout (23), Brave Luna (gauntlets, melee) |

The game plays every attack, skill and ultimate from the one 4-frame `attack` row; each frame is drawn at 1 art px = 1 screen px. Known defect: Frey's attack frame 4 shows only the edge of her shield. The READMEs in those folders still describe the old 64 px atlas.

## Task 1 · Review every frame (69)

Look at each frame on its own at 4× and in sequence with its row. For each frame write one row: sheet, row/column, what it shows, problems found, severity, action. Check:
- silhouette and readability at 1×; the pose says what the move is;
- face, costume, weapon and palette match the illustration and the other frames (Frey: sword and shield, gold/steel; Luna: star wand, pink/violet; Brave Luna: starlight gauntlets);
- proportions stay on model (head ratio), no limb or prop that changes size between frames;
- clean outline: no stray pixels, halos, holes, broken lines, half-transparent fringes, cut edges;
- alignment: feet on y=120 when grounded, no jitter between frames of a loop (opaque-centroid drift);
- motion: idle and walk loop smoothly (walk has contact and passing poses), attack has anticipation → strike → follow-through, shield reads as guarding, hurt reads as being hit.

## Task 2 · Fix what the review finds

Repair or redraw the frames that need it, best first (severity × how often the frame is seen). Use your image generation tool with the illustration and neighbouring frames as reference images, and Godot's `Image` API for the clean-up (alpha cutoff, palette, outline, alignment), scripts under your art-preview folder. Frames you did not change stay pixel-identical (check it). Unused cells stay transparent.

## Task 3 · Prepare (no art): what each skill would need

For Frey and Luna (normal and Brave), list which moves share the one attack row today and propose the minimum set of extra rows (pose per frame, frame count) that would make each skill read as itself. This is material for the lead and the user; do not draw it.

## Writable paths

| Path | For |
| --- | --- |
| `smash-nine-prototype/assets/art/frey/frey_sheet.png`, `.../frey/README.md` | Frey's fixed sheet and an up-to-date atlas contract |
| `smash-nine-prototype/assets/art/luna/luna_sheet.png`, `luna_brave_sheet.png`, `README.md`, `luna_brave_README.md` | Luna's fixed sheets and contracts |
| `smash-nine-prototype/tests/art_preview/sprite_review_21/**` | review and build scripts |
| `reports/codex-art-21/**` | report, per-frame table, before/after contact sheets, generated sources you keep |

Forbidden: product source (`scripts/`, `characters/`, `scenes/`, `project.godot`), other characters' art, existing tests, merging, pushing, installing packages, downloads.

## Acceptance (the lead runs these)

- `tests/test_sprite_frames.gd` passes; `tests/analysis/lead/frame_audit.gd -- --out=<dir> <sheet>` shows no new flags.
- Before/after contact sheets per sheet at 1× and 4× (`reports/codex-art-21/contact/`), changed frames marked.

## Report (`reports/codex-art-21/README.md`, Korean)

The 69-row review table, what was fixed and how, what is still weak, the Task 3 proposal, what a human must judge. Commit, or `reports/codex-art-21/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
