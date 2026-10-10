# CODEX-ART-33 · Frey move sheet again: no pasted heads (fix of ART-32)

- Request: 사용자 2026-10-11: "기술 동작의 스프라이트들이 머리를 억지로 다시 붙여넣다 보니 머리가 2개가 되었다." Rules: `design/DECISIONS.md` D32 (everything inside the cell with an empty 1-px border; one head size per character, the body drawn to the head; effects drawn apart and composited) and its clarification: **no pasted heads — every frame is one drawing; the drawn head is measured and the frame scaled to it.**
- Unit: Builder · Clone `SmashNine-units/builder-art/SmashNine`, branch `codex/frey-heads-33`. Nothing else runs. `Frey.gd` row table stays.
- Read first: `reports/codex-art-32/README.md`, `tests/art_preview/frey_redo_32/build_frey_redo.gd` (line ~172–181 stamps `canonical_head`, the idle head crop, over every generated frame: that is the bug), `head_audit.gd` (it measured the stamped head, so it reported 1.000 everywhere and read an old frame that is visibly ~1.4× as 0.70).

## Forbidden
- Pasting, stamping or blending any head, face or body part from another image into a frame. No per-part compositing of the body at all. The only things composited are the effect layer over the body layer (rule 3).
- Any body pixel operation you do not list in the report. List every one: crop, scale factor per frame, palette quantization, trims.

## Do (hard stop 100 minutes after you start)
1. **Fix the audit first, and prove it.** Measure the head that is drawn in the frame (e.g. face box from skin and eye pixels, eye spacing, or template matching that you validate). Validate on synthetic frames: the idle frame scaled 0.70 / 0.85 / 1.00 / 1.20 / 1.40 must read back within ±3%; the ART-32 composite (pasted heads) and a synthetic frame with two heads must be flagged. Add a **double-head check**: per frame, the number of eye clusters in Frey's eye colours is at most 2 (one face). Report the validation table.
2. **Body layer, one drawing per frame, one generation per row.** Put the idle sprite inside the same generated image as a scale anchor (left slot of the strip), ask for the row's poses at exactly the anchor's size, face or profile visible. Reuse the ART-32 body generations only if they had no head problem before the stamping step (check the `*_source.png` originals).
3. **Scale by the measured head.** One factor per row from the anchor; then each frame's drawn head must be within ±5% of the idle head (the audit decides). A frame outside that is regenerated or edited as a whole drawing — never scaled on its own beyond what makes its own head match, never given another head.
4. Effects layer as in ART-32, composited over the body; rule 1 (zero opaque pixels on every cell's 1-px border), feet y=120 on ground frames, palette and hard alpha as in ART-32.
5. Outputs as in ART-32: `frey_moves_body_sheet.png`, `frey_moves_fx_sheet.png`, `frey_moves_sheet.png`, `frey_moves_heads.json` (head boxes as **measured**, not stamped), README.

## Done when
- Validation table passes; every frame: one head (eye-cluster check), drawn head within ±5% of idle.
- `test_sprite_frames.gd`, `test_moves_sheet.gd`, `test_frey_kit.gd`, `test_sprite_pose.gd` pass; `--headless --import` exits 0.
- Contact sheets in `tests/art_preview/frey_heads_33/`: every row at 3× with the measured head box drawn on each frame and its scale and eye count under it; before (ART-32) / after.
- No `.csv` inside `smash-nine-prototype/` (use `.txt` or put tables in `reports/codex-art-33/`).
- Writable: the five Frey files above (+ `.import`), `tests/art_preview/frey_heads_33/**`, `tests/art_preview/frey_redo_32/head_audit.gd` (may be replaced), `reports/codex-art-33/**`. Report `reports/codex-art-33/README.md` (Korean) + `commit.ps1` (writable paths only, message ending `Co-Authored-By: Codex <noreply@openai.com>`).
