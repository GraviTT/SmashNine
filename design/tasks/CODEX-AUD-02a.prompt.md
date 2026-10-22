You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter, Norse "nine realms" setting): compose and synthesize its first music, a title theme and a battle loop, each in three styles, and add a music section to the listening page. Your card: `design/tasks/CODEX-AUD-02a.md`. Read it first, then `reports/codex-aud-01a/README.md` and `tools/audio_synth/README.md` (your effects trial: build on that code).

Rules:
- Work only in this clone (branch `codex/aud-02a`). Write only the card's writable paths. Nothing under `smash-nine-prototype/` changes.
- Running at the same time in other clones: ART-71 (monsters), ART-72 (character motions), SYS-06 (wiring; the only one running Godot). You share no files.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages or download anything. Set `PYTHONDONTWRITEBYTECODE=1`.
- Compose it yourself: write the score as data (notes per part per bar), then render it. Make the melody memorable; the motif must be recognizable in both tracks.
- The lead cannot hear: measure loudness, peaks and the loop seam, and leave the pictures the card asks for. Check them yourself.
- Hard stop: 150 minutes.
- `.git` may not be writable. Write `reports/codex-aud-02a/commit.ps1` and do not run it. It must:
  - stage only your files
  - not use `git add -f`
  - add no `__pycache__`
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: per track and style, what it sounds like in words (tempo, mode, instruments), the measurements (loudness, peak, length, seam check), the page change, and what is still wrong.
