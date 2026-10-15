# CODEX-TOOL-01 결과

- Frey, Luna, Brave Luna, Yuki, Nova 남성, Rio 남성의 기본 공격 6종을 만들었다: 지상 J(연계형은 3타 연속), 지상 ↑J/↓J, 공중 J/↑J/↓J.
- 총 36쌍/72개 손실 없는 애니메이션 WebP이며 모두 960×540, 30fps다. 전체 용량은 약 10.57 MiB이고 클립은 13~45프레임(0.433~1.5초)이다.
- 캡처 명령: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe --path . --fixed-fps 60 -s tests/capture_move_clips.gd` (`smash-nine-prototype/`에서 실행).
- 모션 뷰어는 각 캐릭터의 **게임 화면**에서 여섯 클립을 보여 주고, 한 토글로 전부 FX/무FX를 함께 바꾼다. 선택한 시트 줄은 ×0.50~×1.50으로 조절하며 실제 fps와 복사용 **바뀐 속도** 목록을 표시한다.
- FX/무FX의 프레임 수와 재생 시간은 전부 일치한다. 34쌍은 별도 이펙트 픽셀 차이가 확인됐다. Frey ↓J와 Yuki ↓J는 현재 30fps 캡처에서 별도 FX 차이가 없고, 캐릭터 시트 안에 그려진 동작 잔상만 양쪽에 남는다.
- 브라우저 로컬 확인은 `http://127.0.0.1:8073` 접근 권한이 거부되어 수행하지 못했다. 빌드 및 정적 연결 검증은 완료했다.
- 전체 테스트의 각 기능 assertion과 소크 매치는 통과 문구를 냈지만, 샌드박스 고정 잡음인 `Failed to read the root certificate store`를 `run_all.ps1`이 엔진 오류로 집계해 최종 종료 코드는 1이었다.
