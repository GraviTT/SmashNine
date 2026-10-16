# CODEX-DOC-02 · Picture report of the sprite audit (explained with images)

- Request: 사용자 2026-10-16 "점검 보고서는 알기 쉽게 Codex에게 이미지로 만들어 설명 하게 할 것."
- Unit: Builder (images) · Lead (reviews every word, merges, writes the report text): Claude.
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/auditor/SmashNine`, branch `codex/doc-02` (from the latest main).
- Read first:
  - `reports/debate-sprite-audit/decision.md`: the decisions these images explain
  - `reports/codex-qa-19/README.md` and its boards: your own audit, for the frames and numbers
- Running at the same time: no other Codex unit. **This task does not edit `smash-nine-prototype/` or any art.**

## Writable paths

| Path | For |
| --- | --- |
| `reports/sprite-audit-2026-10-16/images/**` | the ten images and `contact.png` |
| `reports/sprite-audit-2026-10-16/images.md` | which frames each image uses (clip, frame, commit) |
| `tests/analysis/codex_doc_02/**` | your board script (Python + Pillow) |

## How to make them
- **Every picture is a real game frame or sprite.** Do not use image_gen. Draw all text with Pillow:
  - `C:/Windows/Fonts/malgunbd.ttf` (titles, tags)
  - `C:/Windows/Fonts/malgun.ttf` (captions)
- **Before and after.** "전" frames come from the clips at commit `de5e589`, "후" frames from the clips at commit `1b61483` (it is in your clone).
  - Read a clip with `git show <commit>:art/clips/<form>/<scene>-fx.webp > file`.
  - Use the same frame index for 전 and 후 (pick the frame that shows the problem best).
- **Scaling.**
  - Crop around the action and scale by whole numbers with NEAREST (1× or 2×). Never blur.
  - Keep the floor line visible where the floor matters.
- **Format.**
  - PNG, 1600×900.
  - Background `#101522`.
  - Title 44 px bold, captions 28 px. Nothing under 24 px: the user reads these on a phone.
  - Tags: "전" on `#e5484d`, "후" on `#30a46c`, white text.
  - Highlight boxes and arrows in `#ffd166`, 4 px.
- **Text.** Use exactly the strings below, no other sentences. Character names and numbers may label panels: frame numbers, ×0.76.

## The ten images (`images/NN-name.png`)

| # | File | Panels | Title (exact) | Caption (exact) |
|---|---|---|---|---|
| 01 | `01-summary.png` | the 8 forms' idle sprites (1×) in a row; under each, two coloured dots: sprite, effect (green ok, yellow fix decided, red redraw candidate); a legend | 점검 결과 한눈에 | 그림 파일은 대부분 깨끗하다. 문제는 이펙트를 그리는 코드에 있었다. / 초록 = 좋음 · 노랑 = 코드로 고침 · 빨강 = 다시 그림 후보 |
| 02 | `02-guard.png` | guard clips of the 6 fighters at the same frame, 전 (commit `28ffe0a`) row and 후 (`de5e589`) row | 방어 호 위치 | 전: 호가 몸통을 가르고 바닥 아래로 내려갔다. / 후: 호가 몸 앞을 감싸고 바닥에서 끝난다. |
| 03 | `03-j-trail.png` | Frey ground J, Nova ground J, Luna air J: 전 / 후 | 기본 공격(J) 궤적 두께 | 궤적이 몸의 두 배 높이라 자세가 가려졌다. / 길이(판정 끝)는 그대로, 두께만 0.62배로 줄였다. |
| 04 | `04-doubled.png` | Rio rune counter (frame 25), Nova side J, Nova up J: 전 / 후 | 한 번에 겹쳐 나오던 이펙트 | Rio 룬 반격과 Nova 옆·위 J는 공용 베기와 전용 이펙트를 함께 냈다. / 이제 전용 이펙트만 낸다. |
| 05 | `05-ground-down.png` | Frey and Luna ground ↓J: 전 / 후, floor line marked | 땅에서 아래로 치는 J | 밝은 부분이 바닥 아래로 사라졌다. / 판정은 그대로, 보이는 궤적만 바닥을 따라 눕혔다. |
| 06 | `06-bloom.png` | Luna and Brave Luna J with a star bloom on the target: 전 / 후 | 별꽃은 캐릭터 뒤로 | 궤적과 별꽃이 한 덩어리 섬광이 되어 상대를 가렸다. / 별꽃을 캐릭터 뒤에 그려 상대가 보인다. |
| 07 | `07-ultimate-flash.png` | Luna transformation, Nova ultimate, Yuki ultimate finish: 전 / 후 | 궁극기 섬광 투명도 | 화면 전체가 하얗게 덮여 다른 선수까지 사라졌다. / 크기와 시간은 그대로, 70%만 보이게 했다. |
| 08 | `08-rio-head.png` | Rio idle head next to the four small rows (male attack ×0.76, female attack ×0.86, female low sweep ×0.72, female dimension slash ×0.72), 3× | Rio 머리 크기 (다시 그림 후보) | 네 동작에서 머리가 대기 그림보다 작다. / Rio만 다시 그린 후보를 만들어 고르게 한다. |
| 09 | `09-nova-hurt.png` | Nova female hurt now (v1) and candidate (v2: `art/bakeoff/nova/nova_female-hurt-v2.png`), 3×, floor line y=120 | Nova(여) 피격 한 장 | 지금은 바닥에서 8px 떠 있다. / 8px 내린 후보를 모션 뷰어에 올렸다. 고르면 들어간다. |
| 10 | `10-kept.png` | Brave Luna aura and Rio ultimate circle (후 frames); one fighter sprite with its 42×64 hurtbox drawn as a box | 그대로 두는 것과 다른 세션 몫 | Brave 오라와 Rio 궁 원은 몸을 가리지 않아 유지한다. / 피격 상자(42×64)보다 그림이 크다: 판정은 스킬 세션에 알린다. |

In the Caption column, " / " splits two lines. Draw them as two lines.

## Output and checks
- The ten PNGs, then `contact.png`: all ten at 400×225, in a grid.
- `images.md`: per image, the clip, the frame and the commit of every panel.
- Check each image at 400×225 (a phone thumbnail) and say whether it still reads.
- `reports/sprite-audit-2026-10-16/commit.ps1` (writable paths only; no `git add -f`, no `__pycache__`).
- Final answer in Korean: the list of images, what each shows, the frames used, anything you could not show.

Hard stop: 60 minutes.
