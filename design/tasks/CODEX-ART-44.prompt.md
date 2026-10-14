You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter), unit B: Brave Luna design proposals. Your card: `design/tasks/CODEX-ART-44.md`. Read it first. Then read:
- `reports/frey-rework-2026-10-14.md` (the accepted method)
- `reports/codex-art-42/README.md` (why its Brave anchor was not kept)
- `reports/codex-art-37/idle/prompt.txt` (the prompt style that worked)
- `tools/sprite_pipeline/README.md`
- `smash-nine-prototype/characters/luna/Luna.md`
- `smash-nine-prototype/assets/art/luna/luna_brave_README.md`

Rules:
- Work only in this clone (branch `codex/luna-44`) and write only the paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- Unit A (CODEX-ART-43) runs at the same time in the builder-frey clone. Never touch `luna-*` normal-form files. Keep local work light; image generation is remote.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages.
- Generate with your built-in image tool; copy what you use into `art/raw/luna-44/`.
- The three proposals must be clearly different from each other and from normal Luna, yet unmistakably the same girl. Look at every frame at 4× and measure the head scale. Separate what you measured from what you judge by eye.
- Hard stop at 50 minutes.
- `.git` may not be writable: write `reports/codex-art-44/commit.ps1` (stage only your files, no `git add -f`, nothing under `art/raw/`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean: each proposal's file, what it changes, head scale and detail; what is still wrong.
