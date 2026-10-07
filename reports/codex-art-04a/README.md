# CODEX-ART-04A 결과 보고

## 완료

유닛 A 범위의 Asgard, Midgard, Niflheim, Alfheim 원본 렐름 아트 4세트를 모두 제작했다. 각 세트는 `bg_far.png`, `bg_mid.png`, `platform_main.png`, `platform_sub.png`, 제작 프롬프트·팔레트·캡 폭을 적은 `README.md`를 포함한다. Midgard에는 전경 은신 후보인 `bush.png`도 추가했다.

내장 `image_gen`으로 생성한 원본을 `smash-nine-prototype/tests/art_preview/realms_a/build_assets.gd`에서 Godot 4.7 `Image` API로 후처리했다. 배경은 640×360으로 축소해 팔레트를 제한한 뒤 2배 최근접 확대했고, 플랫폼은 좌우 캡과 반복 중앙을 잘라 3-슬라이스 스트립으로 만들었다.

## 측정된 사실

| 렐름 | 배경/중경 | 메인 스트립 | 메인 캡 | 보조 스트립 | 보조 캡 | 추가 |
|---|---:|---:|---:|---:|---:|---:|
| Asgard | 1280×720 | 232×52 | 52px | 160×32 | 32px | — |
| Midgard | 1280×720 | 220×46 | 46px | 160×32 | 32px | bush 160×72 |
| Niflheim | 1280×720 | 216×44 | 44px | 160×32 | 32px | — |
| Alfheim | 1280×720 | 220×46 | 46px | 160×32 | 32px | — |

- `bg_far.png` 4장은 RGBA8이며 알파가 모두 1인 불투명 이미지다.
- `bg_mid.png`, 플랫폼 스트립 8장, `bush.png`는 RGBA8이며 투명 픽셀과 불투명 픽셀을 모두 가진다.
- 미리보기 4장은 `RealmCatalog.gd`의 실제 플랫폼 중심점과 크기를 그대로 사용했다.
- Frey의 `assets/art/frey/frey_sheet.png` 첫 프레임을 2배 최근접 확대해 전투 스케일 표식으로 합성했다.
- 4개 미리보기와 2×2 컨택트 시트는 각각 1280×720이다.

## 시각적 확인

- [4개 렐름 컨택트 시트](contact_sheet.png)
- [Asgard 실제 배치 미리보기](asgard_preview.png)
- [Midgard 실제 배치·수풀 가림 미리보기](midgard_preview.png)
- [Niflheim 실제 배치 미리보기](niflheim_preview.png)
- [Alfheim 실제 배치 미리보기](alfheim_preview.png)

컨택트 시트에서 지배색은 Asgard 청람·금색, Midgard 갈색·호박색, Niflheim 청록·빙청색, Alfheim 남보라·은청색으로 분리되어 있다. Midgard 미리보기의 왼쪽 아래 캐릭터는 수풀이 앞에 합성되어 하반신 가림 범위를 보여준다.

## 리드 통합 메모

이 유닛은 제품 소스를 수정하지 않았다. 리드가 `RealmCatalog.gd`의 각 렐름 딕셔너리에 다음 아트 메타데이터를 추가해야 런타임 `RealmWorld`가 자동으로 배경과 NinePatch 플랫폼을 읽는다.

```gdscript
# Asgard
"art": {"dir": "res://assets/art/realm_asgard", "cap_main": 52, "cap_sub": 32},
# Midgard
"art": {"dir": "res://assets/art/realm_midgard", "cap_main": 46, "cap_sub": 32},
# Niflheim
"art": {"dir": "res://assets/art/realm_niflheim", "cap_main": 44, "cap_sub": 32},
# Alfheim
"art": {"dir": "res://assets/art/realm_alfheim", "cap_main": 46, "cap_sub": 32},
```

`bush.png`는 현재 자동 로딩 계약에 포함되지 않는다. Midgard 플랫폼 앞쪽에 별도 Sprite2D/TextureRect로 배치하고, 캐릭터보다 높은 z-index를 주어야 은신 표현이 된다. Niflheim 플랫폼은 기존 런타임의 빙판 광택과 강조선이 위에 그려지는 것을 전제로 명도를 억제했다.

## 사람이 판단할 부분

다음은 자동 검증 사실이 아니라 미감·플레이 경험 판단이다.

- Asgard 상단의 밝은 구름과 금빛 건축이 실제 8인 전투에서 시선을 과하게 끄는지
- Midgard 배경의 건물 밀도가 상단 플랫폼 캐릭터를 방해하지 않는지
- Niflheim과 Alfheim이 실제 게임 전환 중에도 청록 얼음 / 남보라 달빛으로 충분히 즉시 구분되는지
- Midgard 수풀의 폭 160px와 높이 72px가 은신 기믹에 적절한지, 또는 상대 캐릭터 정보를 지나치게 가리는지
- 3-슬라이스 중앙 반복 무늬가 가장 긴 플랫폼에서 눈에 띄는지

## 확인 및 테스트

`build_assets.gd`를 Godot 4.7 headless로 실행해 `ART04A_BUILD_OK realms=4`를 확인했다. `verify_assets.gd`로 파일 존재, 정확한 크기, RGBA8 형식, far 배경의 불투명성, 투명 자산의 알파 존재를 검사해 `ART04A_VERIFY_OK realms=4 previews=4 contact_sheet=1`을 확인했다. 프로세스 종료 코드는 1이었지만 출력된 `ERROR`는 카드에 알려진 샌드박스 인증서 저장소 1건뿐이었고, 그 밖의 스크립트·파싱·이미지 오류는 없었다.

## 남은 작업

- 제품 코드 통합과 실제 매치 창에서의 동적 가독성 검증은 리드 범위라 수행하지 않았다.
- Midgard 수풀의 실제 충돌/은신 규칙은 구현하지 않았다.
- `.git`은 이 샌드박스에서 쓰기 허용 경로가 아니므로 직접 커밋하지 않고 `commit.ps1`을 준비했다.
