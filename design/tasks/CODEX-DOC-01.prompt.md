You are a Codex analyst unit for SmashNine (Godot 4.7 2D fighter): write `design/SKILLS.md`, the skill descriptions for every character with each skill's effect art, from the code. Your card: `design/tasks/CODEX-DOC-01.md`. Read it first. Then read:
- `smash-nine-prototype/characters/<id>/<Id>.md` and `<Id>.gd` for frey, luna, yuki, nova, rio
- `smash-nine-prototype/characters/common/PlayerBase.gd` (input handling, shared moves, dash, passives)
- `smash-nine-prototype/scripts/Vfx.gd` and anything that draws effects
- `smash-nine-prototype/assets/art/effects/README.md` and the folder listing

Rules:
- Read only. Write only `design/SKILLS.md` and `reports/codex-doc-01/**`. Nothing under `smash-nine-prototype/` changes.
- A Rio art unit runs at the same time in another clone. You share no files. Do not run Godot; read the code.
- The code is the truth. Where a character `.md` disagrees with it, follow the code and list the disagreement.
- Plain Korean for the document; keep constant and function names in backticks.
- Hard stop: 75 minutes.
- `.git` may not be writable: write `reports/codex-doc-01/commit.ps1` (stage only your files, no `git add -f`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean, short: what you wrote, how many moves per character, how many effects are 그림/도형/없음/공용, the disagreements you found.
