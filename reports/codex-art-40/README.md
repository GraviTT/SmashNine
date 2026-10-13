# CODEX-ART-40 — Frey 192px 기술 행 후보

## 결과

Frey 기술 9개 행을 1152×192 스트립(192px 셀 6개), 발선 y=152, 몸통 중심 x=96으로 다시 정규화했다. 모든 행은 앵커 대비 헤드 스케일 중앙값 0.98–1.02, 4px 여백, spill 0, 프레임별 detail 90 이상을 만족한다. ART-40에서는 새 원본을 생성하지 않았다.

측정값과 4× 육안 판정은 분리했다. 아래 헤드 스케일은 `head_scale.py` 결과이고, 원본 선택 이유와 장비·얼굴 판정은 4× 비교판을 직접 본 결과다.

## 행별 측정

| 행 | 헤드 스케일 | factor | lift scale | source raw | 원본 선택 이유 |
| --- | ---: | ---: | ---: | --- | --- |
| `attack_chain` (`frey-attack-v4`) | 1.01 | 0.326087 | 1.0 | `art/raw/frey-39/attack/raw.png` | ART-37보다 자세가 셀 안에서 간결하고 3타 실루엣이 또렷함 |
| `attack_up` | 1.01 | 0.307292 | 1.0 | `art/raw/frey-38/attack_up/raw.png` | ART-39안은 프레임 detail 최저 89.01; ART-38안은 98.17 이상이며 올려베기 흐름이 명확함 |
| `attack_down` | 1.01 | 0.310976 | 1.0 | `art/raw/frey-38/attack_down/raw.png` | ART-39안은 프레임 detail 최저 88.75; ART-38안은 96.85 이상이고 검·방패가 전 구간 선명함 |
| `attack_air_side` | 1.02 | 0.30625 | 1.0 | `art/raw/frey-38/attack_air_side/raw.png` | ART-39보다 공중 전진 베기의 준비→찌르기→회수가 연속적으로 읽힘 |
| `dash_strike` | 1.01 | 0.3375 | 1.0 | `art/raw/frey-39/dash_strike/raw.png` | ART-38보다 낮은 돌진 실루엣과 회수 자세가 일관됨 |
| `rising_cleave` | 1.02 | 0.364865 | 1.0 | `art/raw/frey-39/rising_cleave/raw.png` | 상승 높이와 검 궤적이 분명하고 장비 형태가 안정적임 |
| `spike_followup` | 1.02 | 0.324324 | 1.0 | `art/raw/frey-38/spike_followup/raw.png` | ART-39 F2의 과도하게 긴 검보다 하강 베기 실루엣이 일관됨 |
| `descent` | 1.00 | 0.3375 | 1.0 | `art/raw/frey-39/descent/raw.png` | ART-38보다 공중 준비→수직 하강→착지 연결이 간결함 |
| `tumble` | 0.98 | 0.307 | 1.0 | `art/raw/frey-38/tumble/raw.png` | ART-39 재생성본이 없으며, 기존 회전 그림을 원래 상승량으로 복원해도 192px에 들어옴 |

## 자동 검사

- 출력: 모든 행 1152×192, 셀 192, 발선 152
- 헤드 스케일 중앙값: 0.98–1.02 (허용 0.96–1.04)
- 모든 프레임: border clear, 최소 4px 여백, spill 0, alpha binary
- 모든 프레임: interior detail 최저 90.62 이상
- 새 raw 생성: 없음 (`art/raw/frey-40/` 불필요)

## 4× 육안 확인

- [attack_chain 비교](./attack_chain/compare.png)
- [attack_up 비교](./attack_up/compare.png)
- [attack_down 비교](./attack_down/compare.png)
- [attack_air_side 비교](./attack_air_side/compare.png)
- [dash_strike 비교](./dash_strike/compare.png)
- [rising_cleave 비교](./rising_cleave/compare.png)
- [spike_followup 비교](./spike_followup/compare.png)
- [descent 비교](./descent/compare.png)
- [tumble 비교](./tumble/compare.png)

각 비교판은 왼쪽 128px idle 앵커와 오른쪽 192px 후보를 같은 4× 픽셀 배율로 놓고 발선을 맞춘 것이다. 전 행에서 얼굴은 하나이며, 양팔·양다리·검·방패가 유지되고 별도 공격 효과는 없다.

## 아직 잘못되었거나 주의할 점

- `tumble`은 회전 중 얼굴이 옆/거꾸로 돌아가 자동 매칭 점수가 낮아 6프레임 중 정면에 가까운 2프레임으로 중앙값 0.98을 계산했다. 나머지 4프레임은 4×에서 머리·장비 크기를 육안 확인했다.
- `attack_air_side`는 F0(0.53), F4(0.59)가 기본 신뢰도 0.6에 조금 못 미쳐 4프레임으로 중앙값을 계산했다. 두 프레임 모두 4× 육안상 크기 급변이나 얼굴 중복은 없다.
- `descent` F2는 수직 낙하를 강조한 머리카락이 다른 프레임보다 크게 솟아 실루엣 변화가 크다. 장비 누락이나 셀 침범은 없지만, 실제 모션 재생에서 한 프레임 튐처럼 느껴지는지는 리드가 확인해야 한다.
- 후보만 만들었으며 `smash-nine-prototype/`에는 반영하지 않았다. `frey-attack-v4.json`에는 향후 move sheet의 `attack_chain` 행이 된다는 메모를 남겼다.

## 검증

- `python -m unittest tools/sprite_pipeline/test_normalize.py -v`: 18개 통과
- `head_scale.py`: 9개 행 모두 측정, 중앙값 0.98–1.02
- 각 행 `metrics.json`: `factor`, `lift_scale`, `head_scale`, `source_raw`를 `art40` 항목에 기록

