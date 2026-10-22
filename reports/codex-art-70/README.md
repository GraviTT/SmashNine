# ART-70 스토리 연출 이미지 인계

상태: 파일 제작·픽셀 규격 검수 완료. 게임 연결과 Godot import는 미실행. 2026-10-22, codex/art-70.

## 완료 / 현재 상태 / 남은 작업

- 완료: 장면3종(3/3/2안), 프레임·이름판·오라(각2안), 총14개 image_gen 원본. 선택한6개와 원본6개를 assets/art/story/에 배치했다. 미선택8개는 variants/에 원본과 가공본을 보존했다.
- 현재 상태: 실제 이미지 픽셀 검사84/84 통과. 생성 도구에 참조 파일을 실제 전달했고, 에필로그의 첫 참조는 선택한 프롤로그다. 패키지 설치·다운로드·제품 코드 변경 없음.
- 남은 작업: 리드의 게임 연결, Godot import, 실제 대화 화면과 그림자 캐릭터 뒤에서 시각 판단. 실행 중인 다른 Godot 프로세스를 발견하여 이번 유닛은 엔진을 시작하지 않았다(godot-import.log).

## 선택본

| 파일 (assets/art/story/) | 선택 | 규격 | 이유 |
|---|---:|---|---|
| [cg_prologue.png](../../smash-nine-prototype/assets/art/story/cg_prologue.png) | 1안 | 1600×900 RGB | 1안: 심장 균열·수평 충격파와 왼쪽 두 섬의 실제 충돌이 가장 빠르게 읽힌다. |
| [cg_root.png](../../smash-nine-prototype/assets/art/story/cg_root.png) | 3안 | 1600×900 RGB | 3안: 얼음 뿌리의 S자 하강, 크게 끊어진 봉인 고리와 바깥으로 흩어지는 부적이 명확하다. 하단도 가장 어둡다. |
| [cg_epilogue.png](../../smash-nine-prototype/assets/art/story/cg_epilogue.png) | 1안 | 1600×900 RGB | 1안: 온전한 밝은 심장, 수평으로 안정된 섬, 끊기지 않은 폭포와 따뜻한 새벽으로 전후 대비가 명확하다. |
| [dialogue_frame.png](../../smash-nine-prototype/assets/art/story/dialogue_frame.png) | 1안 | 480×120 RGBA / 9-slice 24px | 1안: 기존 result_panel의 날개·금색 장식과 작은 푸른 마름모가 가장 잘 이어진다. |
| [name_plate.png](../../smash-nine-prototype/assets/art/story/name_plate.png) | 1안 | 192×36 RGBA / 9-slice 12px | 1안: 대화 틀의 마름모 보석과 맞고, 이름을 넣는 중앙이 완전히 평평하다. |
| [shadow_aura.png](../../smash-nine-prototype/assets/art/story/shadow_aura.png) | 2안 | 768×176 RGBA / 128×176 ×6, 10fps | 2안: 넓은 연무가 그림자임을 구분하며 중앙은 얇다. 6→1 변화량이 일반 전환과 비슷해 1안의 유사 중복 프레임에 의한 머뭇거림을 피한다. |

## 규격 PASS/FAIL — 모든 변형

PASS는 최종 가공본 기준이며, 시각 항목은 육안 판정이다. FAIL인 미선택안도 삭제하지 않았다. 수치와 원본 문제는 아래에서 구분한다.

### cg_prologue

| 카드 규격 줄 / 세부 내용 | 1안 선택 | 2안 | 3안 |
|---|---|---|---|
| Size:1600×900 불투명, raw 보존, 확대 금지 | PASS | PASS | PASS |
| Style:참조1·2의 픽셀 군집·남색/보라/마젠타/금색 | PASS | PASS | PASS |
| Must show:중앙 세계수와 심장 모양 코어 | PASS | PASS | PASS |
| Must show:흰분홍 균열·섬광·고리 충격파·빛 파편 | PASS | PASS | PASS |
| Must show:8종 렐름 섬의 기울어짐·표류 | PASS | PASS | PASS |
| Must show:두 섬 충돌·파편·끊긴 폭포 | PASS:성/마을 | PASS:얼음성/뿔유적 | PASS:태엽/뿔유적 |
| Must show:은하와 적보라 빛 하늘 | PASS | PASS | PASS |
| Bottom quarter:어두운 구름/바위, 핵심 사건은 위쪽 | PASS | PASS | PASS |
| Avoid:인물/생물/글자/로고/UI/틀/워터마크/사진 | PASS | PASS | PASS |
| Text:none | PASS | PASS | PASS |

### cg_root

| 카드 규격 줄 / 세부 내용 | 1안 | 2안 | 3안 선택 |
|---|---|---|---|
| Size:1600×900 불투명, raw 보존, 확대 금지 | PASS | PASS | PASS |
| Style:참조1·3, 청록/시안/오로라/마젠타 픽셀 아트 | PASS | PASS | PASS |
| Must show:빙하 동굴·거대한 서리 뿌리·고드름·심연으로 나선 하강 | PASS | PASS | PASS |
| Must show:원형 봉인 고리·종이 부적·추상 빨간 소용돌이 | PASS | PASS | PASS |
| Must show:고리 파열과 바깥으로 흐르는 부적 | PASS | PASS:파열이 약함 | PASS:큰 단절 |
| Must show:아래 심장빛이 뿌리를 타고 오름·위쪽 오로라 | PASS | PASS | PASS |
| Bottom quarter:어두운 얼음/그림자, 적은 디테일 | FAIL:밝은 하부 뿌리가 걸침 | PASS | PASS |
| Avoid:인물/생물/글자/한자/읽을 수 있는 기호/로고/UI/틀 | PASS | PASS | PASS |
| Text:none (부적은 단순 소용돌이) | PASS | PASS | PASS |

### cg_epilogue

| 카드 규격 줄 / 세부 내용 | 1안 선택 | 2안 |
|---|---|---|
| Size:1600×900 불투명, raw 보존, 확대 금지 | PASS | PASS |
| Style:선택 prologue 첫 참조 + 참조1·2 | PASS | PASS |
| Style:나무의 중앙 위치/크기로 전후 장면 연결 | PASS:시각 정합 | PASS:시각 정합 |
| Must show:온전한 심장·부드러운 분홍금색·상승하는 빛 입자 | PASS | PASS |
| Must show:안정된 섬 배치·흐르는 폭포·평화로움 | PASS | FAIL:섬의 기울어짐이 붕괴 장면처럼 남음 |
| Must show:남색 상단→연보라/연금색 새벽 지평선 | PASS | PASS |
| Bottom quarter:주요 물체 없는 부드러운 구름 | PASS | PASS |
| Avoid:균열/충격파/불/인물/글자/로고/UI/틀 | PASS | FAIL:심장 내부 선이 균열처럼 읽힐 여지 |
| Text:none | PASS | PASS |

나무 정합은 별도 생성된 전후 그림의 육안 비교다. 동일 픽셀 마스크나 완전히 고정된 형태를 뜻하지 않는다. 1안의 심장 위치·수관 크기·중앙 섬이 프롤로그와 충분히 비슷한지는 사람이 최종 선택해야 한다.

### dialogue_frame

| 카드 규격 줄 | 1안 선택 | 2안 |
|---|---|---|
| Size:480×120 RGBA,9-slice24px | PASS | PASS |
| Style:금/짙은금/파란보석/남색 외곽,1x 픽셀 | PASS | PASS |
| Must show:금색 장식+작은 파란보석이24×24 코너 안 | PASS | PASS |
| Must show:외금/내청 이중 직선,변 중간 장식 없음 | PASS | PASS |
| Centre:완전 투명 | PASS:alpha0 | PASS:alpha0 |
| Avoid:문자/캐릭터/중앙채움/외부그림자/흐림 | PASS | PASS |
| 투명 코너·실제alpha·체커보드/흰 halo 없음 | PASS | PASS |
| 가로/세로 stretch 구간 픽셀 동일 | PASS | PASS |

### name_plate

| 카드 규격 줄 | 1안 선택 | 2안 |
|---|---|---|
| Size:192×36 RGBA,9-slice12px | PASS | PASS |
| Style:대화 틀과 같은 금색/보석/남색 | PASS | PASS |
| Must show:남색 alpha약235·2px 금테 | PASS:alpha235 | PASS:alpha235 |
| Must show:양끝12px 안에 작은 파란보석 | PASS | PASS |
| Avoid:글자·늘어나는 중앙의 장식 | PASS | PASS |
| 투명 코너·실제alpha·체커보드/흰 halo 없음 | PASS | PASS |

초기 마감 r1의 이름판1안은 받침1px이 중앙 구역에 들어가 FAIL이었다. r2에서 x3~11 / x180~188로 줄였고 중앙 전체는 정확히 RGBA(16,24,39,235) 한 색이다. 생성된 원본과 r1은 보존했다.

### shadow_aura

| 카드 규격 줄 | 1안 | 2안 선택 |
|---|---|---|
| Size:768×176,6칸×128×176,RGBA,10fps loop | PASS | PASS |
| Placement:중심x64/발y160 | PASS | PASS |
| Style:참조5의 픽셀 효과,지정 보라5색 | PASS | PASS |
| Must show:양옆/머리 위 진한 상승 연무·얇은 가운데·작은 마젠타 불씨 | PASS:날카로운 불꽃 | PASS:둥근 연무 |
| Avoid:인물/실루엣/글자·4px여백·흰halo·잘린사각형 | PASS | PASS |
| 각 프레임 최소4px 투명 여백 | PASS | PASS |
| Loop:6→1 흐름 | FAIL:거의 같은 포즈가 연속해 hold 우려 | PASS:전환 변화량에 고립된 spike 없음 |

## 측정값과 가공 기록

- 장면8종: raw1672×941 → crop(4,2,1668,938)=1664×936 → LANCZOS1600×900. 모두 RGB 불투명. 패딩·확대 없음.
- 프레임 raw1983×793(두 안). 1안 코너crop(12,14,188,190),2안(24,80,184,240) → NEAREST22×22. 팔레트7색·alpha0/255. 정확한480×120 캔버스의 직선만 Pillow로 재작성. 생성 장식 유지.
- 이름판 raw2048×768(두 안). 1안 보석crop(72,350,139,417),2안(63,344,139,420) → NEAREST7×7. 정확한192×36 판/금테/받침은 Pillow로 그림. alpha는0/235/255. 원본의 금빛 외부 번짐을 쓰지 않음.
- 오라1 raw2032×774,2 raw2126×740. alpha<64 미세 잡점 제거 → 각 칸 crop → 공통 배율로 NEAREST 축소 → 발 기준y160/중앙x64 배치. 원래 alpha를32단계로 정리하고 지정5색에 매핑했다. 확대 없음.
- 각 칸의 source crop,scale,paste와 처리 설명: [processing-v2.json](processing-v2.json). 원본 경로/참조 순서/실제14프롬프트: [generation_manifest.json](generation_manifest.json), [PROMPTS.md](PROMPTS.md).

| 오라 측정 | 1안 | 2안 선택 |
|---|---:|---:|
| 모든 칸의 최소 L/T/R/B 빈 여백 |21/10/21/16px|16/10/16/16px|
| 6→1 premultiplied RGBA MAE(0~255) |1.1592|13.2700|
| 1→2..5→6 중앙값 대비 seam 비율 |0.0951|0.9643|
| 흰 halo 픽셀(가시alpha,RGB최솟값>210) |0|0|

seam 수치는 실제 PNG의 alpha를 곱한 RGB와 alpha 4채널 평균 절대차다. 2안은 일반 전환과 비슷한 차이지만, 이 수치만으로 좋은 움직임을 증명하지는 않는다. verify.py의1.25배 기준은 고립된 점프 탐지 보조 지표이며 카드에 없는 미적 기준을 대체하지 않는다.

## 비교 시트·GIF

| 자산 | 비교 시트 | 구성 |
|---|---|---|
| cg_prologue | [cg_prologue_contact-v2.png](cg_prologue_contact-v2.png) | 모든 안1600×900 1:1 +1280×720/하단25%가림 |
| cg_root | [cg_root_contact-v2.png](cg_root_contact-v2.png) | 모든 안1600×900 1:1 +1280×720/하단25%가림 |
| cg_epilogue | [cg_epilogue_contact-v2.png](cg_epilogue_contact-v2.png) | 모든 안1600×900 1:1 +1280×720/하단25%가림 |
| dialogue_frame | [dialogue_frame_contact-v2.png](dialogue_frame_contact-v2.png) | 최종 규격1x+slice선+실표시 크기/예문+명암배경 |
| name_plate | [name_plate_contact-v2.png](name_plate_contact-v2.png) | 최종 규격1x+slice선+실표시 크기/예문+명암배경 |
| shadow_aura | [shadow_aura_contact-v2.png](shadow_aura_contact-v2.png) | 모든 안768×176 1:1+42×96 회색 몸 상자/발선 |

- [오라1 10fps GIF](shadow_aura-v1-v2.gif) / [오라2 선택 10fps GIF](shadow_aura-v2-v2.gif). 두 GIF 모두0.6초 루프,6프레임,프레임당100ms다.
- [선택본 전체 보기](selected_overview.png). Pillow로 합성한 검토용 이미지이며 실제 게임 스크린샷이 아니다.
- 시트의 체커보드·slice선·예문·회색 상자는 검토용 배경에만 있다. 실제 PNG에 들어가지 않는다.

## 원본 문제와 마감 경계

- 생성 원본의 투명 alpha는 실제 존재했다. 프레임/오라 외곽의 저alpha 잡점과 이름판 금빛 번짐은 원본에서는 FAIL. 지정 크기·9-slice 경계도 원본에서는 맞지 않았다.
- UI는 카드가 허용한 Pillow 마감을 사용했다. 코너/보석은 image_gen 원본에서 추출하고, 직선/판 모양은 정확한 픽셀 캔버스에 그렸다.
- 오라는 그림을 새 도형으로 대체하지 않고 생성된6프레임을 분리·축소·배치·팔레트/alpha 정리했다. 원본은 보존했다.
- 인물/문자/가짜 글자·사진같은 표현의 부재, 픽셀 아트의 자연스러움은 육안 검사다. OCR/자동 인식으로 완전한 부재를 증명하지 않았다. 실제 캐릭터 위의 오라와 Godot9-slice는 실행 검증하지 못했다.

## 재현과 확인

Python은 설치된 C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe를 사용했다. Pillow/numpy 추가 설치 없음. 아래 스크립트는 카드 허용 경로만 쓴다.

1. tests/art_preview/story_70/build.py --revision v2: 보존 원본에서 후보 재구축. 기존 PNG와 다르면 덮어쓰지 않고 중단.
2. tests/art_preview/story_70/check_and_contact.py --revision v2: 실제 이미지 측정·비교 시트·GIF.
3. tests/art_preview/story_70/verify.py: 전달 PNG들의 크기·alpha·slice·여백·6개 고유프레임·중앙 가독성 검사.
4. 결과: [verification.json](verification.json), 84/84 PASS. 제품/전투 테스트 결과가 아니다.
5. Godot: [godot-import.log](godot-import.log), 타 유닛의 프로세스가 있어 SKIPPED. 최소 import 프로젝트만 tests/art_preview/story_70/import_check/에 준비했다.

## 사람이 최종 판단할 것 / 다음 권장 단계

- 프롤로그: 충돌하는 섬 두 개와 심장 파열이 작은1280×720 화면에서도 즉시 읽히는지.
- 뿌리: 단순 빨간 소용돌이가 문자처럼 보이지 않는지, 끊어진 봉인이 열리는 장면으로 읽히는지.
- 에필로그: 프롤로그의 같은 나무로 이어지고, 밝기/수관 크기의 작은 변화가 자연스러운지.
- UI:1160×170과220×40에서 장식 크기와2px선 두께가 게임 HUD와 맞는지.
- 오라:10fps 재생에서 연무가 위로 흐르는지,0.6초 루프가 급하지 않은지, 실제90~100px 캐릭터의 손/무기와 겹치지 않는지.
- 다음 권장 단계: 리드가 SYS-03 이후 연결하고 Godot import 및 실제 대화/그림자 화면을 확인한다. 자동 후속 실행을 예약하지 않았다.

정확한 최종 프롬프트6개와 전체 변형14개의 프롬프트는 [PROMPTS.md](PROMPTS.md)에 전문을 보존했다.

## 최종 재현 확인

보존한 작업 경로의 raw만 사용해 14개 가공본을 다시 만들었고 전달된 PNG와 SHA-256이 14/14 일치했다([reproduction.json](reproduction.json)). Python 구문, README 링크, commit.ps1 구문도 검사했다. commit.ps1은 실행하지 않았다. 전달 준비 시각: 2026-10-22 17:25 KST(마감 18:04 이전).

## 커밋 인계

이 환경의 .git은 읽기 전용이므로 직접 커밋하지 않았다. [commit.ps1](commit.ps1)은 codex/art-70 브랜치와 기존 staging을 검사하고, 카드의 허용 경로 3개만 stage한 뒤 [commit-message.txt](commit-message.txt)로 커밋한다. 메시지는 Co-Authored-By: Codex <noreply@openai.com>으로 끝난다. push/merge는 하지 않는다.