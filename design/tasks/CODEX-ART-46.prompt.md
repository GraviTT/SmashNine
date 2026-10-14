You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): Luna's special transformation. Your card: `design/tasks/CODEX-ART-46.md`. Read it first. Then read:
- `reports/frey-rework-2026-10-14.md` (the accepted method)
- `reports/codex-art-43/README.md` (the normal Luna anchor)
- `reports/codex-art-44/README.md` (proposal ② is Brave Luna, D36)
- the prompts in `reports/codex-art-44/v4/prompt.txt` and `reports/codex-art-43/*/prompt.txt`
- `tools/sprite_pipeline/README.md`
- `smash-nine-prototype/characters/luna/Luna.md`

Rules:
- Work only in this clone and write only the paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages.
- Generate with your built-in image tool; copy what you use into `art/raw/luna-46/`.
- This is a showcase motion. The two outfits must read clearly, the spin must flow, and the head size must stay the anchors'. Look at every frame at 4×, measure the head scale per half, and judge the 12-frame preview. Separate what you measured from what you judge by eye.
- Hard stop at 60 minutes.
- `.git` may not be writable: write `reports/codex-art-46/commit.ps1` (stage only your files, no `git add -f`, nothing under `art/raw/`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean: what each frame shows, the head scale per half, the factors, what is still wrong.
