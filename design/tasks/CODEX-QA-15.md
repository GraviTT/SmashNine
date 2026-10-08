# CODEX-QA-15 · Art QA from real game screens: what still looks awkward

- Request: 사용자 2026-10-08 "그림이 어색해지는 것은 모두 Codex에게 맡기고, 퀄리티의 문제가 있어 보이는 것들도 스스로 판단하여 보강할것."
- Unit: Tester (screens) · Lead (decides, writes art cards, integrates): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/tester/SmashNine`, branch `codex/art-qa-15`
- **This task does not edit product source, art or existing tests.** It looks, measures and reports; its findings become the next builder cards.
- Timeout: given in the prompt.

## Why

Today the combat scale doubled and realms grew 1.5x (`scripts/GameScale.gd`, decision D27); effects, backgrounds and attack strips were redrawn (CODEX-ART-13/14/15, ART-16 running). The lead wants every remaining visual that looks awkward or low quality found and fixed, judged from **what the game actually shows**, not from the source files.

## Tasks

1. **Capture real screens** (windowed Godot, one window at a time; the lead does not capture while you run):
   - `smash-nine-prototype/tests/capture_screens.gd`, `tests/capture_ultimates.gd`, `tests/capture_attacks.gd` (usage in their headers; write under `reports/codex-qa-15/screens/`), and your own capture script under your writable path for what they miss: every realm at the start (camera at a few spots, since realms are bigger than the screen), hazards firing, portals, soul crystal, monsters, the HUD with the bot panel (F4, on at start) and the results screen.
2. **Judge each screen like a player** and list problems, ranked by how much they hurt: things cut off, wrong scale or pixel density next to the 1x fighters, smeared or stretched art, effects hiding fighters, unreadable text or overlapping HUD pieces, misaligned anchors (effect not where the hit is), colours fighting the background, placeholder rectangles still visible, anything that looks unfinished. For each: the screenshot (crop and enlarge the spot), what is wrong, the file or code that owns it (trace it), and the fix you suggest — art (which file, what size) or code (which function).
3. Note what already looks good, so it is not touched.

## Writable paths

`reports/codex-qa-15/**`, `smash-nine-prototype/tests/analysis/codex_qa_15/**`. Everything else is read-only.

## Report (`reports/codex-qa-15/README.md`, Korean)

A ranked table (severity, screen, problem, owner file, suggested fix), the cropped evidence images, then "looks good". Commit, or `reports/codex-qa-15/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
