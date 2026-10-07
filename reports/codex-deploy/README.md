# Smash Nine Sites 배포 기록

## 완료

- `powershell -ExecutionPolicy Bypass -File tools/build_web.ps1`로 Godot 4.7 웹 빌드를 새로 생성했다.
- 기존 Sites 프로젝트 `appgprj_6ac65f43555481918a37077e8c63c66c`에 버전 1을 소유자 전용으로 배포했다.
- 게임 원본 저장소에는 커밋이나 push를 하지 않았다. Sites 배포용 소스는 `build/sites-source/`에 새 이력으로 만들었고, 지난 실패의 대용량 객체 이력을 포함하지 않았다.

## 빌드 결과

- 게임 소스 커밋: `55fcea86dc7d9b1d27a3755f76403c61ad098342`
- 출력 폴더: `build/web/`
- 업로드 ZIP: `build/SmashNine-web.zip`
- ZIP 크기: 14,704,178 bytes (14.02 MiB, 빌드 스크립트 표시는 14 MB)
- 빌드 출력: `Largest file: index.wasm.part1 (5 MiB)`
- 파일 시스템 교차 확인: 최대 크기 5,242,880 bytes (5 MiB)
- `index.wasm` 원본은 존재하지 않는다.
- `index.wasm.part0`부터 `index.wasm.part6`까지 각각 5 MiB이며, `index.wasm.part7`은 2,809,179 bytes이다.
- `index.pck`은 4,537,468 bytes이다.
- `index.html` 로더가 `index.wasm`을 8개 조각으로 불러오도록 설정된 것을 확인했다.

## 배포 결과

- URL: https://smash-nine-prototype.tt9.chatgpt.site
- 접근 범위: 소유자 전용 (`custom`, 허용 사용자 1명, 그룹 및 외부 방문자 없음)
- 버전 번호: `1`
- 버전 ID: `appgprj_6ac65f43555481918a37077e8c63c66c~appgver_336704462edc8191bb9baf823f8f7371`
- 배포 ID: `appgdep_6ac66b0c4cdc8191877bf733c39e9dbd`
- 배포 시각(UTC): `2026-10-07T15:54:11.581258Z`

```text
Godot 분할 빌드 ✓ (최대 5 MiB)
        ↓
빈 Sites 소스 이력 생성 ✓
        ↓
Sites 소스 업로드 ✓
        ↓
버전 1 저장 및 소유자 전용 배포 ✓
        ↓
브라우저 접속 ✓ → 소유자 로그인 필요 → 보안 확인에서 중단
```

위 흐름도에서 사이트 게시까지는 완료됐고, 게임 화면 검증만 로그인 단계에서 막혔다.

## 브라우저 확인

실제 브라우저에서 배포 URL을 열었다. 사이트는 먼저 `접속하려면 로그인하세요` 화면을 표시했고, `ChatGPT로 계속`을 선택한 뒤 `auth.openai.com`의 Cloudflare 보안 확인 화면에서 더 진행되지 않았다. 소유자 로그인이 필요한 사이트임을 실제로 확인했다.

로그인 이후 게임 문서에 도달하지 못했으므로 다음 항목은 확인했다고 기록하지 않는다.

- 시작 화면 로고
- 왼쪽 얼굴 초상화 5개
- `[5] Rio`, `[V] Body` 표시
- 5 키 경기 시작
- 게임 브라우저 콘솔 오류 없음
- 네트워크의 `index.wasm.part0~7` 및 `index.pck` HTTP 200

## 현재 상태

배포 자체는 성공했으며 사이트는 소유자 전용으로 게시되어 있다. 상태는 `deployed_verification_blocked_owner_login`으로 기록했다.

## 다음 권장 단계

소유자 로그인이 완료된 브라우저 세션에서 화면, 5 키 시작, 콘솔, 네트워크 응답만 다시 확인하면 된다. 조각 크기를 더 줄이는 재빌드는 현재 필요하지 않다.

## 소유자 확인 (2026-10-08)

사용자가 배포된 버전 1을 직접 열어 플레이했다(사용자: "배포 후 플레이 완료"). Codex 브라우저 확인은 소유자 로그인 게이트에서 막혔으므로, 게임 화면 확인은 이 사용자 플레이가 근거다.
