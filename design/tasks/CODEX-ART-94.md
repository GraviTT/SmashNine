# CODEX-ART-94 · Xion phase 1: her look (main illustration, face, idle anchor), candidates A and B

- Request: the user, through the 총괄 session (2026-11-18): "신규 캐릭터 생성. 총잡이이며, 컨셉은 건카타", "여성으로. 이름은 Xion." Her kit is in the game (D51). Her art is a stand-in: Nova's female drawings recoloured, holding no weapon. Brief: `reports/xion-kit-2026-11-18/art-brief.md`.
- Method: D35 (the idle anchor first, then the rows) and the main-art cards (`design/tasks/CODEX-ART-53.md`, `CODEX-ART-62.md`). Rules: D22, D25, D32–D35, D37 (idle 6.3 fps).
- **Two units make this card at the same time, blind to each other.** Each is told its letter and direction (below). Do not open the other letter's folders (`art/bakeoff/xion/<other letter>/`, `reports/codex-art-94<other letter>/`) or its files.
- **Candidates only.** Nothing under `smash-nine-prototype/` changes. The user picks the look in the pick cup (D49). Every other row (ART-95) then follows the winner.

| Unit | Direction | Branch | Clone |
| --- | --- | --- | --- |
| A | "the long coat" | `codex/xion-94a` | `SmashNine-units/art-a/SmashNine` |
| B | "the short coat" | `codex/xion-94b` | `SmashNine-units/art-b/SmashNine` |

## Xion (both letters)
- An adult woman, one body (D22). She is a gun-kata gunslinger whose play is "mid-range pressure and assassination". Read `smash-nine-prototype/characters/xion/Xion.md` and the Xion section of `design/SKILLS.md`.
  - Two shotguns push enemies back.
  - Her shadow double pins an enemy; she closes in and fires point-blank.
  - She rolls to reload; her ultimate fires in every direction.
- **Weapons: one short shotgun in each hand. They are not pistols.**
  - A short barrel with a thick muzzle (you can see the wide bore).
  - A pump grip or a break action; a pistol grip, no stock.
  - Both guns are the same model: black steel with silver parts and one small crimson detail.
- Palette: black, silver and crimson; natural skin.
  - These colours are new to the roster. Do not use the others' main colours: Frey's gold and white, Luna's pink and violet, Nova's navy and cyan, Rio's cyan trim and blue blade, Yuki's white and ice blue.
- Keep the head and face clear in every picture:
  - nothing in front of the face
  - no hat, hood or visor over it
  - hair off the eyes
  - guns and hands never over the head
- No effects: no muzzle flash, smoke, glow, sparks, afterimages or crimson aura (D32 ③). The game draws them.
- Proportions (D25):
  - illustration: 6.5–7.5 heads
  - sprite: 3 heads, like Frey and Rio; standing height 95–100 px in the 128-px cell (Frey 100, Rio female 96)

## Directions (each letter decides its own details: D22 "세부는 새로 디자인 가능")
- **A, "the long coat"** (the brief as written):
  - a black long coat to mid-calf, with silver lines along its edges, lapels and cuffs
  - crimson lining that shows when the coat swings, and a high collar
  - a fitted black outfit under it, and boots
  - long dark hair tied back (a low ponytail or a braid), so the face stays clear
  - the coat tails give her motion
- **B, "the short coat"** (another reading, cleaner at sprite size):
  - a black coat or jacket that ends at the hips or upper thigh, with silver lines
  - crimson accents, for example a long crimson scarf tied at the neck below the chin and trailing behind, or a crimson sash
  - fitted legwear and boots, so the legs read in walks and rolls
  - short dark hair (a bob or an undercut), optionally with a silver or crimson streak

## What to make (your letter only)

### 1. Main illustration: `art/bakeoff/xion/<letter>/xion_illustration-<letter>.png`
Draw it first: it fixes the design for the sprite.
- Format: 1024×1536 RGBA, transparent background, clean anti-aliased edges, no fringe.
- Framing: full body, 6.5–7.5 heads, about 88 % of the height, centred, a 3/4 view turned to the viewer's right.
- Pose: a gun-kata stance with both shotguns. For example, one arm extended and aiming forward, the other bent with its gun held back or across the body below the chin. Feet planted or mid-step.
- House style is the installed main art (`smash-nine-prototype/assets/art/{frey,luna,yuki,nova,rio}/*_illustration.png`): clean anime illustration, crisp line art, cel shading with soft gradients. Xion must look like the same game.

### 2. Face: `xion_face-<letter>.png`
- 256×256, cut from the illustration with LANCZOS.
- Framed like the installed `frey_face.png` and `rio_female_face.png` (eyes at about 40 % of the height).

### 3. Idle anchor: `xion-idle-<letter>.png`
768×128: 6 frames, a loop at 6.3 fps.
- References:
  - Image 1 = `smash-nine-prototype/assets/art/rio/rio_female_sheet.png` idle frame 1, 4× nearest. It sets the proportions (3 heads), head size, standing height and pixel rendering detail only. **Ignore its costume, colours, cape, ponytail and sword.**
  - Image 2 = your illustration. It sets the identity: face, hair, coat, guns, colours.
- Pose: a calm gun-kata ready stance, feet planted.
  - Both shotguns are held low and ready, one in each hand; both are visible (near and far hand).
  - The muzzles point down and forward; the guns stay below the shoulders.
- Frames:
  1. neutral
  2. inhale, shoulders up slightly
  3. top of the breath; hair and coat (or scarf) lift
  4. exhale begins; hair and coat still lifted (they lag one frame)
  5. lowest
  6. between 5 and 1, for a seamless loop
- Settings: `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00 --scale-by height:<target>`, with the target between 95 and 100.
- Head:
  - The same head size in all six frames: `head_scale.py --anchor <your strip>:0 --sheet <your strip>`, median 0.96–1.04.
  - If fewer than 2 frames score ≥ 0.6, compare 4× head crops instead and say so.
  - Compare the head with Rio female's at 4×: about the same size.
- Detail: at least 90 % of the Rio female idle's interior detail (`normalize.py --reference smash-nine-prototype/assets/art/rio/rio_female_sheet.png:0:6` reports both).
- Checks:
  - the 1-px border is clear, a 4-px margin, green spill 0
  - one face
  - both hands and both guns intact in every frame
  - every frame looked at 4×
- One generation. Make another (at most two more) only if it fails a check.

### 4. Lineup, for the lead's pick cup round
- `reports/codex-art-94<letter>/lineup.png`:
  - your idle frame 1 beside the in-game idle frame 1 of Frey, Rio female, Nova female and Luna
  - at 1× and 3× (nearest), feet on one line
  - on a dark grey (#2a2d34) strip and on a light (#c8c4b8) strip, each figure labelled with its name
  - it checks her size and her colour separation from the roster
- `reports/codex-art-94<letter>/idle-4x.gif`: the six frames at 6.3 fps, 4× nearest.

## Checks (a wrong arm in Luna's second illustration was once missed at mid size)
- Look at the illustration **at full size**, and list what you checked:
  - both arms, and the hands on the grips (fingers wrapped, the trigger finger placed)
  - both guns complete and the same model, with a shotgun shape (not a pistol)
  - the feet
- Size and alpha are right, fringe count 0, nothing cropped.
- Look at the face crop at 2×.
- Separate what you measured from what you judged by eye.

## Output
- In `art/bakeoff/xion/<letter>/`:
  - `xion_illustration-<letter>.png`, `xion_face-<letter>.png`, `xion-idle-<letter>.png`
  - `xion-idle-<letter>.json`: `{"note": "<Korean>", "fps": 6.3, "frames": 6, "loop": true}`
- In `reports/codex-art-94<letter>/`:
  - `prompt-illustration.txt`, `prompt-idle.txt`
  - `compare.png` (4×, from `normalize.py`)
  - `metrics.json`: factor, height, head scale, detail against Rio female
  - `lineup.png`, `idle-4x.gif`
  - `README.md`: Korean, short, **saved as UTF-8**
  - `commit.ps1` (rules below)
- Raw generations go to `art/raw/xion-94<letter>/` (git-ignored).
- `commit.ps1`:
  - Write the paths as a literal string array in the script (`$paths = @('...', '...')`). Do not read them from JSON: Windows PowerShell 5.1's `ConvertFrom-Json` hands an array on as one object.
  - Stage only your files and this card, with no `git add -f` and nothing under `art/raw/`.
  - End the message with `Co-Authored-By: Codex <noreply@openai.com>`.
  - Do not run it.

## Writable
`art/bakeoff/xion/<letter>/**`, `art/raw/xion-94<letter>/**`, `reports/codex-art-94<letter>/**`. Hard stop: 80 minutes.
