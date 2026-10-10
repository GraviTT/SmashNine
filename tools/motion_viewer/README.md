# 모션 뷰어

캐릭터 6명(Frey, Luna, Brave Luna, Nova 남·여, Rio 남·여, Yuki)과 몬스터 18종의 모든 동작을 게임 시트 그대로 재생하는 페이지.

- 주소: https://claude.ai/artifact/188Ryqb526Ue58MDf4BnbU (소유자 전용 Artifact)
- 기능: 캐릭터·체형 고르기, 기본 동작과 기술 동작 전체를 한 번에 재생, 큰 화면에서 재생·멈춤·프레임 넘기기(`Space`, `←` `→`, `↑` `↓`), 속도 0.25~2배, 배율 1~4배, 배경(체크·어둡게·밝게), 가이드(발 기준선 y=120, 칸 테두리, 여백 4px), 프레임 띠, 시트 파일·줄 번호·fps·길이.
- 줄 정의는 게임 코드에서 읽는다: `PlayerBase.ORIGINAL_SHEET_ROWS`, 각 캐릭터의 `MOVE_SHEET_ROWS`(Brave는 `BRAVE_MOVE_SHEET_ROWS`), `RealmMonster.ART_ROWS`. 기술 이름표는 `*_moves_README.md` 표의 Move 열.

## 그림이 바뀌었을 때

1. 저장소 루트에서 `node tools/motion_viewer/build.mjs` → `tools/motion_viewer/dist/`(index.html + sheets/, git에 안 올림)
2. 같은 Artifact에 다시 게시: `dist/index.html`을 위 주소로 publish, `root`는 `dist`, `files`는 `dist/files.json`의 목록. 주소는 그대로 유지된다.
3. 로컬로 볼 때: `.claude/launch.json`의 `motion-viewer`(포트 8071, `node tools/serve_web.js tools/motion_viewer/dist 8071`).

새 캐릭터는 `build.mjs`의 `CHARACTERS` 목록에 한 줄을 더한다.
