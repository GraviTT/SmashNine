# CODEX-ART-95 · Xion concepts C–F from her story: main illustration with her other-timeline double, one idle frame

- Request: the user (2026-11-19), after seeing ART-94's A (long coat) and B (short coat):
  - "컨셉을 조금 더 다양하게 해서 몇가지 시안을 더 만들어줘. 메인 이미지와 도트 idle 포즈 한 프레임만."
  - "한 소녀가 누군가에 의해 100년 간 시간의 개념이 없는 공간에서 시공간 괴물들을 사냥하며 살아남았고, 이후 현실로 돌아왔다는 설정."
  - "도플갱어는 협력하는 또 다른 시간선의 Xion이라는 것으로 해서 일러스트에도 홀로그램 같은 모습으로 들어가게."
- A and B were both black-coat gunslingers. These four concepts must differ from them and from each other in silhouette, era and material. They must not be colour swaps.
- Method: ART-94 (`design/tasks/CODEX-ART-94.md`, its reports `reports/codex-art-94a/`, `reports/codex-art-94b/`). Keep its rules except those changed below. **Candidates only:** nothing under `smash-nine-prototype/` changes. The user picks among A–F in the pick cup.
- **Two units at the same time, blind to each other:**

  | Unit | Concepts | Branch | Clone |
  | --- | --- | --- | --- |
  | `art-a` | C, D | `codex/xion-95a` | `SmashNine-units/art-a/SmashNine` |
  | `art-b` | E, F | `codex/xion-95b` | `SmashNine-units/art-b/SmashNine` |

  Do not open the other unit's folders (`art/bakeoff/xion/{c,d}/` or `{e,f}/`, `reports/codex-art-95a/` or `95b/`). You may look at A and B (`art/bakeoff/xion/{a,b}/`) to stay away from them.

## Her story (the user's)
- A girl was taken by someone into a space without time. For a hundred years she survived there by hunting space-time monsters, and then she came back to reality.
- Time did not pass for her body. She looks like a young woman in her late teens, with eyes that have seen a century.
- Her double is a Xion from another timeline who fights beside her. In the game she is Xion's figure in translucent crimson (D51).
- Her kit stays as in the game (`smash-nine-prototype/characters/xion/Xion.md`): a gun-kata gunslinger with **one short shotgun in each hand, not pistols**. Short barrel, thick muzzle, a pump grip or a break action, both guns the same model.

## Rules for every concept
- Practical, non-revealing combat clothing that suits her age.
- Keep the head and face clear: nothing in front of the face, no hat, hood or visor over it, hair off the eyes, guns and hands never over the head.
- Palette: Xion's base is black, silver and crimson. A concept may shift it (below), but must not use another fighter's main colours: Frey's gold and white, Luna's pink and violet, Nova's navy and cyan, Rio's cyan and blue, Yuki's pure white and ice blue.
- Story motifs are welcome when they are part of the costume or the props:
  - hourglasses, clock hands, cracked dials, a stopped pocket watch
  - trophies, scars and armour from space-time monsters
- No effects on Xion herself: no muzzle flash, smoke, glow, sparks, afterimages or auras. The only special element is the hologram double, and only in the illustration.

## The four concepts
**C, "the time-bleached survivor"** (`art-a`)
- A hundred years in the void bleached her hair ash-silver (not pure white; that is Yuki's).
- A ragged dark poncho-cloak stitched from void-monster hide with crimson thread.
- Hourglass and broken-clock motifs: an hourglass charm, a cracked watch on her wrist.
- Scavenged, engraved shotguns with bone or chitin grips; bandaged hands; a monster horn shard on her belt.
- Feral and hardened. Palette: ash greys, charcoal, bone, crimson.

**D, "the girl from a century ago"** (`art-a`)
- She still wears what she wore when she was taken: a century-old girl's outfit.
  - a long double-breasted wool coat with a wide capelet collar
  - a knee-length pleated skirt over dark tights or breeches, and lace-up boots
- It is patched and reinforced with void-monster bone plates and straps.
- Long dark hair in braids with a crimson ribbon; a stopped pocket watch on a chain.
- Old-fashioned and a little tragic. Palette: deep crimson or burgundy coat, black, silver or dark-iron fittings (no gold).

**E, "the chrono hunter"** (`art-b`)
- Sleek and modern: a fitted black tactical suit with crimson time-rune lines in flat paint (no glow).
- An asymmetric short jacket with silver plates shaped like clock hands, and a clock-dial emblem on one shoulder.
- A high ponytail with crimson inner hair; shotguns with gear-shaped cylinders or clock-dial details.
- Precise and cool. Palette: black, silver, crimson.

**F, "the void huntress"** (`art-b`)
- Asymmetric armour pieces carved from space-time monster chitin, in pearl-grey and black.
- A split cape whose lining shows a printed star-field or void pattern (a pattern, not light).
- Long dark hair, half up; a necklace of monster teeth; heavy boots; shotguns with chitin parts.
- A hunter who wears her prey. Palette: black, pearl-grey, crimson.

## What to make for each of your two concepts (`<c>` = its lower-case letter)

### 1. Main illustration: `art/bakeoff/xion/<c>/xion_illustration-<c>.png`
- Format, framing and house style as ART-94:
  - 1024×1536 RGBA, transparent background, clean edges, no fringe
  - full body, 6.5–7.5 heads, 3/4 view turned to the viewer's right
  - the installed main art's style (`smash-nine-prototype/assets/art/*/*_illustration.png`)
- Xion is in front, opaque and complete, in a gun-kata pose with both shotguns, about 80–85 % of the height.
- **Her double, as a hologram:**
  - A second Xion behind her, cooperating: back to back, or aiming the other way. She is clearly secondary (behind, partly overlapped, may be a little smaller).
  - She is from another timeline. She may differ in a few details (hair, a scar, the coat), but must read as the same person.
  - Render her as a hologram:
    - translucent (partial alpha, about 40–70 %), crimson monochrome
    - fine horizontal scanlines, one or two thin horizontal slices shifted a few pixels (glitch)
    - edges that read on both dark and light backgrounds
  - She never covers Xion's face or head.

### 2. Idle frame: `art/bakeoff/xion/<c>/xion-idle-<c>.png`
- One frame, 128×128, made like ART-94's idle frame 1:
  - Image 1 = Rio female's idle frame 1 at 4×, for proportions (3 heads), head size, standing height and pixel detail only. Ignore her costume and sword.
  - Image 2 = your illustration's Xion (not the hologram).
- A calm gun-kata ready stance, feet planted, both shotguns held low, one in each hand, both visible.
- `normalize.py --cell 128 --grid 1x1 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, with the standing height between 95 and 100 px and feet at y=120.
- Head about Rio female's size (compare 4× crops). Detail ≥ 90 % of Rio female's idle.
- Checks: the border is clear, a 4-px margin, green spill 0; both hands and both guns intact; looked at 4×.
- No hologram in the sprite.
- Also write `xion-idle-<c>.json`: `{"note": "<Korean>", "frames": 1}`.

## Your report
- `reports/codex-art-95<unit letter a|b>/`:
  - `lineup.png`: your two idle frames beside the in-game idle frame 1 of Frey, Rio female, Nova female and Luna, at 1× and 3×, on #2a2d34 and on #c8c4b8, labelled
  - `prompt-<c>-illustration.txt`, `prompt-<c>-idle.txt`
  - `metrics.json`: per concept: illustration size and alpha, sprite factor, height, detail against Rio female
  - `README.md`: Korean, short, saved as UTF-8. For each concept, say in three lines what makes it different from A, B and your other concept, then what you checked.
  - `commit.ps1`, as ART-94: paths in a literal string array, only your files and this card, no `git add -f`, nothing under `art/raw/`, ending with `Co-Authored-By: Codex <noreply@openai.com>`. Do not run it.
- Raw generations go to `art/raw/xion-95<unit letter>/` (git-ignored).

## Checks (as ART-94)
- Look at each illustration at full size, and list what you checked:
  - the hands on the grips, the fingers, the trigger finger
  - both guns complete and the same model, shotguns not pistols
  - the feet
  - the hologram: translucent, behind, the face clear
- Look at each sprite at 4×.
- Separate what you measured from what you judged by eye.

## Writable
- `art-a`: `art/bakeoff/xion/c/**`, `art/bakeoff/xion/d/**`, `art/raw/xion-95a/**`, `reports/codex-art-95a/**`
- `art-b`: `art/bakeoff/xion/e/**`, `art/bakeoff/xion/f/**`, `art/raw/xion-95b/**`, `reports/codex-art-95b/**`

Hard stop: 80 minutes.
