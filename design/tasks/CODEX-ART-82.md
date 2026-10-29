# CODEX-ART-82 · Character motion repairs: the face-ratio rows and the weak motions

- Request: 점검 세션 "게임 상태 점검 및 정리", 사용자 요청 2026-10-25 — after the checkpoint `checkpoint-2026-10-25` (`c51a417f`), repair the sprites without needing the user. New files are **candidates** next to the old ones; the user picks later.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/art-b/SmashNine`, branch `codex/art-82` (from the checkpoint).
- Running at the same time: ART-81 (audit of every candidate) in `art-a`. You share no files. Do not run Godot.
- Read first: `design/tasks/CODEX-ART-72.md`, `reports/codex-art-72/README.md`, `reports/codex-art-75/README.md`, `reports/codex-art-77/README.md`, `reports/codex-art-78/README.md` (the method, the face check, what was weak). The raws of those runs are in this clone: `art/raw/motions-72`, `motions-75`, `motions-77`, `motions-78`.
- Nothing under `smash-nine-prototype/` or `tools/` changes. **Never overwrite**: write the next free version.

## 1. Rows outside the face rule
The lead promoted these rows as candidates although a frame measured outside the face rule (the face is about 14 px wide at 1×, so one pixel is 7%). Bring **every measurable frame to 0.96–1.04** (eye distance and face width, the ART-72 method, `face_check.py`; `tools/sprite_pipeline/head_scale.py` as the second check, the face decides):

| Row | Measured (eye / width) |
|---|---|
| `frey/frey-victory-v1` | 0.989–1.100 / 0.914–1.057 |
| `luna/luna-victory-v1` | 0.966–1.005 / 0.929–1.000 (F6 wink not measured) |
| `luna/luna_brave-victory-v1` | 0.968–0.994 / 1.000–1.071 |
| `luna/luna_brave-hurt-v2` | 1.001–1.064 / 0.929–1.071 |
| `luna/luna_brave-jump-v2` | 0.971–1.066 / 1.000 |
| `luna/luna_brave-fall-v3` | 0.955–0.985 / 1.000 |
| `frey/frey-jump-v2` | 0.992–1.045 / 1.000 |
| `yuki/yuki-victory-v1` | 1.001–1.053 / 1.000–1.083 |
| `nova/nova_female-victory-v1` | width 0.931–1.069 |
| `rio/rio_female-victory-v1` | width 1.000–1.083 (F6) |

- If one frame is off, retry **that frame only**, with the row's other frames as references; keep the pose and the motion.
- If the whole row is off by the same amount, change the row's single factor and rebuild from the raw.
- Keep everything else the row already had (pose, flow, costume, feet, margin, detail).

## 2. Weak motions
| Row | What is weak | Repair |
|---|---|---|
| `luna/luna-jump-v3` | F2 and F3 nearly the same | a distinct apex (tucked or stretched), F2 still rising |
| `yuki/yuki-fall-v2` | F1 and F2 nearly the same | hair, sleeves and the tassel flutter differently between the two |
| `nova/nova_female-victory-v1` | both jabs with the same arm | jab with alternating arms, then the raised fist and the wink |
| `luna/luna-victory-v1` | a big rotation jump F3→F4 | an in-between so the twirl reads as one movement |
| `rio/rio_male-victory-v1` | F2 sword short (foreshortened), a big gap F3→F4 | a readable sword in F2 and a smoother F3→F4 |

The repairs in part 2 must also meet the face rule of part 1.

## Checks and output
As CODEX-ART-72: the settings (`--resample lanczos --sharpen 60 --despill auto --palette none`), one factor per row matched to the anchor idle, costume exactly as the idle, one face, border clear, 4 px margin, spill 0, detail ≥ 79, feet on the line where grounded.
- Files: the next free version of each row, `art/bakeoff/<folder>/<stem>-<row>-v<n>.png` + `.json` (`note` in Korean with the measured face ratios per frame and what was repaired; `replaces`: the old file name).
- A 4× board per row: the anchor, the old version, the new version, with the face measures: `reports/codex-art-82/<stem>-<row>.png`.
- `reports/codex-art-82/README.md` (Korean): a table per row (frames redone, factor, face ratios before → after, margin, detail, delivered or not), and what is still weak.
- `reports/codex-art-82/commit.ps1`: only your files (this card and its prompt included), no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/{frey,luna,yuki,nova,rio}/**` (new files only), `art/raw/motions-82/**` (git-ignored), `reports/codex-art-82/**`, `design/tasks/CODEX-ART-82.md`, `design/tasks/CODEX-ART-82.prompt.md`.

Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. Hard stop: 150 minutes. Part 1 first, rows in the table order.
