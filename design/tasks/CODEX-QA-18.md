# CODEX-QA-18 · Full character sprite inspection

- Request: 사용자 2026-10-13 "…그리고 다시 전체 캐릭터 점검을 위한 루틴에 들어간다." Earlier user findings this week: inconsistency inside one motion, Frey `spike_followup` severe, pasted heads (two heads), walk rows that do not walk. Rules: `design/DECISIONS.md` D32 (everything inside the cell with an empty 1-px border; one head size per character; effects drawn apart; no pasted parts). Method analysis: `reports/sprite-method-analysis-2026-10-13.md`.
- Unit: Analyst (looks at images, measures; changes no art) · Clone `SmashNine-units/analyst/SmashNine`, branch `codex/inspect-18`
- Running at the same time: builder `codex/pipeline-35` (tools only). Headless Godot or the Codex runtime Python (`C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`, numpy and Pillow); unique `--log-file` for Godot.
- Read first: `characters/common/PlayerBase.gd` (`ORIGINAL_SHEET_ROWS`), the move-row tables in `characters/*/[A-Z]*.gd` and `characters/luna/Luna.gd` (`BRAVE_MOVE_SHEET_ROWS`), the character docs `characters/*/*.md` (what each move is), `assets/art/<id>/*README*.md`.

## Inspect
All 8 bodies (frey, luna, luna_brave, nova_male, nova_female, rio_male, rio_female, yuki): every row of the main sheet (`<stem>_sheet.png`, 7 rows) and of the move sheet (`<stem>_moves_sheet.png`). Look at **every frame at 2× with view_image** (make one contact image per sheet: each row at 2× with the idle frame at the left and the numbers under each frame) and report only what you actually saw.

Per frame, by eye: exactly one face and one head; face or profile visible (no unintended back view); head size like idle; two arms, two hands, weapon intact; no smear or blur; no effects drawn into the character (glows, slashes, dust); no stray pixels; nothing cut at the cell edge.
Per row, measured: body height and width range and silhouette area spread vs idle and between consecutive frames (scale jumps), feet y on ground frames (120), colours outside the sheet's palette, partial alpha, 1-px border and 4-px margin, for `walk` the feet silhouette change (`smash-nine-prototype/tests/art_preview/walk_34/walk_feet.gd`), and the jump between this row's first frame and idle (size and position).
Also judge the motion: does the row read as that move at 1× and at its fps (contact low, float high, hair/cape lagging; anticipation and follow-through), and do idle ↔ walk and attack end ↔ idle join without a size or position pop.

## Report
- `reports/codex-qa-18/README.md` (Korean): per body a table of rows — verdict **좋음 / 손질 / 다시 그림**, the frame numbers and the reason, the numbers. Then a **priority list of the 12 rows most worth redrawing**, weighted by how often a player sees them (idle, walk, the J chain, K, L, jump/fall, hurt, then the rest) and how bad they are, with one line per row describing the motion it should show (poses per frame) so a builder can write the per-frame prompt.
- Contact images in `reports/codex-qa-18/contact/`, numbers in `reports/codex-qa-18/metrics/` (`.json` or `.txt`), scripts in `smash-nine-prototype/tests/analysis/codex_qa_18/`. No `.csv` inside `smash-nine-prototype/`.
- Writable: those three paths only. Hard stop 65 minutes after you start; if time runs short, cover the move sheets and the walk/idle rows first and say what is left. Commit, or `reports/codex-qa-18/commit.ps1` (message ending `Co-Authored-By: Codex <noreply@openai.com>`).
