You are the Codex image builder unit of SmashNine, third pass on design/tasks/CODEX-DOC-02.md. Same clone and branch (codex/doc-02). Change only reports/sprite-audit-2026-10-16/images/08-rio-head.png, then rebuild contact.png and update images.md. Same rules: real sprites only, no image_gen, Pillow text, title and captions unchanged.

The lead reviewed 08. The full figures do not show the point for the female crouching rows (low_sweep, dimension_slash): their heads sit lower because of the pose, so the height guides read as "lower", not "smaller". The labels "Rio 남" and "Rio 여" are also struck through by the guide lines.

Redo the panels as head crops:
- Two rows: male (idle, attack) and female (idle, attack, low_sweep, dimension_slash).
- From the same sheet frames you used, crop each head (hair included) and draw every crop at the same 4× scale with NEAREST. Align all crops on one chin line per row.
- Behind each crop draw a thin #ffd166 outline the size of that row's idle head, aligned on the same chin line, so a smaller head visibly does not fill it.
- Under each crop: its row name and ratio exactly as before (×1.00, ×0.76, ×0.86, ×0.72, ×0.72). Put "Rio 남" and "Rio 여" to the left of their rows, clear of any line.
- Keep the title "Rio 머리 크기 (다시 그림 후보)" and the two caption lines exactly.
Look at the result with view_image at full size and at 400×225. Final answer in Korean: what you changed.
