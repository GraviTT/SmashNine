# 모션 뷰어

캐릭터 6명(Frey, Luna, Brave Luna, Nova 남·여, Rio 남·여, Yuki)과 몬스터 18종의 모든 동작을 게임 시트 그대로 재생하는 페이지.

- 주소: https://claude.ai/artifact/188Ryqb526Ue58MDf4BnbU (소유자 전용 Artifact)
- 기능: 캐릭터·체형 고르기, 기본 동작과 기술 동작 전체를 한 번에 재생, 큰 화면에서 재생·멈춤·프레임 넘기기(`Space`, `←` `→`, `↑` `↓`), 속도 0.25~2배, 배율 1~4배, 배경(체크·어둡게·밝게), 가이드(발 기준선 y=120, 칸 테두리, 여백 4px), 프레임 띠, 시트 파일·줄 번호·fps·길이. 후보가 있는 줄은 현재 그림과 모든 후보를 같은 프레임 번호·배율·가이드로 나란히 재생한다.
- 줄 정의는 게임 코드에서 읽는다: `PlayerBase.ORIGINAL_SHEET_ROWS`, 각 캐릭터의 `MOVE_SHEET_ROWS`(Brave는 `BRAVE_MOVE_SHEET_ROWS`), `RealmMonster.ART_ROWS`. 기술 이름표는 `*_moves_README.md` 표의 Move 열.

## 그림이 바뀌었을 때

1. 저장소 루트에서 `node tools/motion_viewer/build.mjs` → `tools/motion_viewer/dist/`(index.html + sheets/, git에 안 올림)
2. 같은 Artifact에 다시 게시: `dist/index.html`을 위 주소로 publish, `root`는 `dist`, `files`는 `dist/files.json`의 목록. 주소는 그대로 유지된다.
3. 로컬로 볼 때: `.claude/launch.json`의 `motion-viewer`(포트 8071, `node tools/serve_web.js tools/motion_viewer/dist 8071`).

새 캐릭터는 `build.mjs`의 `CHARACTERS` 목록에 한 줄을 더한다.

## 동작 겨루기 후보

후보는 Godot 프로젝트 밖에 둔다.

```text
art/bakeoff/<캐릭터 id>/<시트 stem>-<행 이름>-v<번호>.png
art/bakeoff/<캐릭터 id>/<시트 stem>-<행 이름>-v<번호>.json  # 선택
```

예: `art/bakeoff/luna/luna-walk-v1.png`. PNG는 파이프라인이 만든 128px 셀 6열 가로 스트립이다. JSON은 `{"note":"설명", "fps":10, "frames":6}` 형식이다. `frames`·`fps`가 게임 행과 다르면(예: 4프레임 행의 6프레임 후보) 후보는 자기 값으로 재생되고, 프레임 띠와 넘기기는 프레임이 가장 많은 쪽을 따른다. 물러난 후보는 `art/bakeoff/<id>/retired/`로 옮기면 저장소에는 남고 뷰어에서는 빠진다. `stem`은 실제 시트 이름에서 `_sheet.png` 또는 `_moves_sheet.png`를 뺀 값(`frey`, `nova_male`, `luna_brave` 등), 행 이름은 게임 코드의 `idle`, `walk`, `spike_followup` 등과 정확히 같아야 한다.

`build.mjs`는 후보를 해당 행 manifest에 붙이고 `dist/bakeoff/`로 복사한다. 후보가 있는 타일에는 `후보 N` 배지가 보이며, 선택하면 현재 행과 후보들이 동기 재생된다. 좁은 화면에서는 비교 패널이 가로 스크롤된다.
