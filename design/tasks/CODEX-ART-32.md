# CODEX-ART-32 · Frey move rows redone with one scale and one generation per row (pilot)

- Request: 사용자 2026-10-11 (motion viewer https://claude.ai/artifact/188Ryqb526Ue58MDf4BnbU): "이렇게 보니 확실히 스프라이트의 어색함이 많이 보이네. 하나의 모션에서도 일관성이 없고 특히 Frey의 spike_followup은 심각한 수준." Pilot for every move sheet; the same method goes to Luna, Brave Luna, Nova, Rio and Yuki once Frey passes.
- Unit: Builder (images) · Clone `SmashNine-units/builder-art/SmashNine`, branch `codex/frey-redo-32`. Nothing else runs. Product code untouched (the row table in `Frey.gd` stays: same row names, order and frame counts).
- Read first: `assets/art/frey/frey_sheet.png` (the reference: idle row), `frey_illustration.png`, `frey_moves_sheet.png` + `frey_moves_README.md`, `characters/frey/Frey.md` (what each move does), `reports/codex-art-23/README.md`, `reports/codex-art-28/README.md`, `tools/motion_viewer/README.md`.

## What is wrong (lead, measured by eye on the sheet; your audit must put numbers on it)
- Scale jumps inside a row: `spike_followup` frame 3 is about half the idle size, frame 4 about 1.5×; `descent` 4 small, 5 large; the `tumble` row is smaller than idle.
- Frames of one row come from different generations (ART-23 and ART-28 redraws), so face, proportions and rendering differ frame to frame; `descent` 2–3 are back views (a mass of hair and cape).
- Cause: every frame was resized on its own to fit its cell. A pose with a long sword got shrunk with its body; a small generated pose got enlarged.

## Do (hard stop 100 minutes after you start)
1. **Scale audit first** — `tests/art_preview/frey_redo_32/scale_audit.gd` (or your bundled runtime): estimate each frame's character scale relative to the idle frame of `frey_sheet.png` (e.g. best-matching scale of the head/helmet region by template matching over 0.5–1.8×, or another method you show to be robust), print a per-row table (min, max, spread). Record the numbers for the current sheet.
2. **One generation per row**: generate all frames of a row together in one image (a horizontal strip of the row's poses), with the idle sprite and the illustration as reference images and the instruction that every pose is the same character at the same size as the reference sprite. Prefer editing from the reference sprite over drawing from scratch. Face (or at least helmet and profile) visible in every frame; no back views.
3. **One scale for the whole sheet**: post-process every frame with the same factor (the one that maps the reference idle to the live idle size). Never fit a frame to its cell. When a pose does not fit 128×128 at that scale, regenerate the pose tighter (sword angled, effect shorter) instead of shrinking it. Effects may be trimmed with an irregular, dithered edge.
4. Same palette and outline as `frey_sheet.png` (quantize to its palette), hard alpha, feet on y=120 for ground frames, air frames centred like jump/fall.
5. Order: `spike_followup`, `descent`, `tumble`, then the other five rows. Up to 3 generations per row; keep the best and say which rows still fall short.

## Done when
- Scale audit: every frame within ±8% of idle (list any exception with its reason, e.g. a deliberate squash frame).
- `tests/art_preview/moves_23/edge_audit.gd` 0, `tests/art_preview/margin_30/margin_audit.gd` 0, `tests/test_sprite_frames.gd`, `test_moves_sheet.gd`, `test_frey_kit.gd`, `test_sprite_pose.gd` pass.
- Contact sheets in `tests/art_preview/frey_redo_32/`: before/after per row at 1× and 3×, each row next to the idle frame, with the measured scale under every frame.
- Writable: `assets/art/frey/frey_moves_sheet.png` (+ `.import`), `assets/art/frey/frey_moves_README.md`, `tests/art_preview/frey_redo_32/**`, `reports/codex-art-32/**`. Keep image-gen originals named `*_source.png`; previews under ~15 MB.
- Report `reports/codex-art-32/README.md` (Korean): the audit method, before/after scale table per row, prompts, what a human must judge. `commit.ps1` (writable paths only, message ending `Co-Authored-By: Codex <noreply@openai.com>`).
