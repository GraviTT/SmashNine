# CODEX-ART-70 · Story mode presentation art: three scene pictures, dialogue frame, name plate, shadow aura

- Request: user 2026-10-22, during story mode step 1 (D43): "스토리 연출용으로 들어갈 스프라이트와 리소스가 필요하면 직접 만들어봐." The lead decided the set below.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/art-70` (from the latest main). Lead: Claude (reviews every image at full size, picks, wires them in later).
- Running at the same time: CODEX-SYS-03 (story code and screens) in the builder-ui clone; it runs Godot. You share no files. Run Godot at most once at a time and only briefly (an import check).
- Read first: `reports/story-mode-plan-2026-10-22.md` section 5 (what the story shows), `design/STORY.md` (the lines each picture sits behind), `smash-nine-prototype/assets/art/ui/README.md` (how the HUD frames and the title background were made), `scripts/Vfx.gd` (how effect strips are described: frames, fps, pivot, loop).
- **Nothing in the game code changes.** You deliver files; the lead wires them after the story skeleton is merged.

## Where each asset is used

| Asset | Used for |
| --- | --- |
| `cg_prologue` | full screen behind the prologue narration of stage 1 (`story.s01.pre.1–3`) |
| `cg_root` | behind the lines where the root's seal opens, between stage 8 (Niflheim) and stage 9 (`story.s08.post.*`, `story.s08.home.post.*`) |
| `cg_epilogue` | behind the last narration (`story.s09.post.1–2`), before each hero's ending art |
| `dialogue_frame` | the frame of the dialogue box (about 1160×170 at the 1280×720 UI) |
| `name_plate` | the plate under the speaker's name, above the box's left or right end |
| `shadow_aura` | a looping dark aura behind the shadow fighters of stage 9 (the hero's copies) |

The dialogue box covers the **bottom quarter** of a scene picture: keep the important parts in the upper three quarters.

## Image spec

Style references (attach in this order): 1 = `smash-nine-prototype/assets/art/ui/title_bg.png` (style anchor: painted pixel art, deep navy cosmos, floating realm islands, the world tree with its glowing pink heart), 2 = `smash-nine-prototype/assets/art/realm_center/bg_far.png` (the tree and heart as the game shows them), 3 = `smash-nine-prototype/assets/art/realm_niflheim/bg_far.png` (ice palette, for `cg_root`), 4 = `smash-nine-prototype/assets/art/ui/frames/result_panel.png` (frame ornaments: gold and blue), 5 = `smash-nine-prototype/assets/art/effects/skill/luna_brave_aura.png` (an effect strip of the game).

### 1. `cg_prologue.png` — the heart bursts

| Line | Spec |
| --- | --- |
| Size | final **1600×900**, opaque. Generate landscape at the largest size offered, crop to 16:9, downscale with LANCZOS. Never upscale (if the raw is under 1600 px wide, final 1280×720). Keep the raw as `cg_prologue_source.png`. |
| Style | refs 1 and 2: the same painted pixel-art look (visible pixel clusters, no smooth airbrush), palette deep navy `#0b1030`, violet `#3b1d5e`, purple `#7a3fc0`, heart magenta `#ff4fd8`, white-pink burst `#ffd6f5`, gold accents `#f3cd7c` |
| Must show | the world tree Yggdrasil in the centre; its heart (the pink heart-shaped core inside the trunk, as in refs 1–2) **cracking and bursting**: jagged white-pink cracks, a bright flash and a ring shockwave; light shards flying; the realm islands around it (as in ref 1: gold castle, green-roofed town, ice castle, purple moon grove, red lava fortress, brass clockwork city, green forest temple, grey horned ruins) **tilting and drifting**, two of them colliding with rubble and broken waterfalls; galaxies in the sky with a red-violet tint from the burst |
| Bottom quarter | darker clouds and rock, little detail (the dialogue box goes there) |
| Avoid | people or creatures, text, letters, logos, UI, frames, border, watermark, photographic look |
| Text | **none** |

### 2. `cg_root.png` — the frozen root, the seal opening

| Line | Spec |
| --- | --- |
| Size | as `cg_prologue` (1600×900 opaque, raw kept as `cg_root_source.png`) |
| Style | refs 1 and 3: painted pixel art; ice palette teal `#0d2a33`, `#1f5560`, cyan `#7fe3ff`, aurora green `#58d6a8`, with the heart's magenta `#ff4fd8` glowing from below |
| Must show | an immense ancient root of the world tree, frosted with ice and icicles, spiralling down into an abyss inside an ice cavern; a **circular ward seal** around the root's opening — a ring of paper talismans (plain rectangles with abstract red swirl marks) glowing pale cyan, the ring **breaking apart** with talismans drifting outward; from the depths, pink-magenta light of the heart rising along the root; aurora light from far above |
| Bottom quarter | dark ice and shadow, little detail |
| Avoid | people or creatures, text, letters, kanji or any readable glyph on the talismans, logos, UI, frames, watermark |
| Text | **none** |

### 3. `cg_epilogue.png` — the heart at rest

| Line | Spec |
| --- | --- |
| Size | as `cg_prologue` (raw kept as `cg_epilogue_source.png`) |
| Style | the accepted `cg_prologue` as the **first** reference (same tree position and size, so the two read as before and after), plus refs 1–2 |
| Must show | the same tree with its heart **whole** and glowing soft warm pink-gold (`#ffb8e8`, `#f3cd7c`); gentle light motes rising; the realm islands floating calmly in their places, waterfalls flowing; the sky deep navy at the top fading to a soft lavender and pale-gold dawn glow at the horizon; peaceful |
| Bottom quarter | soft clouds, little detail |
| Avoid | cracks, shockwave, fire, people, text, logos, UI, frames, watermark |
| Text | **none** |

### 4. `dialogue_frame.png` — 9-slice frame of the dialogue box

| Line | Spec |
| --- | --- |
| Size | exactly **480×120**, transparent PNG; 9-slice margins **24 px** on every side |
| Style | ref 4: the same gold `#f3cd7c` / deep gold `#a8742c` and blue gem `#3d7bd9` / `#9fd2ff` ornaments, dark outline `#101827`, 1x pixel art (crisp, nearest-neighbour friendly) |
| Must show | ornate corners (gold flourish with a small blue gem) that stay **inside the 24×24 corner squares**; edges are a plain double line (gold outer, thin blue inner) that can stretch without looking distorted; nothing in the middle of an edge |
| Centre | fully transparent (the game draws a dark backing behind the text) |
| Avoid | text, characters, a filled centre, drop shadow outside the canvas, anti-aliased blur |

### 5. `name_plate.png` — 9-slice plate for the speaker's name

| Line | Spec |
| --- | --- |
| Size | exactly **192×36**, transparent PNG; 9-slice margins **12 px** |
| Style | as `dialogue_frame` |
| Must show | a dark navy plate (`#101827`, alpha about 235) with a 2 px gold border and a tiny blue gem at each end (inside the 12 px end zones) |
| Avoid | text, ornaments in the stretchable middle |

### 6. `shadow_aura.png` — looping aura behind a shadow fighter

| Line | Spec |
| --- | --- |
| Size | a horizontal strip of **6 frames**, each **128×176** → **768×176**, transparent; played at 10 fps, looping (frame 6 flows into frame 1) |
| Placement | the fighter's feet sit at **y=160** in each cell, body centre at **x=64** (fighters are about 90–100 px tall at 1x) |
| Style | ref 5 for the pixel-effect look; palette deep violet `#1a0f2e`, `#3b1d5e`, purple `#6b2fa8`, magenta sparks `#ff4fd8`, faint pink `#ff9be8` |
| Must show | dark violet smoke-flame wisps **rising** around the body outline (densest at the sides and above the head, thin in the middle so the fighter stays readable when drawn on top), a few magenta sparks drifting up |
| Avoid | a figure or silhouette inside, text, anything touching the cell edges (keep a **4 px** empty margin), white halo, square cut-off edges |

## Variants, checks, contact sheets

- Variants: 3 for each scene picture (2 for `cg_epilogue`, made from the chosen prologue), 2 for each frame/plate, 2 for the aura. The frame and plate may be finished by drawing with Pillow on the exact canvas if that matches ref 4 better; say which you did.
- Checks per variant, as a pass/fail table against every line above. Measure: exact pixel size; for transparent files, transparent corners, no checkerboard baked in, no halo; 9-slice: ornaments stay inside the margins (draw the slice lines on a preview); aura: 4 px margin in every frame, loop seam (frame 6 vs frame 1 difference), feet line.
- A contact sheet per asset in `reports/codex-art-70/`: every variant at full size and at display size (scene pictures at 1280×720 with a dark bar over the bottom quarter where the dialogue box goes; the frame and plate stretched to 1160×170 and 220×40 with sample text drawn by Pillow; the aura frames at 1x behind a grey 42×96 body box, and an animated GIF).
- Look at every scene picture at full size for text-like marks, figures, seams and smears before choosing.

## Writable

| Path | For |
| --- | --- |
| `smash-nine-prototype/assets/art/story/**` | the chosen finals (names above), their `*_source.png` raws, `README.md` (Korean: files, sizes, 9-slice margins, aura frames/fps/pivot, prompts, where each is used) |
| `smash-nine-prototype/tests/art_preview/story_70/**` | build and check scripts, previews |
| `reports/codex-art-70/**` | report, contact sheets, unchosen variants (`variants/`) |

Unchosen variants stay out of `assets/` (the web build packs everything there). Forbidden: game code, other assets, design docs, merging, pushing, installing packages, downloads.

## Done when

- [ ] Six finals in `assets/art/story/` with raws and the README.
- [ ] `reports/codex-art-70/README.md` in Korean: per asset the chosen file and why, the pass/fail table, the final prompt, crops/resizes done, the contact sheet, and what a human should judge.
- [ ] Commit on the branch, or `reports/codex-art-70/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
