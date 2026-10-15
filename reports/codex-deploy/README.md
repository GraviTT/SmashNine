# Smash Nine Sites 배포 기록

## 완료

- `main`의 `cde86ef5bec431fab5488e2f1015d3b986bb58de`을 확인한 뒤 `powershell -ExecutionPolicy Bypass -File tools/build_web.ps1`로 Godot 4.7 웹 빌드를 생성했다.
- 기존 Sites 프로젝트 `appgprj_6ac65f43555481918a37077e8c63c66c`에 5번째 버전을 소유자 전용으로 배포했다.
- `build/web/`의 `.partN` 파일을 합치거나 빼지 않고 그대로 배포했다. 합쳐진 `index.wasm`과 `index.pck`은 포함하지 않았다.
- 게임 원본 저장소에는 커밋하거나 push하지 않았다. 추적 파일은 이 문서와 `site.json`만 수정했다. Sites 전용 임시 체크아웃에는 호스팅 절차상 소스 커밋 1개를 만들고 push했다.

## 빌드 결과

- 게임 소스 커밋: `cde86ef5bec431fab5488e2f1015d3b986bb58de`
- 출력 폴더: `build/web/` (19개 파일)
- 업로드 ZIP: `build/SmashNine-web.zip`
- ZIP 크기: 26,706,962 bytes (25.47 MiB, 빌드 스크립트 표시는 25.5 MB)
- 빌드 출력: `Largest file: index.pck.part0 (5 MiB)`
- 파일 시스템 교차 확인: 최대 크기 5,242,880 bytes (5 MiB), 제한 이하
- `index.wasm` 원본은 없고 `index.wasm.part0`부터 `index.wasm.part7`까지 8개 조각이 있다(합계 39,509,339 bytes).
- `index.pck` 원본은 없고 `index.pck.part0`부터 `index.pck.part3`까지 4개 조각이 있다(합계 16,592,952 bytes).
- 배포 아카이브 `build/sites-deploy-v5.tar.gz`는 26,729,038 bytes (25.49 MiB)이며, 아카이브에서도 위 조각 구성이 유지됐다.

## 버전 4 이후 변경점

다음 항목은 사용자가 제공한 변경 요약이며, 이번 배포 작업에서 기능별로 다시 검증한 내용은 아니다.

- Frey·Luna·Brave Luna·Yuki·Nova 스프라이트 재작화: 6프레임 동작과 192px 기술 시트
- Rio를 제외한 전 캐릭터 8프레임 걷기
- Luna 궁극기 변신 모션
- 대기 동작 6.3fps
- Rio를 포함한 새 메인 아트

## 배포 결과

- URL: https://smash-nine-prototype.tt9.chatgpt.site
- 접근 범위: 소유자 전용 (`custom`, 허용 사용자 1명, 그룹 및 외부 방문자 없음)
- 버전 번호: `5`
- 버전 ID: `appgprj_6ac65f43555481918a37077e8c63c66c~appgver_a4a4b56438708191a2f59346ddb4c531`
- 배포 ID: `appgdep_6ad050e293dc81919d9bf4cd88611e55`
- Sites 소스 커밋: `5da8abbea01e368935f4fe7d35b575632584ce0d`
- 배포 시각(UTC): `2026-10-15T04:05:20.041991Z`
- 배포 상태: `succeeded`
- 서버 저장 확인: 20개 파일, 콘텐츠 해시 `sha256:0821010b0dbfdae53d583d36e014bdcc198947dc05ef74b7d78ef558c733cdb4`

```text
main cde86ef 확인 ✓
        ↓
Godot 분할 빌드 ✓ (최대 5 MiB)
        ↓
Sites 소스 19개 빌드 파일 해시 일치 ✓
        ↓
버전 5 저장 및 소유자 전용 배포 ✓
```

위 흐름도는 이번 작업에서 실제 확인한 범위다.

## 확인 및 제한

- Sites 배포 API가 `succeeded`와 프로덕션 URL을 반환했고, 저장된 버전 번호가 `5`임을 확인했다.
- 이번 요청은 빌드와 새 버전 배포만을 범위로 했으므로 실제 브라우저 게임 실행 검증은 하지 않았다.
- 첫 빌드 시 이전 `index.wasm`을 지우는 순간 파일 잠금이 발생해 한 번 중단됐으나, 잠금 해제와 Godot 프로세스 종료 상태를 확인한 뒤 같은 명령으로 재실행해 정상 완료했다.
- 공식 패키징 래퍼가 Windows 경로를 GNU tar의 원격 경로 문법으로 해석해 `tar (child): Cannot connect to C: resolve failed`로 한 번 중단됐다. 같은 번들 `package-site.sh`에 MSYS 형식 경로를 전달해 정상 패키징했으며, 서버 거부나 배포 오류는 발생하지 않았다.
- 빌드 전부터 있던 미추적 파일은 변경하지 않았고, 이번 빌드가 새로 만든 미추적 파일은 없었다.
- 빌드 시작 시 `main`은 요청한 `cde86ef`이었다. 작업 도중 외부 커밋 두 개가 추가되어 최종 확인 시 `main`은 `8e35644`가 되었지만, 두 커밋의 변경은 `routine/README.md`뿐이어서 게임 빌드 입력에는 차이가 없다.

## 현재 상태

버전 5는 소유자 전용 프로덕션 사이트에 배포되어 있다. 기록 상태는 `deployed_not_browser_verified`다.

## 남은 작업

배포 자체에 남은 작업은 없다. 브라우저 게임 실행 검증은 이번 요청 범위에 포함되지 않았다.

## 다음 권장 단계

리드가 `reports/codex-deploy/site.json`과 이 문서의 변경을 검토한 뒤 필요하면 커밋하면 된다.
