# CODEX-ART-03A ImageGen prompts

All three sources were produced with the built-in ImageGen tool and a genuinely
transparent background.

## Yuki

```text
Use case: stylized-concept
Asset type: original 2D pixel-art game character sprite atlas for a Godot platform-brawler
Input images: Concept1 and Concept2 are broad roster/style references only; Frey sheet is the accepted production scale reference. Match Frey's pixel density, strong dark outline, figure height, chibi proportions, padding and visual weight, without copying her design.
Primary request: Create one production-ready sprite atlas for YUKI, an original FEMALE Eastern-myth onmyoji controller. She faces RIGHT in every frame. Slight nimble body, long black hair tied high with a red-and-white cord, asymmetrical deep-plum and vermilion shrine-mage coat over dark fitted trousers, ivory paper talismans marked only with abstract red brush symbols, short black boots, small gold yin-yang clasp. No handheld weapon. Palette must be distinct from Frey's gold/steel/blue.
Canvas/layout: EXACTLY 6 columns by 7 rows of equal cells, with no drawn grid or labels. Every figure remains entirely inside its cell with generous transparent padding and one consistent baseline/center axis.
Row 0: 4 idle frames, subtle breathing with two talismans floating close, then 2 fully empty transparent cells.
Row 1: 6-frame nimble run cycle, talismans trailing closely.
Row 2: 1 rising jump frame in column 0, then 5 empty transparent cells.
Row 3: 1 falling frame in column 0, then 5 empty transparent cells.
Row 4: 4-frame basic attack clearly reading as wind-up -> flick/throw one paper talisman forward to the right -> active extended casting hand and short paper trail -> recovery; then 2 empty cells.
Row 5: 6-frame shield animation: both hands hold a ward sign, with a SMALL vertical plum-red/gold seal barrier immediately in front/right of her body, subtle pulse/recoil; barrier must not hide the character.
Row 6: 1 hurt/knockback frame in column 0, then 5 empty transparent cells.
Style/medium: authentic hand-crafted pixel art at larger working resolution for later nearest-neighbor reduction to 64x64 cells; crisp hard pixel clusters, limited cohesive palette, 2-3 pixel equivalent dark navy outline, no anti-aliased painterly edges, no gradients, no semi-transparent motion blur. Cute super-deformed fantasy fighter proportions, same figure height and head/body ratio as Frey reference.
Animation consistency: same exact face, hair silhouette, body proportions, costume, talisman size and palette in every frame. Attack and shield poses must be readable at 2x gameplay scale.
Constraints: genuinely transparent background; no text; no labels; no numbers; no logos; no watermark; no scenery; no ground shadow; no grid lines; no cropped limbs or talismans; no extra characters; empty cells truly empty; no left-facing frames.
```

## Nova male

```text
Use case: stylized-concept
Asset type: original 2D pixel-art game character sprite atlas for a Godot platform-brawler
Input images: Concept1 and Concept2 are broad roster/style references only; Frey sheet is the accepted production scale reference. Match Frey's pixel density, strong outline, figure height, chibi proportions, padding and visual weight, without copying her design.
Primary request: Create one production-ready sprite atlas for NOVA, MALE body variant, an original superhero cosmic guard who converts speed into gravity strikes. He faces RIGHT in every frame. Athletic compact male body, short upswept midnight hair, face visible, sleek fitted midnight-indigo suit with pale silver chest/forearm armor, bright teal seams that shift toward small gold accents, a simple circular gravity-orbit emblem on the chest, teal boots and gauntlets. No cape, no weapon, no shield equipment. Palette and silhouette distinct from Frey's gold/steel Valkyrie and Yuki's plum/red robes.
Canvas/layout: EXACTLY 6 columns by 7 rows of equal cells, no drawn grid or labels. Every figure remains entirely inside its cell with generous transparent padding and one consistent baseline/center axis.
Row 0: 4 idle frames, ready runner stance and subtle breathing, then 2 fully empty transparent cells.
Row 1: 6-frame fast run cycle with short tight teal gravity wisps, strong contact and passing poses.
Row 2: 1 rising jump frame in column 0, knees tucked and gravity lift below, then 5 empty cells.
Row 3: 1 falling frame in column 0, streamlined downward pose, then 5 empty cells.
Row 4: 4-frame momentum punch/forearm strike to the right: clear coiled wind-up -> launch -> active extended punch with a SHORT teal-to-gold gravity streak -> braking recovery; then 2 empty cells. Body motion must sell impact.
Row 5: 6-frame shield animation: forearms crossed tightly in front/right of chest inside a SMALL round teal gravity field, subtle pulse/recoil; field must not hide the body.
Row 6: 1 hurt/knockback frame in column 0, then 5 empty cells.
Style/medium: authentic hand-crafted pixel art at larger working resolution for later nearest-neighbor reduction to 64x64 cells; crisp hard pixel clusters, limited cohesive palette, 2-3 pixel equivalent dark navy outline, no anti-aliased painterly edges, no gradients, no semi-transparent motion blur. Cute super-deformed fighter proportions matching Frey's figure height/head ratio.
Animation consistency: same exact face, hair, athletic male body proportions, suit panel design, emblem, gauntlets, boots and colors in every frame. Attack and crossed-arm shield silhouette readable at 2x gameplay scale.
Constraints: genuinely transparent background; no text; no labels; no numbers; no logos; no watermark; no scenery; no ground shadow; no grid lines; no cropped limbs/effects; no extra characters; empty cells truly empty; no left-facing frames.
```

## Nova female

```text
Use case: style-transfer
Asset type: matching female-body variant of an original 2D pixel-art game character sprite atlas
Input images: Image 1 is the exact NOVA male atlas/design to preserve. Image 2 is the accepted Frey scale reference.
Primary request: Create NOVA FEMALE as the same character and exact same animation atlas as Image 1, but with a clearly female athletic compact body and subtly feminine face. Preserve the same short upswept midnight hair identity, same sleek midnight-indigo suit pattern, same pale silver chest/forearm armor, same teal seams and small gold accents, same circular gravity-orbit chest emblem, same teal boots and gauntlets, same effects and palette. Do not feminize by exposing skin or changing the costume. The difference should come from body shape: slightly narrower shoulders, defined waist, slightly wider hips and feminine face, while remaining an athletic cosmic guard.
Canvas/layout: EXACTLY 6 columns by 7 rows of equal cells, with no grid or labels, same content positions as Image 1.
Row 0: 4 idle frames, then 2 empty cells.
Row 1: 6 fast run frames.
Row 2: 1 rising jump frame, then 5 empty cells.
Row 3: 1 falling frame, then 5 empty cells.
Row 4: 4-frame momentum punch sequence (wind-up -> launch -> active teal-to-gold gravity strike -> recovery), then 2 empty cells.
Row 5: 6-frame crossed-forearm guard inside a small round teal gravity field.
Row 6: 1 hurt frame, then 5 empty cells.
Style/medium: match Image 1's crisp hand-crafted pixel clusters, dark navy outline, limited palette, figure height, head/body ratio and effect size. Match Frey's overall gameplay figure height. No anti-aliased painterly edges, gradients or semi-transparent motion blur.
Critical invariants: this must be immediately recognizable as the female-body variant of the exact same Nova design. Same costume panels, emblem, hair color/style, gear, effect colors, animation actions, facing right, and proportions across all frames. Only alter face/body anatomy enough to read female.
Constraints: genuinely transparent background; no text; no labels; no numbers; no logos; no watermark; no scenery; no ground shadow; no grid lines; no cropped limbs/effects; no extra characters; empty cells truly empty; no left-facing frames.
```
