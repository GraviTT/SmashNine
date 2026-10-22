You are the same Codex builder unit, continuing CODEX-ART-73 (story dialogue portraits) in this clone, branch `codex/art-73`. Read `design/tasks/CODEX-ART-73.md` and your own `reports/codex-art-73/README.md` again.

## The lead's review
The lead looked at all eight boards. The 24 edits read well: the same person, the same framing, clear expressions at the dialogue size. They are not rejected. What is left is exactly what you named: outside the face the generator re-rendered every pixel a little (hair strands, armour shading, alpha at the edge).

## The fix: composite the new expression onto the neutral
**The lead specifically instructs you to do this with Python and Pillow.** This is the post-processing step the project uses for every generated asset; it is not drawing the expression by code.

For each of the 24 edits:
1. **Align.** Find the integer offset (±4 px) that best lines the edit up with the neutral, measured on the face outline and the hair fringe, not on the eyes or mouth.
2. **Mask.** A feathered mask that covers only what the expression changes: both eyes, both brows, the mouth, and the cheeks if a blush, tear, sweat drop or scratch is there. A 3–5 px margin around each feature, a 3–4 px feather. Make the mask per form from the neutral (the features sit in different places); one mask may serve the three expressions of a form.
3. **Paste** the aligned edit into the neutral through the mask. Outside the mask every pixel, alpha included, equals the neutral exactly.
4. **Check:**
   - outside the mask: 0 changed pixels (measure it)
   - the seam: on a 4× crop of the feather band, no visible edge, no doubled line, no colour step (look at it, and measure the mean difference between the edit and the neutral inside the band)
   - the expression still reads at 142×164
5. If the edit's face moved or tilted so its features do not sit on the neutral's face (the jaw, the nose or the eyes land in the wrong place, or the seam shows), redo that edit with the image tool, asking it to keep the head and the face position exactly. Up to 2 more tries, then report the best one.

Also:
- **Yuki `hurt`**: you found it weak at the dialogue size. One more edit with a clearer pain: brows up and together, eyes narrowed or half shut, mouth tight or open, a sweat drop. Keep the better of the two.

## Output
- Replace the 24 `art/bakeoff/<folder>/<stem>_face-<expression>-v1.png` with the composites. In each `.json`:
  - `review_status: "candidate"`, `delivered: true`
  - `edited_from`
  - `composite`: `{"mask_bbox", "feather", "offset"}`
  - `note` in Korean
- Boards `reports/codex-art-73/<stem>-faces.png` again, with labels `neutral` / `happy` / `angry` / `hurt` (no "REJECTED"), at 1× and at 142×164, and a third row: a 4× crop of the face with the mask outline drawn thinly, so the lead can check the seam.
- Update `reports/codex-art-73/README.md` (Korean): the method, per image the offset, the outside-mask change (should be 0) and the seam measure, what you redid, what is still weak.
- Write `commit.ps1` again (only your files, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, and include this prompt file). Do not run it.

## Rules
- Write only the card's writable paths. Nothing under `smash-nine-prototype/` changes.
- Running at the same time in other clones: ART-74 and ART-76 (monsters), ART-75 (character motions) and QA-21 (bug hunt, Godot). Do not run Godot.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`; `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads.
- Hard stop: 90 minutes.
- Final answer in Korean, short: a table per form and expression (offset, outside-mask change, seam measure, redone or not), and what is still weak.
