# CODEX-ART-69 · Defeat motion for every form (new row `defeat`)

- Request: 사용자 2026-10-17 "그리고 이후 캐릭터들 패배 모션 추가."
- Today a fighter knocked out just vanishes. The lead is wiring the game: a fighter knocked out on the ground plays its `defeat` row, holds the last drawing, then fades.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine`, branch `codex/art-69` (from the latest main).
  - Running at the same time: ART-68 (Rio heads) in the builder-ui clone. You share no files.
- Method: D35, as the move rows were drawn (`design/tasks/CODEX-ART-61.md`, `reports/codex-art-61b/README.md`, `tools/sprite_pipeline/README.md`):
  - one generated image per motion, with the form's adopted idle as the reference
  - `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`
  - one factor per row, matched to the anchor head
- **Candidates only.** Nothing under `smash-nine-prototype/` changes. The viewer shows them as new rows, and the user picks.

## The row
- `defeat`, 6 frames, 192-px cells (the move sheet's cell).
  - The figure is at the main sheet's pixel scale (the same factor as the idle). Feet on y=152 while standing.
  - Played at about 10 fps, once. The game holds frame 6 for about 0.6 s, then fades the fighter out.
- The motion, facing right like every sheet:
  1. hit recoil: head snapped back, upper body bent back
  2. stagger one step back, arms loose
  3. knees buckle
  4. falling backward or sideways
  5. hitting the ground (a small bounce)
  6. lying still on the ground (eyes closed; the weapon dropped beside or still in hand)
- Frames 5 and 6 lie on the line y=152 (the body rests on the floor, not above it).
- The lying body must fit with a 4 px margin: draw it with knees bent or curled if it is longer than the cell.
- Costume exactly as the idle, one face, hands and weapons intact, no effects, no text.

## The forms (in this order)

| Form | Anchor idle | Output |
| --- | --- | --- |
| Frey | `art/bakeoff/frey/frey-idle-v2.png` | `art/bakeoff/frey/frey-defeat-v1.*` |
| Luna | `art/bakeoff/luna/luna-idle-v3.png` | `art/bakeoff/luna/luna-defeat-v1.*` |
| Brave Luna | `art/bakeoff/luna/luna_brave-idle-v4.png` | `art/bakeoff/luna/luna_brave-defeat-v1.*` |
| Yuki | `art/bakeoff/yuki/yuki-idle-v2.png` | `art/bakeoff/yuki/yuki-defeat-v1.*` |
| Nova male | `art/bakeoff/nova/nova_male-idle-v2.png` | `art/bakeoff/nova/nova_male-defeat-v1.*` |
| Nova female | `art/bakeoff/nova/nova_female-idle-v2.png` | `art/bakeoff/nova/nova_female-defeat-v1.*` |
| Rio male | `art/bakeoff/rio/rio_male-idle-v2.png` | `art/bakeoff/rio/rio_male-defeat-v1.*` |
| Rio female | `art/bakeoff/rio/rio_female-idle-v2.png` | `art/bakeoff/rio/rio_female-defeat-v1.*` |

Each `.png` is a 6-frame strip, 1152×192, transparent.

Each `.json` has:
- `note` in Korean
- `frames: 6`, `fps: 10`, `cell: 192`, `feet: 152`
- `factor`

## Checks (each form)
- **Face match**, 0.96–1.04 against the anchor, on frames 1–3. Measure on 4× crops: eye-to-eye distance, and face width at the eyes, hair excluded. Also run `head_scale.py`; if the two disagree, the face decides.
  - Frames 4–6 are tilted or lying: check them by eye at 4× next to the anchor.
- Border clear, 4 px margin, spill 0, detail ≥ 79.
- Feet and body on the line.
- One face per frame; nothing pasted from the idle.
- A 4× board per form with the anchor: `reports/codex-art-69/<stem>-defeat.png`.
- Up to 3 generations per form. If a form still fails, report the best attempt and why.

## Writable

| Path | For |
| --- | --- |
| `art/bakeoff/<folder>/<stem>-defeat-v1.png` and `.json` (the eight files in the table, new files only) | the candidates |
| `art/raw/defeat-69/**` (git-ignored) | raw generations |
| `reports/codex-art-69/**` | boards, `README.md` (Korean), `prompts.txt`, `commit.ps1` (no `git add -f`, nothing under `art/raw/`, no `__pycache__`) |

Hard stop: 150 minutes. Deliver the forms in the table order and list the rest.
