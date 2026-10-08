# Smash Nine Sites 배포 기록

## 완료

- `powershell -ExecutionPolicy Bypass -File tools/build_web.ps1`로 Godot 4.7 웹 빌드를 새로 생성했다.
- 기존 Sites 프로젝트 `appgprj_6ac65f43555481918a37077e8c63c66c`에 버전 2를 소유자 전용으로 배포했다.
- `build/web/`의 분할 파일을 그대로 배포했으며, 합쳐진 `index.wasm` 또는 `index.pck`은 포함하지 않았다.
- 게임 원본 저장소에는 커밋이나 push를 하지 않았다.

## 빌드 결과

- 게임 소스 커밋: `ae406ffa07d095106542926b3a12ca2da3a6ed09`
- 출력 폴더: `build/web/`
- 업로드 ZIP: `build/SmashNine-web.zip`
- ZIP 크기: 16,775,078 bytes (16.00 MiB, 빌드 스크립트 표시는 16 MB)
- 빌드 출력: `Largest file: index.wasm.part0 (5 MiB)`
- 파일 시스템 교차 확인: 최대 크기 5,242,880 bytes (5 MiB), 제한 이하
- `index.wasm` 원본은 없고 `index.wasm.part0`부터 `index.wasm.part7`까지 8개 조각이 있다.
- `index.pck` 원본은 없고 `index.pck.part0`과 `index.pck.part1` 두 조각이 있다(합계 6,630,200 bytes).
- 배포 아카이브에서도 합쳐진 `index.wasm`과 `index.pck`이 없고, 위 조각 구성이 유지된 것을 확인했다.

## 배포 결과

- URL: https://smash-nine-prototype.tt9.chatgpt.site
- 접근 범위: 소유자 전용 (`custom`, 허용 사용자 1명, 그룹 및 외부 방문자 없음)
- 버전 번호: `2`
- 버전 ID: `appgprj_6ac65f43555481918a37077e8c63c66c~appgver_1cbe1d226c648191a13750584efcd5a4`
- 배포 ID: `appgdep_6ac770f7cc208191bd7a489d18ca1039`
- Sites 소스 커밋: `fb8dcac645affb1e74a34adc57378a3147eaf7d5`
- 배포 시각(UTC): `2026-10-08T10:31:39.249242Z`

```text
Godot 분할 빌드 ✓ (최대 5 MiB)
        ↓
기존 Sites 프로젝트의 새 소스 커밋 업로드 ✓
        ↓
버전 2 저장 및 소유자 전용 배포 ✓
        ↓
소유자 로그인 Chrome에서 실제 게임 검증 ✓
```

위 흐름도에서 빌드, 게시, 실제 브라우저 검증까지 모두 완료했다.

## 브라우저 확인

소유자 로그인이 완료된 실제 Chrome에서 배포 URL을 열어 다음을 직접 확인했다.

- 시작 화면: 타이틀 로고, 왼쪽 캐릭터 초상화 5개, `[5] Rio`, `[V] Body` 표시
- 5 키 입력: Rio로 경기가 시작됨
- 경기 화면 오른쪽 아래: `J`, `K`, `L`, `I`가 붙은 스킬 아이콘 네 칸
- 경기 화면 아래: 조작키 안내가 한 줄로 표시됨
- 경기 화면 오른쪽: 8명 상태를 나열하는 봇 패널 표시
- 브라우저 콘솔: `error` 수준 로그 0건

사이트는 소유자 전용이므로 접근에는 소유자 로그인이 필요하다. 이번 확인은 이미 로그인된 소유자 Chrome 세션에서 수행했다.

## 현재 상태

버전 2 배포와 요청된 화면·동작 검증이 완료됐다. 상태는 `deployed_verified`로 기록했다. 서버의 파일 크기 거부는 발생하지 않았다.

## 남은 작업

이번 배포 요청 범위에서 남은 작업은 없다.

## 다음 권장 단계

리드가 `reports/codex-deploy/site.json`과 이 문서의 변경을 검토한 뒤 필요하면 커밋하면 된다.
