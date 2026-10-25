# SART-02 · Stage title card pictures for the nine story stages (candidates)

- Request: the user, through the status-check session, 2026-10-25: the Codex quota was reset; work that needs no user decision, mainly image and sprite repairs and additions. Story mode area (D43): stage title card art.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-b/SmashNine`, branch `codex/sart-02` (from tag `checkpoint-2026-10-25`). Lead: Claude (reviews every image at full size).
- Running at the same time: SART-01 (three scene pictures) in the story-art-a clone. Other sessions run their own units. You share no files with anyone.
- **Candidates only.** Nothing under `smash-nine-prototype/` changes; the game is not wired to these files.
- Read first: `reports/story-mode-plan-2026-10-22.md` sections 3 and 6, `design/STORY.md` (stage titles), `smash-nine-prototype/scripts/ui/StoryScreens.gd` `show_stage_card` and `show_story_map` (where a card picture would go later), `smash-nine-prototype/assets/art/story/README.md`.

## Why

The stage start card and the story map's detail panel show only the realm's 32 px emblem. A small painted picture per stage would tell at a glance where the hero is and what happens there.

## Image spec

Common to all nine:

| Line | Spec |
| --- | --- |
| Size | final **640×360**, opaque. Generate landscape at the largest size offered, crop to 16:9, downscale with LANCZOS; never upscale. Shown later at about 360–480 px wide, so it needs **one strong landmark with a clear silhouette**, not fine clutter. |
| Style | painted pixel art like the game's backgrounds and ART-70: attached refs 1 `title_bg.png` and 2 `cg_prologue.png`; for each stage also load that realm's `bg_far.png` (table below) with `view_image` and pass it to `image_gen` as a reference for palette and landmarks |
| Set | the nine read as **one set**: the same wide establishing view, the landmark in the middle third, horizon in the lower third, light from the upper left, similar saturation and contrast; the edges a little calmer than the centre (a frame may cover 8 px) |
| Avoid | people, faces, figures, text, letters, glyphs, logos, UI, frames, borders, watermark, photographic look |
| Text | **none** (titles are drawn by the game) |

| # | File stem | Stage title (story.csv) | Realm reference | Must show |
| --- | --- | --- | --- | --- |
| 1 | `stage_card_01` | 부서진 하늘 | `realm_midgard/bg_far.png` | the human town's rooftops at dusk under a sky split by glowing cracks, far realm islands drifting |
| 2 | `stage_card_02` | 발키리의 문 | `realm_asgard/bg_far.png` | Asgard's golden gate and castle, columns of light falling around it, a wing motif on the gate |
| 3 | `stage_card_03` | 달빛 다리 | `realm_alfheim/bg_far.png` | a long moonlit bridge with two glowing round moon gates at its ends under a large crescent moon |
| 4 | `stage_card_04` | 태엽 도시 | `realm_svartalfheim/bg_far.png` | the dwarven clockwork city: big gears, a forge glow, conveyor belts with chevrons |
| 5 | `stage_card_05` | 무너지는 숲 | `realm_vanaheim/bg_far.png` | the forest temple with vine bridges, the island cracking with an orange collapse glow |
| 6 | `stage_card_06` | 중력의 우물 | `realm_jotunheim/bg_far.png` | giant stone ruins around a swirling gravity well, stones floating upward, storm sky |
| 7 | `stage_card_07` | 불의 짐승 | `realm_muspelheim/bg_far.png` | the lava fortress with eruption pillars; only a hint of the beast: two glowing eyes and curved tusks half hidden in smoke |
| 8 | `stage_card_08` | 얼어붙은 뿌리 | `realm_niflheim/bg_far.png` | an ice cavern with the frozen root of the world tree under aurora light |
| 9 | `stage_card_09` | 세계수의 심장 | `realm_center/bg_far.png` | the world tree with its glowing pink heart above the final arena's floating platform |

## Variants, checks, deliverables

- **Two clearly different variants per stage** (18 generations). Version as `-v1`, `-v2`; an edit after your own review is `-v3`.
- Raw generations go to `art/raw/story/<stem>-vN_raw.png` (git-ignored).
- Candidates go to `art/bakeoff/story/<stem>-vN.png` (640×360), each with `<stem>-vN.json`:
  - `note` in Korean
  - `stage`, `title`
  - `size`, `processing`
- Check each variant against every spec line (pass/fail). Measure size and the set's spread of mean brightness and saturation, so outliers show. Look at every picture at full size for text-like marks, faces or figures.
- Contact sheets in `reports/codex-sart-02/` (JPEG quality 90, at most 2 MB each):
  1. per stage, both variants at full size and at 480×270
  2. **set board:** your recommended variant of each stage in the story map's 3×3 order:
     - top row: ② 발키리의 문, ① 부서진 하늘, ⑧ 얼어붙은 뿌리
     - middle row: ③ 달빛 다리, ⑨ 세계수의 심장, ⑦ 불의 짐승
     - bottom row: ④ 태엽 도시, ⑤ 무너지는 숲, ⑥ 중력의 우물
     - under each, the number and the Korean title drawn with Pillow (Malgun Gothic), exactly as written above
- `reports/codex-sart-02/README.md` in Korean:
  - per stage the variants, pass/fail, final prompt, processing
  - the set measurements
  - which variant you recommend and why. The user picks later.

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `art/bakeoff/story/stage_card_*` | candidates and their JSON |
| `art/raw/story/**` | raw generations (git-ignored) |
| `reports/codex-sart-02/**` | report and contact sheets |

Forbidden: `smash-nine-prototype/**`, `design/**`, other files in `art/bakeoff/story/`, other sessions' files, merging, pushing, installing packages, downloads.

## Done when

- [ ] 18 candidates with JSON, contact sheets and README.
- [ ] Commit on the branch, or `reports/codex-sart-02/commit.ps1` staging only the writable paths (not `art/raw/`), message ending `Co-Authored-By: Codex <noreply@openai.com>`.
