# 아트 채택 경로

## 가져오기 압축 규칙 (D52, 2026-11-24)

새 그림을 넣을 때 `.import`의 `compress/mode`를 아래처럼 둔다. `tests/test_import_modes.gd`(run_all)가 검사한다.

| 그림 | 압축 | 까닭 |
|---|---|---|
| 얼굴(`*_face*.png`), 타이틀 배경(`ui/title_bg.png`) | 손실 WebP, `compress/mode=1`, `compress/lossy_quality=0.9` | 붓으로 그린 일러스트라 손실 압축이 눈에 띄지 않는다. 웹 용량 −2.7MB |
| 스토리 장면 그림(`story/cg_*`), 시작 카드(`story/stage_card_*`) | 손실 WebP, 품질 0.85 | 같은 까닭(이전부터) |
| 캐릭터 전신 일러스트(`*_illustration.png`, 원본 1024×1536) | 손실 WebP 품질 0.9, 가져올 때 긴 변 768로 줄임(`process/size_limit=768` → 512×768) | 선택 화면·스토리 화면이 그리는 그림이라 웹 빌드에 들어가야 한다(2026-11-25, 그전에는 빠져 있어 얼굴 그림이 대신 나왔다). 원래 크기로는 예산을 넘는다. 9장 0.8MB. 변신 폼(Brave Luna) 일러스트는 쓰는 화면이 생기면 웹 빌드에 넣는다 |
| 그 밖의 모든 그림: 몸·기술 시트, 동작 줄, 몬스터, 이펙트, 렐름 배경, 아이콘, UI 틀 | 무손실, `compress/mode=0` | 손실 WebP는 색을 반 해상도로 저장해 픽셀 경계가 번진다 |

웹에서 내려받는 양의 예산은 45MB다. `tools/build_web.ps1`이 빌드 끝에 `Download: … (budget 45 MiB)`를 찍고, 넘으면 경고한다. 근거는 `reports/web-size-2026-11-24/`에 있다.

새 캐릭터의 전신 일러스트는 웹 빌드에 들어가야 한다. `export_presets.cfg`의 제외 목록이 캐릭터의 일러스트를 빼면 `test_import_modes`가 실패한다. 어느 화면도 그리지 않는 `luna/luna_brave_illustration.png`만 제외 목록에 있다(2026-11-25 기준 여유 0.1MiB). 이 그림을 쓰게 되면 제외 목록에서 빼고 용량을 다시 잰다.

## 스토리 대화 표정과 그림자 얼굴 (SYS-09)

사용자가 모션 뷰어에서 고른 후보를 아래 경로로 복사한 뒤 Godot에서 임포트한다.
SYS-09에서는 후보를 복사하거나 채택하지 않았다.

| 후보 | 채택할 제품 경로 |
|---|---|
| `art/bakeoff/<folder>/<stem>_face-happy-v1.png` | `assets/art/<folder>/<stem>_face_happy.png` |
| `art/bakeoff/<folder>/<stem>_face-angry-v1.png` | `assets/art/<folder>/<stem>_face_angry.png` |
| `art/bakeoff/<folder>/<stem>_face-hurt-v1.png` | `assets/art/<folder>/<stem>_face_hurt.png` |
| `art/bakeoff/<folder>/<stem>_face-shadow-v1.png` | `assets/art/<folder>/<stem>_face_shadow.png` |

후보 경로는 저장소 기준, 제품 경로는 `smash-nine-prototype/` 기준이다.
`<folder>/<stem>`은 `frey/frey`, `yuki/yuki`, `luna/luna`, `luna/luna_brave`,
`nova/nova_male`, `nova/nova_female`, `rio/rio_male`, `rio/rio_female`이다.
스토리의 Luna는 기본 폼이므로 `luna_brave`는 현재 대화에서 선택하지 않는다.
라이벌은 기존처럼 캐릭터 기본 체형을, 주인공과 자기 그림자는 선택한 체형을 사용한다.

`ArtSettings.character_portrait(id, body, expression)`은 채택된 표정이 없으면 기존
중립 얼굴 → 픽셀 초상화 → 시트의 첫 idle 칸 순서로 돌아간다. 남녀 얼굴이 있는 캐릭터는
현재 중립 얼굴과 같은 stem의 표정을 사용하므로 다른 체형의 표정을 빌려오지 않는다.
기존의 인자 두 개 호출은 그대로다.

대사 세 번째 필드에 `{"face": "happy"}` / `angry` / `hurt`를 넣으면 말하는 쪽에만
표정이 나타난다. 태그가 없거나 말하지 않는 쪽은 중립이며, 말하지 않는 인물의 어둡게
표시하는 효과는 유지된다. `cg`와 `face`는 같은 사전에 함께 넣을 수 있다.
기존 장면 그림 메타데이터를 읽는 테스트와의 호환을 위해 카탈로그 표정 태그에는
`"cg": ""`도 명시했다(장면 그림 없음).

그림자는 감정 태그 대신 항상 `shadow`를 찾는다. 그림자 파일이 있으면 원래 그림의 색을
그대로 사용하고, 없으면 기존 중립 얼굴에 보라색을 곱한다. 주인공이 말할 때는 어느 쪽도
동일한 비발화자 밝기 감소를 추가 적용한다.
