# CODEX-ART-19 · Bot behaviour mind map / tree diagram

- Request: 사용자 2026-10-09 "특정 캐릭터가 아닌 모든 기본적인 봇들의 행동 원리를 정리하고, 기본에서 뻗어나가 특정 캐릭터는 추가적으로 어떻게 행동하다 라는 것을 이미지로 정리. 이미지는 Codex에게 생성 요청 하고, 마인드맵이나 트리 다이어그램 형태로 제작할것."
- Unit: Builder (image) · Lead (content, review): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/bot-tree-19`
- Read first: `reports/bot-behavior/tree.json` (every word of the image), `reports/bot-behavior/README.md` (what it means, in more detail), `smash-nine-prototype/scripts/EnemyAI.gd` (the bot brain the text comes from).
- Running at the same time: Codex analyst (bot matches, CPU heavy). **This task does not edit product source, tests, `tree.json` or the README.**
- Timeout: given in the prompt.

## What to make

One explainer image for the user (reads Korean), opened on a PC monitor in an image viewer. It shows how every bot thinks, and how each character branches off that base:

- **Root:** `root` of `tree.json` ("기본 봇 (모든 캐릭터 공통)").
- **Common part:** the root → 4 groups (판단 · 이동 · 전투 · 생존, each in its `color`) → 12 branches → their leaves.
- **Characters:** one more child of the root, `characters_label` ("캐릭터별 추가 행동"), branching into the 5 characters. Each character node: face picture, `name`, `role`, `profile` line, its leaves, in the character's `color`. It must read as "the base, plus these extras": the characters hang off the base, not beside it as a separate chart.
- **Title** and **subtitle** at the top, **footer** at the bottom.

Form: a mind map or a tree diagram (the user's words). Make **3 clearly different layout variants** (e.g. A radial mind map around the root, B left-to-right tree in columns, C your own idea) and choose the most legible one.

## Spec

| Item | Value |
| --- | --- |
| Size | PNG, 3840 px wide, height as the layout needs (2160–2800 px). No scaling of text after rendering. |
| Legibility | must still read at 50% (1920 px wide): leaves at least 28 px, branch labels at least 34 px bold, group labels at least 44 px bold, title at least 64 px bold (sizes at full resolution). Long leaves may wrap to two lines; never shrink one leaf below the rest. |
| Text | **every string exactly as in `tree.json`** (Korean, with its spaces, dots `·`, numbers and units). No other words. No paraphrase, no shortening, no translation, no added labels. `\n` in `root` is a line break. |
| Font | a Korean system font already installed: Malgun Gothic (`C:/Windows/Fonts/malgun.ttf`, bold `malgunbd.ttf`) or Noto Sans KR (`NotoSansKR-VF.ttf`). No downloads. |
| Background | light (`#F7F8FB` or similar) with dark text `#1F2430`; text on a saturated group colour is white. Contrast at least 4.5:1 for all text. |
| Colours | groups and characters use the `color` values in `tree.json` (fills, connectors or accents); keep each branch's colour consistent from root to leaves. |
| Faces | `face` paths in `tree.json` (256×256 game art), drawn at 96–128 px with nearest-neighbour scaling (pixel art stays sharp), in a circle or rounded square. |
| Skill icons (optional) | `smash-nine-prototype/assets/art/skill_icons/<id>_<k|l|i>.png` (40×40) next to the leaves that name K, L or the ultimate, at 40 or 80 px nearest-neighbour. |
| Connectors | clean curves or elbows, no crossings, no line through text. |
| Must avoid | text overlapping anything, clipped text, lines crossing labels, tiny decorative text, drop-shadow mush, words drawn by an image generator. |

**How to render:** draw the diagram in code from `tree.json` (HTML/SVG rendered by headless Chrome or Edge — `C:/Program Files/Google/Chrome/Application/chrome.exe`, `C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe`, e.g. `--headless=new --screenshot=... --window-size=3840,H --hide-scrollbars --force-device-scale-factor=1 --user-data-dir=<a folder in your writable path>` — or Godot in windowed mode). One command must re-render the final PNG from `tree.json`, so the lead can fix a word and render again. Your image generation tool may be used only for text-free decoration (a subtle background or ornaments) in at most one variant; all words are drawn by code.

## Check the content too (independent verification)

Before drawing, check each label of `tree.json` against `EnemyAI.gd` and the character files. List every statement the code does not support (label, what the code does, file:line) in your report. Draw the labels as given anyway; the lead fixes the text and re-renders.

## Checks (measured, in the report)

- Final pixel size; every string of `tree.json` present exactly once (compare your rendered text list with the JSON programmatically, e.g. from the HTML before the screenshot).
- No overlapping boxes or text (bounding boxes from the layout code), nothing clipped at the edges.
- Contrast ratio of each text colour pair.
- Contact sheet `reports/codex-art-19/contact.png`: all 3 variants at 25% side by side, and a 100% crop of the densest region of each.
- Look at the chosen image yourself at 100% and at 50% before you choose.

## Writable paths

| Path | For |
| --- | --- |
| `reports/codex-art-19/**` | render scripts, HTML/SVG sources, variants, contact sheet, report, browser profile folder |
| `reports/bot-behavior/bot-behavior-tree.png` | the chosen final image |

Forbidden: product source, tests, `reports/bot-behavior/tree.json` and `README.md`, the project's direction/agent/design docs, merging, pushing, installing packages, downloads.

## Report (`reports/codex-art-19/README.md`, Korean)

Which variant was chosen and why, the content check (label → code mismatch list), the measured checks, how to re-render, what a human should judge (layout taste). Commit, or `reports/codex-art-19/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
