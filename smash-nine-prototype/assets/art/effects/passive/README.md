# Frey / Luna passive marks

Godot 4.7용 1x 픽셀 패시브 표시 세트다. 세 PNG는 RGBA8, 투명 배경, 이진 알파(0/255), 최근접 필터용이며 1 art px = 1 screen px를 전제로 한다.

| 파일 | 크기 | 중심 앵커 | 용도 |
| --- | ---: | ---: | --- |
| `frey_pursuit_mark.png` | 64×40 | (32,20) | 표식 대상 머리 위의 하향 발키리 날개 표식 |
| `frey_spike_ring.png` | 96×96 | (48,48) | Frey 둘레에서 퍼지는 강스파이크 재입력 창 |
| `luna_star_charge.png` | 18×18 | (9,9) | Luna 둘레를 도는 별빛 충전 1스택 |

## 표시 계약

- `frey_pursuit_mark`: 대상 위에 중앙 정렬하며 흰금 날개가 작은 금색 점을 향한다. 애니메이션은 코드에서 알파 펄스로 처리한다.
- `frey_spike_ring`: Frey 몸 중심에 정렬한다. 안쪽은 캐릭터가 가려지지 않도록 비어 있다. 0.18초 동안 확대·페이드한다.
- `luna_star_charge`: Luna 몸 중심에서 반경 44px 궤도에 최대 5개를 배치한다. 기존 이동 탄환 `luna_star.png`의 분홍/청록 꼬리와 달리 금백색 중심·보라 외곽만 쓴다.
- 임포트는 `NEAREST`, 밉맵 끔, 색상 변조 없음이 기준이다.

## ImageGen 원본 프롬프트

공통: 내장 ImageGen, genuinely transparent background, crisp hand-clustered pixel art, intentional square pixels, no antialiasing, no text/logo/watermark.

- Pursuit: `one downward-pointing valkyrie pursuit mark; two symmetrical white-gold feathered wings meet in a sharp V-shaped chevron over one small gold downward point; readable above a fighter; Frey gold #FFD27A/#FFB85C, white, dark navy; no full bird or red`.
- Spike ring: `one thin circular gold-white signal ring; four tiny feather motifs at the diagonals; center open for a 60 px fighter; 2–3 px visual stroke at final size; no filled disc or thick outline`.
- Star charge: `one compact upright five-point magical star; brilliant white core, warm gold #FFE06B, violet #662A91 outer contour; brighter than a projectile; no pink fill, cyan trail, blur or particles`.

ImageGen 원본은 `reports/codex-art-22/source/`에 보존했고, `tests/art_preview/passive_marks_22/build_and_verify.ps1`이 알파 크롭 → 최근접 축소 → 제한 팔레트 매핑 → 이진 알파 정리를 수행한다.
