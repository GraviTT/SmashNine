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

## 실제 기본 공격 클립 갱신

기술 수치·동작 시트·공격 이펙트가 바뀌면 저장소 루트가 아니라 `smash-nine-prototype/`에서 아래를 실행한다. 캡처는 창을 열며 한 번에 하나만 실행한다. 첫 명령은 새 클론에서 한 번이면 된다.

```powershell
$env:PYTHONDONTWRITEBYTECODE = '1'
$godot = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
& $godot --headless --path . --import
& $godot --path . --fixed-fps 60 -s tests/capture_move_clips.gd
```

`capture_move_clips.gd`는 Frey, Luna, Brave Luna, Yuki, Nova 남성, Rio 남성의 지상 J(연계 전 타), 지상 ↑J/↓J, 공중 J/↑J/↓J를 30fps·960×540으로 각각 이펙트 켬/끔 캡처한다. 마지막에 Pillow로 손실 없는 애니메이션 WebP 72개와 `art/clips/manifest.json`을 만든다. 이어서 저장소 루트에서 `node tools/motion_viewer/build.mjs`를 다시 실행한다.

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
