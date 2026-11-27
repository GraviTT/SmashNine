# CODEX-ART-98 · Six new character candidates: main illustration, face, one idle frame each

> **Superseded 2026-11-27 by `CODEX-ART-99.md`.** The user narrowed the new characters to Borok (with an axe), Doron (no mecha at first) and a new Jupi. Both units were stopped at 00:07 before any picture was delivered.

- Request: the user (2026-11-26, through the 총괄 session): "그 동안 Codex의 사용량을 좀 많이 소모 해야 하니 캐릭터를 더 만들어야 할 것 같다."
- The 총괄 chose six candidates from the old design document. Read **`reports/new-characters-2026-11-26/README.md`**: each candidate's play style, one-line story, skill sketch and body type.
- The user picks two of the six in the pick cup (D49). The picked ones then get their kits and full art, as Xion did.
- Method: the Xion concept round (`design/tasks/CODEX-ART-95.md`, `reports/codex-art-95a/README.md`, `reports/codex-art-95b/README.md`) and the main-art cards (`CODEX-ART-53.md`, `CODEX-ART-62.md`). Rules: D22, D25, D32–D35.
- **Candidates only:** nothing under `smash-nine-prototype/` changes. Everything goes under `art/bakeoff/newchar-2026-11-26/`, outside the game folder.
- Two units at the same time, three candidates each:

  | Unit | Candidates, in order | Branch | Clone |
  | --- | --- | --- | --- |
  | `art-a` | Borok, Raven, Mira | `codex/newchar-98a` | `SmashNine-units/art-a/SmashNine` |
  | `art-b` | May, Dohwa, Doron | `codex/newchar-98b` | `SmashNine-units/art-b/SmashNine` |

## The candidates

The details are each unit's design, within the brief's big frame (D22: "세부는 새로 디자인 가능"). Suggested palettes keep them apart from the roster and from each other; change one only with a reason.

| Candidate (id) | Body | Who | Props and look | Suggested palette | Sprite size |
| --- | --- | --- | --- | --- | --- |
| **Borok** (`borok`) | male | slow, hard-to-launch tank; the blacksmith king under Svartalfheim | a huge forge hammer (an anvil may appear in the illustration); heavy armour; braided beard. **The heaviest body in the roster at a glance**: choose stout-and-broad (dwarf-like) or tall-and-armoured, and say why | soot-black iron, ember orange (painted, no glow), leather brown | 3 heads, the widest silhouette |
| **Raven** (`raven`) | female | long-range sniper who keeps her distance with traps and back-jumps; the black ranger of the elf forest fortress | a great bow and a quiver; a raven-feather mantle (hood down); elf ears welcome | forest green, raven black, ivory | 3 heads |
| **Mira** (`mira`) | female | summoner who fights with skeletons and bone walls; her own body is frail; the archmage who gathers the bones of the dead | a bone staff; **one small skeleton servant beside her in the illustration** (secondary, like Xion's double), none in the sprite | bone ivory, ash grey, pale ghost green | 2.5–3 heads |
| **May** (`may`) | female | gambler whose skills change with the card she draws, and who can see the next card; a girl who reads the cataclysm in tarot | tarot cards held or fanned in her hand; a large scythe for her "Death" card; star and moon motifs | charcoal, cream card faces, mustard gold accents | 2.5 heads (a girl) |
| **Dohwa** (`dohwa`) | female | pulls foes into her own game; stronger as her tails stack; a nine-tailed fox who trained for a thousand years | **nine fox tails**, fox ears, a Korean hanbok-inspired outfit; a fox bead (orb) in her hand. Elegant and mysterious, **not sexualised**: a full outfit | peach-coral, cream fur, deep lacquer red-brown | 3 heads; tails may fan out behind |
| **Doron** (`doron`) | male | fights in a giant mecha and, when it breaks, survives on foot as a small boy; a boy genius who pilots the mecha "Goliath" | the illustration shows **both**: the boy and Goliath (he may stand on its hand or sit in its open cockpit). Gatling arm, jet pack, missile pods | gunmetal mecha with safety-yellow panels; the boy in a white-and-yellow flight suit | the mecha form; see below |

- Male candidates (Borok, Doron): one male body only at this stage. The second body comes after the pick.
- Every candidate:
  - an adult except May (a girl) and Doron (a boy); practical, non-revealing clothing that suits the age
  - the head and face clear: nothing over the face, no hood or visor over it, props and hands never across the head
  - no effects on the figure itself (no glow, aura, fire, smoke, sparks); props are fine

## What to make for each candidate (`<id>` as in the table)

### 1. Main illustration: `art/bakeoff/newchar-2026-11-26/<id>/<id>_illustration.png`
- 1024×1536 RGBA, transparent background, clean edges, no fringe.
- Full body, 6.5–7.5 heads (D25), about 88 % of the height, a 3/4 view turned to the viewer's right, in a pose that shows the play style.
- House style = the installed main art (`smash-nine-prototype/assets/art/*/*_illustration.png`, Xion's included): clean anime illustration, crisp line art, cel shading with soft gradients.
- The secondary figures named in the table (Mira's skeleton, Goliath) stand behind or beside the character without covering the face.

### 2. Face: `<id>_face.png`
256×256 cut from the illustration (eyes at about 40 % height), framed like the installed faces. For Doron, cut the boy's face.

### 3. Idle frame: `<id>-idle.png` + `<id>-idle.json` (`{"note": "<Korean>", "frames": 1}`)
- One frame, made like ART-95's idle frames:
  - Image 1 = an in-game idle frame at 4× for pixel detail and head size: Rio female's (3 heads), Nova female's (2.5) or Luna's (2.2), whichever fits the candidate. Ignore its costume.
  - Image 2 = your illustration (identity).
- A calm, ready stance that shows the weapon or prop; feet planted.
- `normalize.py --cell 128 --grid 1x1 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, feet at y=120.
  - Standing height for the chosen head count: 3 heads about 95–100 px, 2.5 heads about 88–92 px, 2.2 heads about 82–86 px.
  - Borok may be shorter if he is stout, but his head stays the size of a 3-head fighter's.
- **Doron:** the frame shows Goliath standing with the boy visible in its open cockpit.
  - Use a 192-px cell (`--cell 192`, feet y=152) when the mecha is taller than 120 px; the game draws 192 cells at the same scale (D34).
  - The mecha is the largest body in the roster, but keep the boy's head the size of a 2.2-head fighter's.
  - Optional, only if time allows: `doron-idle-pilot.png`, the boy alone at 2.2 heads in a 128 cell.
- Detail ≥ 90 % of the reference idle; the border clear, a 4-px margin, green spill 0; props and hands intact; looked at 4×.
- No effects in the sprite.

## Your report
- `reports/codex-art-98<a|b>/`:
  - `lineup.png`: your three idle frames beside the in-game idle frame 1 of Frey, Rio female, Nova female, Luna and Xion, at 1× and 3×, on #2a2d34 and on #c8c4b8, labelled
  - `concepts.png`: your three illustrations side by side, each with its idle frame
  - `prompts.txt`, `metrics.json` (per candidate: illustration size and alpha, sprite factor, height, head count as measured, detail)
  - `README.md`: Korean, short, UTF-8. For each candidate, three lines on how the look shows the play style and the story, then what you checked.
  - `commit.ps1`: the paths as a literal string array, only your files and this card, no `git add -f`, nothing under `art/raw/`, ending `Co-Authored-By: Codex <noreply@openai.com>`. Do not run it.
- Raw generations go to `art/raw/newchar-98<a|b>/` (git-ignored).

## Checks
- Look at every illustration **at full size**, and list what you checked:
  - hands, fingers and how they hold the prop
  - the prop complete
  - the feet
  - Dohwa's nine tails counted
  - Goliath's arms and legs
- The user notes errors at this level: "일러스트 팔 오류", "일러스트 신체 비율 수정 필요" (Xion round).
- Look at every sprite at 4×.
- Separate what you measured from what you judged by eye. Do not stamp, paste or copy body parts between frames or images.

## Writable
- `art-a`: `art/bakeoff/newchar-2026-11-26/{borok,raven,mira}/**`, `art/raw/newchar-98a/**`, `reports/codex-art-98a/**`
- `art-b`: `art/bakeoff/newchar-2026-11-26/{may,dohwa,doron}/**`, `art/raw/newchar-98b/**`, `reports/codex-art-98b/**`

Hard stop: 90 minutes. Finish candidates in the table's order and list the rest.
