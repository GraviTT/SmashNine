# CODEX-ART-52B · Nova 여성 몸 phase 2 결과

여성 Nova(`nova_female`)의 카드 전 행을 D35 방식으로 후보 제작했다. 기본행 6개(`walk`, `jump`, `fall`, `hurt`, `shield`, `attack`)와 192px 기술행 9개를 만들었으며, 게임 파일은 바꾸지 않았다. 원격 생성은 전부 built-in ImageGen을 사용했고 실제 사용 프롬프트는 각 행의 `prompt.txt`에 남겼다. `jump`/`fall`/`hurt`는 카드 지시대로 한 번의 공용 생성, `attack`은 `vector_side` 원본을 재사용했다.

전체 후보를 같은 게임 픽셀 배율로 훑는 실제 스트립 모음은 `overview.png`다.

## 행별 결과

| 행 | 후보 파일 | 프레임 | 머리 확인 | 공통 배율 | lift / 이동 | 아직 보이는 제한 |
|---|---|---:|---|---:|---|---|
| walk | `nova_female-walk-v1.png` | 6 | 자동 중앙값 1.02, 6/6 신뢰 | 0.267284 | 0 | 접촉-다운-패싱은 읽히지만 머리카락 지연 폭은 작다. |
| jump | `nova_female-jump-v1.png` | 1 | 자동 0.96(1프레임) + 4배 크롭 | 0.188228 | +8px | 한 장 자세라 실제 상승 연결감은 게임에서 확인해야 한다. |
| fall | `nova_female-fall-v1.png` | 1 | 자동 1.02(1프레임) + 4배 크롭 | 0.190000 | +8px | 위로 선 머리카락이 실루엣 높이를 크게 만든다. |
| hurt | `nova_female-hurt-v1.png` | 1 | 자동 0 usable(0.46), 4배 크롭으로 판정 | 0.190000 | +8px | 누운 자세라 키 수치를 크기 판정에 쓰지 않았다. |
| shield | `nova_female-shield-v1.png` | 6 | 자동 중앙값 1.00, 3프레임 신뢰 | 0.237843 | 0 | F3–F6 얼굴이 팔에 많이 가려지지만 의도한 X자 방어다. |
| attack | `nova_female-attack-v1.png` | 6 | 자동 중앙값 1.02, 6/6 신뢰 | 0.258525 | x +2px | 128px에서 같은 배율이 들어갔고 F3–F4는 의도한 유지 프레임이다. |
| vector_side | `nova_female-vector_side-v3.png` | 6 | 자동 중앙값 1.02, 6/6 신뢰 | 0.258525 | 0 | 셀 안 뿌리는 고정되어 있어 실제 전진은 런타임 이동이 담당해야 한다. |
| vector_upper | `nova_female-vector_upper-v1.png` | 6 | 자동 중앙값 1.04, 2프레임 신뢰 | 0.290052 | 0–21px | 위로 든 팔 때문에 4프레임의 자동 점수는 낮았고 F4–F5는 정점 유지다. |
| compression_stomp | `nova_female-compression_stomp-v1.png` | 6 | 자동 중앙값 1.02, 6/6 신뢰 | 0.237843 | 0 | 프레임별 자동값은 0.92–1.10으로 흔들리지만 4배 실루엣과 중앙값은 통과한다. |
| air_side | `nova_female-air_side-v1.png` | 6 | 자동 중앙값 1.02, 6/6 신뢰 | 0.261366 | 16–41px | 전 프레임 공중이지만 생성 원본의 상대 높이 때문에 비행 호가 조금 크다. |
| meteor_kick | `nova_female-meteor_kick-v1.png` | 6 | 자동 중앙값 1.02, 6/6 신뢰 | 0.255745 | 0–29px | F5 착지 접촉은 읽히지만 강한 충격은 게임 이펙트가 있어야 완성된다. |
| vector_shift | `nova_female-vector_shift-v1.png` | 6 | 자동 중앙값 0.96, 6/6 신뢰 | 0.283146 | 0–25px | F3–F4는 의도한 가속 유지라 차이가 작다. |
| gravity_brake | `nova_female-gravity_brake-v1.png` | 6 | 자동 중앙값 0.96, 6/6 신뢰 | 0.237843 | 0–4px | 급정지 자체는 읽히지만 폭발 세기는 게임 이펙트가 담당한다. |
| slingshot_start | `nova_female-slingshot_start-v1.png` | 6 | 자동 중앙값 1.02, 6/6 신뢰 | 0.270276 | 0 | 192px에서는 열린 손바닥이 명확하며 중력핵은 의도대로 비어 있다. |
| tumble | `nova_female-tumble-v1.png` | 6 | 자동 0 usable(최고 0.52), 4배 크롭으로 판정 | 0.237843 | 16–29px | 긴 머리가 회전 실루엣을 크게 만들지만 머리·얼굴 크기는 앵커와 맞는다. |

단일 포즈와 tumble은 신뢰 프레임이 2개 미만이라 `head_compare.png`에서 4배 머리 크롭을 앵커와 직접 비교했다. standing 기준은 앵커 F0의 높이 89px이며, 웅크리거나 누운 후보 자체의 몸 높이로 배율을 정하지 않았다. tumble은 Nova 기존 행이 없어 수락된 Yuki tumble을 회전 순서 참고로만 사용했고 외형·크기는 여성 Nova 앵커만 따랐다.

## 수치 검사

- 모든 최종 PNG: RGBA, 이진 알파, 테두리 비움, 최소 4px 여백, 초록 번짐 0px.
- 내부 디테일 최저값: 전체 행 중 `tumble` 82.70으로 여성 기준 79 이상.
- 기본행: 128px 셀, 발선 y=120. 기술행: 192px 셀, 발선 y=152.
- `attack`만 같은 `vector_side` 배율에서 왼쪽 여백이 2px였으므로 전 프레임 공통 x +2px를 적용했다.
- 자동 머리 측정과 분리해 매 행 `compare.png`를 원본 크기 4배로 열어 얼굴 1개, 두 팔/건틀릿, 두 다리/부츠, 동작 의미를 확인했다.
- 생성 원본은 `art/raw/nova-52b/`에 복사했으며 git 대상이 아니다.

## 남은 작업

- 카드의 행은 모두 도달했다. 미완료 행은 없다.
- 후보이므로 모션 뷰어에서 10/12/14–40fps 실제 재생을 보고 리드가 채택 여부를 결정해야 한다.
- 특히 walk의 머리카락 지연 폭, compression_stomp의 프레임별 머리 측정 흔들림, air_side의 큰 높이 호를 움직임으로 확인하는 것이 좋다.
- `smash-nine-prototype/` 제품 파일과 런타임 연결은 변경하지 않았다.
