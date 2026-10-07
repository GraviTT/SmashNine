# CODEX-ART-03 B 결과 — Luna / Rio

## 완료

Builder B 범위의 우선순위 시트 3장을 모두 제작했다. Luna는 여성 1종, Rio는
동일한 캐릭터 디자인의 남성/여성 체형 2종이다. 세 시트 모두 Frey와 같은
384x448 RGBA, 6x7, 64x64 셀 계약을 사용한다. 추가 조건을 충족한 뒤 각 시트와
같은 팔레트의 64x64 초상화도 만들었다.

### 최종 아트

| 캐릭터 | 시트 | 초상화 |
|---|---|---|
| Luna | `assets/art/luna/luna_sheet.png` | `assets/art/luna/luna_portrait.png` |
| Rio 남성 | `assets/art/rio/rio_male_sheet.png` | `assets/art/rio/rio_male_portrait.png` |
| Rio 여성 | `assets/art/rio/rio_female_sheet.png` | `assets/art/rio/rio_female_portrait.png` |

위 경로는 모두 `smash-nine-prototype/` 기준이다. ImageGen 원본도 각 아트 폴더에
보존했다. Luna는 분홍/보라 별 마법사, Rio는 남색/청록/은색 룬 마검사로 설계해
Frey의 금색/강철 실루엣과 분리했다.

## 생성 및 후처리

- 내장 ImageGen을 사용했다. Frey의 승인된 `generated_source.png`를 픽셀 밀도,
  외곽선, 치비 비율, 6x7 배치 참고로 사용했다.
- Luna 프롬프트는 별 보석 마법봉, 분홍/보라 의상, 별 궤적 공격과 전면 별 방패를
  요구했다.
- Rio 남성 프롬프트는 남색 아카데미 전투복, 청록 패널/다이아몬드 문장, 수정 손잡이
  은색 검, 사선 마나 참격과 기하 룬 방패를 요구했다.
- Rio 여성 프롬프트는 남성 원본을 직접 참조해 장비·팔레트·문장·검·룬을 고정하고,
  체형·얼굴 표현·사이드 포니테일만 달리하도록 했다.
- `tests/art_preview/chars_b/build_sheets.gd`가 원본 셀을 실제 불투명 영역으로 자른 뒤
  최대 51x42에 비율 유지 최근접 축소, 알파 임계값 적용, 작은 분리 조각 제거,
  중심/발 정렬, 384x448 재조립을 수행한다.

## 측정 사실

| 시트 | 사용 프레임 | 불투명 높이(px) | 불투명 너비(px) | 중심 x 범위 | 발 y |
|---|---:|---:|---:|---:|---:|
| Luna | 23 | 37–42 (평균 41.09) | 41–51 (평균 48.91) | 31.52–32.47 | 전부 48 |
| Rio 남성 | 23 | 33–42 (평균 41.00) | 39–51 (평균 47.39) | 31.52–32.45 | 전부 48 |
| Rio 여성 | 23 | 34–42 (평균 40.74) | 40–51 (평균 48.87) | 31.53–32.48 | 전부 48 |

- 3장 모두 384x448 RGBA8다.
- 총 69개 사용 셀이 비어 있지 않다.
- 총 57개 미사용 셀은 완전 투명하다.
- 초상화 3장은 모두 64x64 RGBA8다.
- 세부 프레임 측정값은 `alignment_luna.csv`, `alignment_rio_male.csv`,
  `alignment_rio_female.csv`에 있다.

## 시각 확인

- `roster_contact.png`: Frey, Luna, Rio 남성, Rio 여성을 같은 배율로 나란히 표시
- `contact_sheet.png`: 7개 애니메이션을 모두 2배 최근접으로 표시
- `compare_idle.png` 등 7장: 각 동작을 Frey 기준과 같은 화면에서 비교

어두운 배경에서 Luna의 분홍/보라와 Rio의 청록/남색이 Frey의 금색/강철과 분리되어
보인다. 공격 행은 준비 → 마법/검격 활성 → 회수 흐름, 방패 행은 Luna의 별 방패와
Rio의 기하 룬 방패가 보인다.

## 검증 결과

```text
[chars-b-build] PASS sheets=3 size=384x448 cell=64 feet_row=48 work=51x42
CHARS_B_VERIFY PASS sheets=3 size=(384, 448) used_frames=69 feet_row=48 unused_cells=57 transparent
[chars-b-preview] PASS comparisons=7 roster_contact=1 scale=2x
```

최종 프리뷰는 Godot 4.7 Compatibility 창 모드에서 캡처했다. 인증서 오류 이외의 실행 오류는 없었고,
샌드박스에서만 발생하는 알려진 `Failed to read the root certificate store` 한 줄은 별도
환경 소음으로 확인했다. `Image.load_from_file`의 export 관련 경고 1건은 테스트 전용
프리뷰 스크립트가 import 캐시와 무관하게 생성 PNG를 즉시 읽기 위한 방식에서 나온다.

## 리드 통합 메모

- 제품 소스는 수정하지 않았다.
- Luna는 현재 여러 스트립 텍스처를 쓰므로, 원본 아트 토글에 연결할 때 Frey와 같은
  `CharacterAnimation.add_grid()` 행 오프셋(0, 6, 12, 18, 24, 30, 36)을 사용해야 한다.
- Rio 구현 브랜치에서도 동일한 그리드 계약을 사용할 수 있다. 성별 선택 기준은 제품
  설계 결정이 필요하며, 두 시트는 애니메이션 프레임 수와 정렬이 동일하다.
- 런타임 표시 계약은 위치 `(0, -32)`, 배율 `2`, nearest 필터다.

## 사람이 판단할 항목

- Luna의 고채도 분홍색과 별 마법 효과 밀도가 실제 8인 전투에서 적절한지
- Rio 남녀의 체형/머리 실루엣 차이가 충분한지, 또는 더 큰 차이를 원하는지
- Rio의 룬 방패와 Luna의 별 방패 크기가 피격 판정과 무관한 시각 효과로 적절한지
- 초상화가 시작 화면에서 충분히 얼굴 중심으로 읽히는지

위 항목은 측정 통과 여부가 아니라 취향과 전투 가독성에 관한 최종 사용자 판단이다.

## 미수행 / 제한

- 제품 소스 연결, 캐릭터 선택 UI 연결, 실제 매치 플레이테스트는 이 유닛의 쓰기 범위가
  아니어서 수행하지 않았다.
- 시트의 정적 프레임과 2배 컷은 검증했지만, 제품 캐릭터에 연결된 시간축 애니메이션은
  리드 통합 후 확인해야 한다.
