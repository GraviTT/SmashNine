# Frey original sprite sheet

## CODEX-ART-28 move-row 보정

`frey_moves_sheet.png`의 `descent` 3–5번 프레임과 `spike_followup` 4번 프레임을 idle 체급에 맞춰 다시 그렸다. 얼굴과 검 진행 방향이 보이도록 하강 실루엣을 분리했고, 발/중심 기준은 기존과 같이 y=120을 따른다. 최종 768×1024 시트의 셀 크기는 128×128이며 edge audit는 0이다.

ImageGen 1차/2차 원본과 전후 비교는 `tests/art_preview/fx_28/`에 보관한다. 최종 셀은 `build_assets.gd`가 Frey 기준 팔레트, hard alpha, 최근접 축소만 적용해 만든다.

`frey_sheet.png` is the active original-art Frey atlas. The illustration
`frey_illustration.png` is the face, costume, weapon, shield, palette, and proportion reference.

## Atlas contract (v2)

- Canvas: 768×896 RGBA PNG
- Grid: 6 columns × 7 rows; 128×128 per cell
- Facing: right
- Rows: idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1
- Grounded frames: lowest opaque pixel at cell y=120
- Unused cells: fully transparent
- Runtime: position `(0, -56)`, scale `1`, nearest-neighbour filtering
- Target proportion: approximately 3 heads tall

## CODEX-ART-21 review

All 23 used frames were checked individually at 4× and in row sequence. Attack frame 4's
edge-on shield was redrawn from the canonical illustration and adjacent attack frames so the
blue-and-gold oval and star remain readable during recovery. Shield frame 1 was moved up one
pixel to restore the y=120 baseline. All other used cells remain pixel-identical.

The retained ImageGen source, before/after contacts, measurements, and build scripts are in
`reports/codex-art-21/` and `tests/art_preview/sprite_review_21/`.
