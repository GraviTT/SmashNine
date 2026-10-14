# CODEX-ART-58 · The 8-frame walk: redraw the two passing frames (3 and 7) so the feet step through (Frey, Luna)

- Request: 사용자 2026-10-14 "…양 발이 번갈아 가며 앞으로 내딛는 모습이 아니다. 먼저 Frey와 Luna의 걸음걸이를 8프레임으로 변경해볼것." **Candidates only.**
- Two units at the same time, one character each, the same clones as ART-57:

  | Unit | Branch | Clone |
  | --- | --- | --- |
  | Frey | `codex/walk-58-frey` | `SmashNine-units/builder-frey/SmashNine` |
  | Luna | `codex/walk-58-luna` | `SmashNine-units/builder-art/SmashNine` |

## Why (the lead's check of ART-57)
ART-57 fixed the costume and the bob: `art/bakeoff/frey/frey-walk-v5.png` and `art/bakeoff/luna/luna-walk-v4.png`. Frames 1, 2, 4, 5, 6 and 8 stay.

Frames 3 and 7 are not passing poses. The swinging foot is already far in front, and the standing foot has jumped back.

Frey's planted feet (`tools/sprite_pipeline/walk_feet.py`), centre x:

| Frame | 2 | 3 | 4 |
| --- | --- | --- | --- |
| Planted feet | 83 | 49.5 (and the swing toe at 82.5) | 46 and 92 |

Between frames 2 and 3, both feet move more than 30 px in one frame. The eye pairs each foot with the nearest foot of the next frame, so it sees the back foot drop and the front foot lift. That reads as feet going down and up in place, not as one leg stepping through. This is the same complaint the user has about today's walks. Luna's frames 3 and 7 have the same fault.

Look at `reports/codex-art-57/<id>/` and run `walk_feet.py --onion` on the ART-57 strip to see it: red is a frame, cyan the next.

## The passing pose
The mannequin panels 3 and 7 are right; the drawings did not follow them.
- The standing leg is straight and vertical. Its foot is flat on the ground, directly under the hips.
- The swinging leg's knee is bent. Its foot is lifted 6–12 px (output pixels) **right beside the standing ankle**, toe pointing down.
- The two feet are almost at the same x. The lifted foot is **not** in front of the body.
- The far leg is a little darker and partly behind the near leg. Where the legs overlap, the near leg is drawn in front.

| Character | Frame | Standing leg | Swinging leg |
| --- | --- | --- | --- |
| Frey | 3 | near | far |
| Frey | 7 | far | near |
| Luna | 3 | near | far |
| Luna | 7 | far | near |

## Method
1. **Generate frames 3 and 7 only.**
   - Image 1 = the idle anchor (look).
   - Image 2 = that frame's grey mannequin panel from ART-57.
   - Image 3 = the accepted ART-57 frame 1 (costume).
   - Image 4 (legs together, same costume) = Frey: `art/bakeoff/frey/frey-walk-v2.png` frame 3; Luna: `art/bakeoff/luna/luna-walk-v1.png` frame 2.
   - Prompt: ART-57's, plus the passing-pose words above. Up to 4 generations per frame.
2. **Normalise** exactly as in ART-57: one factor per generation matched to the anchor head, `--ground-all`, LANCZOS, sharpen 60, despill auto, palette none.
3. **Assemble the 8 frames before the bob.**
   - Frames 1, 2, 4, 5, 6, 8 are ART-57's normalised frames *before* `walk_bob.py` (in `art/raw/walk-57/<id>/` in your clone).
   - Frames 3 and 7 are the new ones.
   - Then run `walk_bob.py` once on the strip.
4. **Measured acceptance for frames 3 and 7** (`walk_feet.py`, centre x of the planted foot):
   - exactly one planted foot, centred within ±6 px of:

     | Character | Frame 3 | Frame 7 |
     | --- | --- | --- |
     | Frey | 64 | 66 |
     | Luna | 67 | 68 |

     These are the midpoints between the standing foot in frames 2 and 6 and the rear foot in frames 4 and 8.
   - On the onion board (frames 2→3, 3→4, 6→7, 7→8):
     - the lifted foot is beside the standing ankle, not in front of the body
     - no foot moves more than 25 px between two frames
5. **The ART-57 checks still hold:**
   - the costume board against the idle (boots, legs, dress or armour, prop)
   - the leg check: 1 and 5 lead with different legs; 3 and 7 lift the swinging leg
   - every bob shift within ±3 px
   - border, margin, spill and detail
6. **GIF at 13.3 fps.** Say plainly whether the swinging leg now visibly passes the standing leg in each step.

## Output
- `art/bakeoff/frey/frey-walk-v6.png` and `art/bakeoff/luna/luna-walk-v5.png`: 1024×128, 8 cells.
- Each has a `.json` `{"note": "<Korean>", "fps": 13.3, "frames": 8}`.
- Deliver only a character that passes. Otherwise report the best attempt and what failed.
- Raw generations go to `art/raw/walk-58/<id>/`.
- `reports/codex-art-58/<id>/` holds:
  - `onion.png`, `feet.json`, `costume.png`, `bob.png`, `bob.json`, `walk.gif`
  - `prompts.txt`, `README.md` (Korean)
  - `commit.ps1`: no `git add -f`, nothing under `art/raw/`, no `__pycache__`

## Writable
- **Frey unit:** `art/bakeoff/frey/frey-walk-v6.*`, `art/raw/walk-58/frey/**`, `reports/codex-art-58/frey/**`
- **Luna unit:** `art/bakeoff/luna/luna-walk-v5.*`, `art/raw/walk-58/luna/**`, `reports/codex-art-58/luna/**`

Hard stop: 60 minutes.
