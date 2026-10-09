# Smash Nine Sites 배포 기록

## 완료

- `powershell -ExecutionPolicy Bypass -File tools/build_web.ps1`로 Godot 4.7 웹 빌드를 새로 생성했다.
- 기존 Sites 프로젝트 `appgprj_6ac65f43555481918a37077e8c63c66c`에 버전 3을 소유자 전용으로 배포했다.
- `build/web/`의 `.partN` 파일을 그대로 배포했으며, 합쳐진 `index.wasm` 또는 `index.pck`은 포함하지 않았다.
- 게임 원본 저장소에는 커밋하거나 push하지 않았다. 추적 파일은 이 문서와 `site.json`만 수정했다.

## 빌드 결과

- 게임 소스 커밋: `314f3f808dcd8aef537dc623f6d9269481a45f93`
- 출력 폴더: `build/web/`
- 업로드 ZIP: `build/SmashNine-web.zip`
- ZIP 크기: 16,793,220 bytes (16.02 MiB, 빌드 스크립트 표시는 16 MB)
- 빌드 출력: `Largest file: index.wasm.part0 (5 MiB)`
- 파일 시스템 교차 확인: 최대 크기 5,242,880 bytes (5 MiB), 제한 이하
- `index.wasm` 원본은 없고 `index.wasm.part0`부터 `index.wasm.part7`까지 8개 조각이 있다.
- `index.pck` 원본은 없고 `index.pck.part0`과 `index.pck.part1` 두 조각이 있다(합계 6,649,416 bytes).
- 배포 아카이브 `build/sites-deploy-v3.tar.gz`는 16,818,261 bytes (16.04 MiB)이며, 아카이브에서도 위 조각 구성이 유지됐다.

## 배포 결과

- URL: https://smash-nine-prototype.tt9.chatgpt.site
- 접근 범위: 소유자 전용 (`custom`, 허용 사용자 1명, 그룹 및 외부 방문자 없음)
- 버전 번호: `3`
- 버전 ID: `appgprj_6ac65f43555481918a37077e8c63c66c~appgver_5ae7ca1d56ec81918474cc2366ccf5c7`
- 배포 ID: `appgdep_6ac9151aaacc81918a8e95e3a3420abf`
- Sites 소스 커밋: `085f71043384e97069a413313b60d077a0993879`
- 배포 시각(UTC): `2026-10-09T16:24:13.000752Z`
- 배포 상태: `succeeded`

```text
Godot 분할 빌드 ✓ (최대 5 MiB)
        ↓
Sites 소스 17개 파일 해시 일치 ✓
        ↓
버전 3 저장 및 소유자 전용 배포 ✓
        ↓
프로덕션 URL 반환 ✓
```

위 흐름도는 이번 작업에서 실제 확인한 범위다.

## 확인 및 제한

- Sites 배포 API가 `succeeded`와 프로덕션 URL을 반환한 것을 확인했다.
- 이번 요청은 빌드와 새 버전 배포만을 범위로 했으므로 실제 브라우저 게임 실행 검증은 하지 않았다.
- 초기 소스 열기에서 작업 디렉터리 선택 오류로 `Local and remote Site history diverged` 안전 중단이 한 번 발생했다. 원격이나 게임 저장소를 덮어쓰지 않았고, 빈 `build/sites-source/`에서 원격 Sites 이력을 다시 열어 해결했다.
- 공식 Node 패키징 래퍼는 Windows PATH에서 `bash`를 시작하지 못했으며, 번들된 동일 `package-site.sh`를 Git Bash로 실행해 아카이브를 생성했다. 서버의 파일 크기 거부나 배포 오류는 발생하지 않았다.

## 현재 상태

버전 3은 소유자 전용 프로덕션 사이트에 배포되어 있다. 기록 상태는 `deployed_not_browser_verified`다.

## 남은 작업

배포 자체에 남은 작업은 없다. 브라우저 게임 실행 검증은 이번 요청 범위에 포함되지 않았다.

## 다음 권장 단계

리드가 `reports/codex-deploy/site.json`과 이 문서의 변경을 검토한 뒤 필요하면 커밋하면 된다.
