# 모션 뷰어

캐릭터 6명(Frey, Luna, Brave Luna, Nova 남·여, Rio 남·여, Yuki)과 몬스터 18종의 모든 동작을 게임 시트 그대로 재생하는 페이지.

- 주소: https://claude.ai/artifact/188Ryqb526Ue58MDf4BnbU (소유자 전용 Artifact)
- 기능: 캐릭터·체형 고르기, 기본 동작과 기술 동작 전체를 한 번에 재생, 큰 화면에서 재생·멈춤·프레임 넘기기(`Space`, `←` `→`, `↑` `↓`), 줄별 속도 0.5~1.5배 미리보기와 변경값 복사, 배율 1~4배, 배경(체크·어둡게·밝게), 가이드(발 기준선 y=120, 칸 테두리, 여백 4px), 프레임 띠, 시트 파일·줄 번호·fps·길이. 후보가 있는 줄은 현재 그림과 모든 후보를 같은 프레임 번호·배율·가이드로 나란히 재생한다. 캐릭터의 **게임 화면**에는 실제 기본 공격 클립과 이펙트 켬/끔 전환이 있다.
- 줄 정의는 게임 코드에서 읽는다: `PlayerBase.ORIGINAL_SHEET_ROWS`, 각 캐릭터의 `MOVE_SHEET_ROWS`(Brave는 `BRAVE_MOVE_SHEET_ROWS`), `RealmMonster.ART_ROWS`. 기술 이름표는 `*_moves_README.md` 표의 Move 열.

## 그림이 바뀌었을 때

1. 저장소 루트에서 `node tools/motion_viewer/build.mjs` → `tools/motion_viewer/dist/`(index.html + sheets/, git에 안 올림)
2. 같은 Artifact에 다시 게시: `dist/index.html`을 위 주소로 publish, `root`는 `dist`, `files`는 `dist/files.json`의 목록. 주소는 그대로 유지된다.
3. 로컬로 볼 때: `node tools/serve_web.js tools/motion_viewer/dist 8073`.

새 캐릭터는 `build.mjs`의 `CHARACTERS` 목록에 한 줄을 더한다.

## 실제 게임 클립 갱신

기술 수치·동작 시트·공격 이펙트가 바뀌면 저장소 루트가 아니라 `smash-nine-prototype/`에서 아래를 실행한다. 캡처는 창을 열며 한 번에 하나만 실행한다. 첫 명령은 새 클론에서 한 번이면 된다.

```powershell
$env:PYTHONDONTWRITEBYTECODE = '1'
$godot = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
& $godot --headless --path . --import
& $godot --path . --fixed-fps 60 -s tests/capture_move_clips.gd
```

`capture_move_clips.gd`는 30fps·960×540 이펙트 켬/끔 클립을 만든다. TOOL-02부터는 이미 승인된 기본 공격 36쌍을 다시 인코딩하지 않고 그대로 보존하며, 캐릭터 주위 이펙트 19쌍(전 폼 Guard 6개 + 추격/스파이크/궁극기/오라/궤도/봉인/룬/상태 장면 13개)만 갱신한다. 마지막에 Pillow가 손실 없는 애니메이션 WebP 38개를 만들고 기존 `art/clips/manifest.json`에 `group: around`로 병합한다. 이어서 저장소 루트에서 `node tools/motion_viewer/build.mjs`를 다시 실행한다.

뷰어의 **게임 화면**은 `기본 공격`과 `캐릭터 주위 이펙트`로 나뉜다. 두 묶음 모두 `끔 / 지금 / 새 후보` 모드를 함께 바꾸며, 각 주위 이펙트 설명에는 캡처 때 쓴 카메라 배율도 표시된다.

**이펙트 후보 비교(`art/clips-new`):** 뷰어의 이펙트 보기는 `끔 / 지금 / 새 후보` 세 가지다. 새 후보 클립은 이렇게 만든다.
1. `art/bakeoff/effects/<id>/*-vN.png`를 각 JSON의 `replaces` 경로에 잠시 덮어쓴다.
2. `--headless --import` 뒤 위 캡처를 돌리고, 결과 `art/clips`를 `art/clips-new`로 옮긴다. 지금 클립은 미리 복사해 두었다가 되돌린다.
3. 덮어쓴 이펙트는 `git checkout -- smash-nine-prototype/assets/art`로 되돌리고 다시 import한다.

`build.mjs`는 `art/clips-new/manifest.json`이 있으면 같은 form/move의 fx 클립을 새 후보로 붙인다. 후보를 채택해 게임에 넣으면 `art/clips`를 다시 캡처하고 `art/clips-new`는 지운다.

## 동작 겨루기 후보

후보는 Godot 프로젝트 밖에 둔다.

```text
art/bakeoff/<캐릭터 id>/<시트 stem>-<행 이름>-v<번호>.png
art/bakeoff/<캐릭터 id>/<시트 stem>-<행 이름>-v<번호>.json  # 선택
```

예: `art/bakeoff/luna/luna-walk-v1.png`. PNG는 파이프라인이 만든 128px 셀 6열 가로 스트립이다. JSON은 `{"note":"설명", "fps":10, "frames":6, "cell":192, "feet":152}` 형식이다(`cell`·`feet`는 칸이 128이 아닐 때만, D34). `frames`·`fps`가 게임 행과 다르면(예: 4프레임 행의 6프레임 후보) 후보는 자기 값으로 재생되고, 프레임 띠와 넘기기는 프레임이 가장 많은 쪽을 따른다. 칸 크기가 다른 후보(128 기본 행 옆의 192 기술 후보)는 같은 화면 배율로 그리고, 발 기준선이 같은 높이에 오도록 맞춘다. 게임 줄 표에 아직 없는 줄의 후보(예: Yuki `tumble`)는 기술 동작 끝에 "새 줄 — 게임에 아직 없음"으로 나오고, 지금 게임 칸 없이 후보만 재생된다. 게임에 들어간 후보는 JSON에 `"adopted": "날짜"`를 달아 두면 파일은 그 자리에 남고(기준 대기 동작 경로 유지) 뷰어 후보 목록에서는 빠진다. 물러난 후보는 `art/bakeoff/<id>/retired/`로 옮기면 저장소에는 남고 뷰어에서는 빠진다. `stem`은 실제 시트 이름에서 `_sheet.png` 또는 `_moves_sheet.png`를 뺀 값(`frey`, `nova_male`, `luna_brave` 등), 행 이름은 게임 코드의 `idle`, `walk`, `spike_followup` 등과 정확히 같아야 한다.

`build.mjs`는 후보를 해당 행 manifest에 붙이고 `dist/bakeoff/`로 복사한다. 후보가 있는 타일에는 `후보 N` 배지가 보이며, 선택하면 현재 행과 후보들이 동기 재생된다. 좁은 화면에서는 비교 패널이 가로 스크롤된다.

## 동작 속도 채택 기록 (사용자 2026-10-15)
"모션 별 시간은 모션 뷰어에서 직접 조절 후 채택 버튼을 눌러 기록하여 데이터를 남기는 식으로 할테니 수정할것. 그 데이터를 보고 이후 조절하면 된다."

- 무대의 **선택 줄 속도**(×0.5–×1.5)를 맞춘 뒤 **채택**을 누르면, Artifact 데이터베이스(`db` 기능)의 `motion_speeds` 컬렉션에 그 줄의 문서가 저장된다.
  - 문서 id: `<캐릭터>~<체형|default>~<base|moves>~<줄>`
  - 필드: `character`, `body`, `sheet`, `row`, `frames`, `table_fps`, `factor`, `fps`, `adopted_at`, `viewer_commit`
  - 다시 채택하면 덮어쓰고, **기록 지움**은 문서를 지운다. 채택된 줄의 타일에는 `채택 ×0.80` 표시가 붙는다.
- 리드가 반영할 때 (D39, 2026-10-15 첫 반영 91줄):
  1. `ArtifactData`의 `list`(collection `motion_speeds`)로 내려받는다. 문서 하나가 파일 하나로 받아진다.
  2. `python tools/motion_viewer/apply_speeds.py <받은 폴더>`를 돌린다. 기록 사본 `art/motion_speeds.json`과 게임용 `smash-nine-prototype/characters/common/MotionSpeeds.gd`를 쓰고, 바뀐 줄을 출력한다.
  3. 게임은 시트를 자를 때 줄마다 그 fps로 재생한다. 체형(남/여)과 형태(Luna/Brave Luna)마다 따로다.
     - 기술 줄은 D38 그림 시계로 재생된다. 타격 그림은 판정 순간에 오고, 그 뒤 그림만 채택 속도보다 빨리 넘어가지 않는다.
     - 줄 재생이 곧 기술 시간인 것(Luna 변신)은 시간도 줄을 따라간다.
  4. 테스트(`test_motion_speeds` 포함), 웹 빌드, 클립 다시 찍기, 뷰어 다시 게시를 한다.
- 뷰어의 줄 fps는 **게임 속도**(반영된 채택값)다. 그린 속도가 다르면 `그린 속도 13.3`처럼 옆에 나온다.
  - 채택 기록의 fps가 게임 속도와 같으면 `반영 ×0.85`(그린 속도 대비)로 표시된다. 다르면 `채택 ×… · 반영 전`이다.
  - 반영된 줄에 남아 있던 내 슬라이더(채택한 배율과 같은 값)는 ×1로 돌아간다. 두 번 곱해지지 않게 하려는 것이다.
  - 다시 채택하면 `table_fps`는 그때의 게임 속도, `drawn_fps`는 그린 속도로 기록된다. 반영에는 `fps`(절대값)만 쓴다.
- 다시 게시할 때는 `capabilities`를 생략해 `db` 선언을 유지한다. 로컬 미리보기에는 데이터베이스가 없어 채택 버튼이 숨는다.

## 후보 고르기 · TOOL-03

캐릭터·몬스터 동작의 비교 무대, **몬스터 투사체**, **대화 초상화**의 모든 미채택 후보에는 **고르기 / 고름 ✓ · 취소**와 300자 이내 메모가 있다. 메모를 먼저 쓰고 고르면 함께 저장하며, 이미 고른 후보의 메모만 바꿀 때는 **메모 저장**을 누른다. 입력 중에는 쓰지 않고 버튼 한 번에 문서 하나만 쓴다. 후보별 선택은 독립적이므로 같은 동작의 여러 버전을 함께 고를 수 있다.

- 맨 위 **고른 것**은 종류·폼 이름·동작/표정·버전·저장된 메모를 모아 보여준다. 여기서도 취소할 수 있다. 재접속하면 DB 구독으로 복원한다.
- JSON에 `adopted`가 있는 후보와 `retired/` 안의 후보는 미리보기에 나오지 않는다. 이전 게시에서 고른 기록은 목록에 남으며 `현재 후보 목록에 없음` 표시와 취소 버튼을 제공한다.
- DB 없이도 기존 동작·클립·새 이미지 비교가 가능하다. 후보 고르기·메모 컨트롤은 비활성화되고 한국어 안내가 나온다. 속도 채택은 기존처럼 DB가 없으면 숨는다.
- 저장은 후보 선택 기록이다. 게임 파일 적용과 속도 채택(`motion_speeds`)은 각각 별도다. 이 도구는 게임 그림이나 GDScript를 쓰지 않는다.

### 저장 형식과 리드가 읽는 방법

기존 Artifact의 `window.claude.use("db")`를 한 번 호출하고, **`candidate_picks` 컬렉션 전체를 한 번 구독**한다. 기존 `motion_speeds` 구독도 유지한다.

문서 id는 `<kind>~<id>~<row>~<version>`이다. `kind`는 `fighter`, `monster`, `projectile`, `face`; `id`는 시트 stem(예: `nova_male`, `nova_female`, `luna_brave`, `mossling`)이다. 표정의 `row`는 `happy` / `angry` / `hurt`, 투사체는 `projectile`, 공용 충격파는 `shockwave`다. `version`은 `v1` 등의 문자열이다.

```json
{
  "kind": "monster",
  "id": "mossling",
  "row": "idle",
  "version": "v1",
  "file": "art/bakeoff/monsters/mossling-idle-v1.png",
  "picked": true,
  "note": "형식 예시이며 실제 선택 기록이 아님",
  "picked_at": "2026-10-23T03:00:00.000Z"
}
```

리드는 같은 모션 Artifact에서 **`ArtifactData list candidate_picks`**를 사용한다. `picked === true`만 현재 선택으로 읽고, `file`의 실제 후보 및 JSON을 확인한 뒤 별도로 게임에 반영한다. 취소는 문서를 삭제하지 않고 `picked: false`로 덮어쓴다. 메모 저장·취소에도 `picked_at`은 마지막 저장 시각(ISO UTC)으로 갱신된다. 조회 결과만으로 반영 완료로 간주하지 않는다.

### 투사체와 초상화

- `art/bakeoff/monsters/<id>-projectile-vN.png`와 `slam_shockwave-vN.png`를 자동 수집한다. JSON의 `frames`·`fps`·`cell`·`loop`를 사용하고, `cell`은 숫자 또는 `[가로, 세로]`다. 기존 단일 PNG와 후보를 각각 원본 크기 1×·3×로 비교한다. 충격파의 기존 표현은 PNG가 없는 Line2D이므로 게임 코드 좌표를 캔버스로 재현하고 명시한다. **원본 픽셀 배율이며 실제 게임 표시 배율을 모사한 것은 아니다.**
- `art/bakeoff/<폴더>/<stem>_face-{happy,angry,hurt}-vN.png`를 자동 수집한다. 8개 폼별 현재 무표정과 후보를 142×164 영역에 `object-fit: contain`으로 나란히 배치한다. 클릭하면 원본 크기 대화상자, 닫기 또는 Esc로 돌아온다.
- 새 번호의 동작·투사체·표정 파일은 다음 빌드에 포함된다. 후보 JSON과 이미지가 잘못됐거나 게시 목록 파일이 없으면 빌드가 실패한다. 동작 JSON은 기존처럼 생략할 수 있다. 투사체에는 프레임·fps·셀 메타데이터가 필요하다.

### 빌드·검증·재게시

```powershell
node tools/motion_viewer/build.mjs
node tools/motion_viewer/verify.mjs
```

`verify.mjs`는 패키지 없이 Node 표준 라이브러리의 모의 DOM·Image·캔버스·DB로 실행한다. 결과는 **`reports/codex-tool-03/viewer-checks.json`**에 쓴다. 기존 AUD 보고서는 덮어쓰지 않는다. `reports/codex-tool-03/baseline.json`은 변경 전 빌드 데이터로, 기존 행·후보·속도·클립 보존 비교에 사용한다. 게임의 행 정의나 클립이 의도적으로 바뀌면 이 기준 데이터도 해당 변경에 맞춰 검토해야 한다. 추가 후보 개수는 고정하지 않는다.

같은 Artifact https://claude.ai/artifact/188Ryqb526Ue58MDf4BnbU 에 **`root=tools/motion_viewer/dist`, HTML=`dist/index.html`, files=`dist/files.json`**으로 재게시한다. **`capabilities`는 생략**해 기존 `db`, `motion_speeds`, 새 `candidate_picks` 기록을 유지한다. 소리 Artifact와 구분한다.

`files.json`은 HTML을 제외한 모든 sidecar 목록이다. 시트 → 후보 → 현재 비교 그림 → 클립 순이다. 250개 또는 HTML 포함 60,000,000바이트를 초과하면 **`files-1.json`, `files-2.json`, …**도 생성한다. 각 목록은 250개 이하이며 동일 HTML의 용량까지 포함해 60MB 이하로 나눈다. 리드는 번호순으로 **같은 버전**에 나눠 올려야 한다. 새 버전마다 기존 파일을 유지/합치는 게시 도구 동작은 실제 게시 때 확인한다. 카드의 한 요청 255파일/64MB, 한 버전 511파일/256MB 기준으로 전체 버전 적합 여부도 빌드가 출력한다. 전체 버전 한도를 넘으면 배치 분할만으로 해결되지 않는다.

이번 클론 검증은 Node 모의 동작과 파일 바이트 비교다. 실제 브라우저 열기는 자동 승인 검토가 localhost 접근 권한을 거부해 수행하지 못했다. 게시 후 리드가 화면 배치·이미지 재생·실제 DB 저장 및 새로고침 복원을 확인해야 한다.

