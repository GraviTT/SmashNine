# CODEX-ART-91 · Motion inventory and missing-motion priorities, then new monster motions (appear, rage)

- Request (사용자, 2026-10-28 14:30, 점검 세션 전달): "Codex에게 스프라이트를 더 만들게 하여 아직 게임에 없는 더 많은 행동 패턴 동작을 생성해볼것. 이후 사용 할수도 있으니 미리 만들어두는 것이고, 오늘 오후 4시에 종료."
- Unit: Analyst first, then Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-a/SmashNine`, branch `codex/art-91` (from `after-cp/art-sprite` `51b6ada6`).
- Running at the same time: ART-92 in `art-b` makes `dodge_roll`, `taunt`, `stun`, `crouch`, then `run_start` for the 8 fighter forms. Do not make those. The character-skill session makes skill moves; do not make them. Do not run Godot.
- New files are **candidates** for later; nothing is wired into the game.

## Time — hard limits
- Part 1 must be written by **15:05**. Then Part 2.
- Check the clock (`Get-Date`) before each row. **Do not start a new row after 15:45** local time. Finish the row in hand, then write the report; be done by **15:55**. The process is killed at 15:57; anything not delivered by then is lost.
- Deliver row by row: when a row passes, write its files and add it to the progress list at once. Never batch deliveries to the end.

## Part 1 · Inventory and priorities (no image generation, about 15 minutes)
Read the row tables in the game code (`PlayerBase.ORIGINAL_SHEET_ROWS`, `OPTIONAL_MOTION_ROWS`, each character's `SHEET_ROWS` / `MOVE_SHEET_ROWS` / `BRAVE_MOVE_SHEET_ROWS`, `RealmMonster.ART_ROWS`) and every candidate under `art/bakeoff/` (`<stem>-<row>-vN.png`, `adopted` in json = in the game).
Write `reports/codex-art-91/inventory.md` (Korean) and `inventory.json`:
1. Per fighter form (8) and per monster (18): rows in the game and candidate rows (versions, adopted or not).
2. Missing **general** motions (not skills), with priority 1–3 and why, suggested cell/feet, frames (6), fps, loop, and which existing row to use as the style reference. Fighters: e.g. run start/stop, dodge roll, guard break, stun, grab/throw, wall cling/wall jump, ledge grab/climb, portal enter/exit, taunt, crouch, air recovery, surprise, laugh. Monsters: e.g. appear (spawn), rage, special attack, sleep, flee.
3. Mark what ART-92 is making now and what belongs to the skill session (moves in `*_moves_README.md` and skills designed in the docs but not drawn yet), so nobody makes the same row twice.

## Part 2 · Monster motions (until 15:45)
Monsters (18): every `<id>` with a game sheet `smash-nine-prototype/assets/art/monsters/<id>_sheet.png`. Rows in this order, motion by motion, all monsters each:

| Order | Row name | What it shows | Cell / feet | Frames · fps · loop |
|---|---|---|---|---|
| 1 | `appear` | the monster arrives on the field: from a low, curled or crouched start it rises or unfolds into its ready stance (body only) | 96 / 72 | 6 · 10 · false |
| 2 | `rage` | an angry wind-up of its own kind: rears up, roars or bristles, then a tense ready stance | 96 / 72 | 6 · 10 · false |

If time is left: `sleep` (curled or slumped, slow breathing; 6 · 6 · true), then `flee` (turns away and runs; 6 · 10 · true).

Method (as the six-row monster candidates ART-71/74/76 and their repairs ART-83/88): read `reports/codex-art-76/README.md` and `reports/codex-art-83/README.md` for the settings. One generation draws the whole row; Image 1 = that monster's idle candidate (the newest version, e.g. `<id>-idle-v2.png` if it exists, else `-v1`), Image 2 = a related row of the same monster (appear: `windup` or `defeat`; rage: `windup`; sleep: `defeat`; flee: `walk`). Up to 2 generations per row; keep the better. One factor per row; the figure stays within ±5% of the idle size. No effects drawn into the body (no dust, glow bursts, projectiles, flashes).

## Checks (deliver only if all pass)
Same look and palette as the monster's idle; border clear; 4 px margin inside every cell; spill 0; feet on y=72 where grounded (flying monsters keep their idle hover height); size within ±5% of the idle; **fixed-width slicing**: the strip is exactly 6 × 96 wide and no pixel of a frame touches or crosses its cell edges; 6 distinct frames.

## Output per delivered row
- `art/bakeoff/monsters/<id>-<row>-v1.png` (6 frames in one row) + `.json`: `note` (Korean: what it shows, size vs idle, anything weak), `frames`, `fps`, `cell`, `feet`, `loop`, `new_row: true`.
- A 4× board `reports/codex-art-91/<id>-<row>.png`: the idle frame, then the 6 frames.
- Append one line to `reports/codex-art-91/progress.md` (time · id · row · file · frames · checks · note) and the row's paths (png, json, board) to `reports/codex-art-91/commit-paths.txt`.
- A failed row: no file in `art/bakeoff`; log it with the reason; keep the best attempt under `art/raw/monsters-91/`.

## At the end (by 15:55)
`reports/codex-art-91/README.md` (Korean): the inventory summary, delivered rows (monster · row · file · frames · checks), failed rows with reasons; `commit.ps1` staging exactly `commit-paths.txt` plus `inventory.md`, `inventory.json`, this card and its prompt, with `git add --pathspec-from-file`; no `git add -f`, nothing under `art/raw/`, no attempt dumps, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/monsters/<id>-{appear,rage,sleep,flee}-v1.*` (new files only), `art/raw/monsters-91/**` (git-ignored), `reports/codex-art-91/**`, `design/tasks/CODEX-ART-91.md`, `design/tasks/CODEX-ART-91.prompt.md`. Nothing under `smash-nine-prototype/` or `tools/` changes; never overwrite an existing file.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads.
