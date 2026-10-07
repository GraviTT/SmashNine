# CODEX-ART-08B 결과 보고

## 완료

Unit B 담당 순서대로 Rio 남성, Rio 여성, Luna의 메인 일러스트와 얼굴 포트레이트를 만들고, Rio 남성/여성·Luna·Brave Luna의 v2 스프라이트 시트를 만들었다. 기존 의상, 색상, 머리, 무기와 실루엣 아이디어를 참조 이미지로 고정하고 인체 비례와 픽셀 디테일을 높였다.

제품 소스(`scripts/`, `characters/`, `scenes/`, `project.godot`)는 수정하지 않았다.

## 산출물

| 캐릭터 | 메인 일러스트 | 얼굴 | v2 시트 |
|---|---|---|---|
| Rio 남성 | `assets/art/rio/rio_male_illustration.png` (1024×1536) | `rio_male_face.png` (256×256) | `rio_male_sheet.png` (768×896) |
| Rio 여성 | `assets/art/rio/rio_female_illustration.png` (1024×1536) | `rio_female_face.png` (256×256) | `rio_female_sheet.png` (768×896) |
| Luna | `assets/art/luna/luna_illustration.png` (1024×1536) | `luna_face.png` (256×256) | `luna_sheet.png` (768×896) |
| Brave Luna | 시간 우선순위에 따라 별도 일러스트 없음 | Luna 얼굴 공유 가능 | `luna_brave_sheet.png` (768×896) |

생성 원본은 같은 아트 폴더의 `*_illustration_source.png`, `*_v2_source.png`에 보관했다. 사용한 최종 프롬프트와 방식은 `PROMPTS.md`에 기록했다.

## 측정 사실

모든 시트는 6×7, 셀 128×128이며 행 계약은 idle 4 / walk 6 / jump 1 / fall 1 / attack 4 / shield 6 / hurt 1이다. 각 시트의 사용 프레임은 23개이고, 나머지 19개 셀은 완전 투명하다.

| 시트 | 목표 몸 높이 | 프레임 수 | 최종 불투명 중심 x 범위 | 전체 알파 경계 높이 범위 |
|---|---:|---:|---:|---:|
| Rio 남성 | 98 px | 23 | 63.54–64.74 | 89–121 px |
| Rio 여성 | 96 px | 23 | 63.51–64.50 | 95–121 px |
| Luna | 84 px | 23 | 63.59–64.46 | 87–98 px |
| Brave Luna | 84 px | 23 | 63.58–64.49 | 84–113 px |

- 모든 프레임의 배치 기준은 중심 x=64, 발 기준선 y=120이다.
- 표의 `전체 알파 경계 높이`는 머리카락, 무기, 공격·방패 이펙트를 포함하므로 몸 높이보다 클 수 있다.
- 프레임별 경계, 불투명 중심, 불투명 픽셀 수는 `alignment.csv`에 있다.
- 4개 시트 합계 사용 프레임 92개, 미사용 셀 76개를 자동 검증했다.

## 시각적 확인

`contact_sheet.png`는 캐릭터별로 왼쪽부터 v1 시트 2배, v2 시트 1배, 얼굴, 축소 일러스트를 배치했다. Brave Luna 행은 별도 일러스트를 만들지 않아 시트 비교만 있다.

## 검증

실행 명령:

```powershell
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/hires_b/build_hires_b.gd
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/hires_b/verify_hires_b.gd
```

최종 결과: `HIRES_B_BUILD_OK`, `HIRES_B_VERIFY_OK illustrations=3 faces=3 sheets=4 frames=92 unused_cells=76`.

Godot가 출력한 `Failed to read the root certificate store`는 카드에 명시된 샌드박스 잡음이다. `Image.load_from_file`의 export 경고는 오프라인 아트 빌드/검증 스크립트가 PNG를 직접 읽기 때문에 발생하며 게임 런타임 경고가 아니다.

## 리드 통합 메모

- 기존 시트 파일명을 그대로 교체했지만 셀은 64px에서 128px로 바뀌었다. 리드의 v2 계약에서 128×128 셀, 1배 렌더링, 발 y=120을 사용해야 한다.
- `Luna.gd`의 Brave 시트 추가 경로도 현재 64×64를 직접 지정하므로 리드의 v2 전환에서 함께 128×128로 바뀌어야 한다.
- 새 얼굴 파일은 기존 `*_portrait.png`를 덮어쓰지 않았다. HUD/캐릭터 선택 화면에서 새 `*_face.png`를 명시적으로 연결해야 한다.
- 메인 일러스트는 현재 런타임에 연결하지 않았다.

## 사람이 판단할 부분

다음은 측정값이 아니라 미감 결정이다.

- Rio 여성 일러스트의 노출도와 갑옷/치마 비율이 최종 캐릭터 톤에 맞는지
- Luna 일러스트의 프릴과 별 장식 밀도가 기존 단순 실루엣에 비해 과하지 않은지
- 1배 화면에서 Rio의 룬 방패와 Luna의 별 방패가 충분히 읽히는지
- 공격 이펙트가 128px 셀 경계에서 끊기는 모습이 애니메이션 재생 중 허용 가능한지
- 얼굴 컷의 어깨 비중과 시선 방향이 실제 HUD 64–96px에서 적절한지

## 남은 작업

- Brave Luna 별도 메인 일러스트와 별도 얼굴은 선택 사항이라 만들지 않았다.
- 실제 게임 연결과 플레이 화면 캡처는 제품 소스 쓰기 금지 및 리드의 v2 전환 작업과 겹치므로 수행하지 않았다.
- 전체 게임 테스트는 제품 코드가 아직 이 브랜치에서 v2 시트 계약으로 전환되지 않아 실행하지 않았다.

