# CODEX-TOOL-02 결과

캐릭터 주위 이펙트 19장면을 이펙트 켬/끔 38개 손실 없는 WebP(960×540, 30fps, 17.52 MiB)로 만들었다. 기존 기본 공격 36쌍은 파일을 다시 쓰지 않았고, `manifest.json`에서 `group: j`와 `group: around`로 나눴다.

| 폼 | 장면 | 보이는 내용 |
| --- | --- | --- |
| 6폼 전부 | `guard` 6개 | 0.6초 방어 유지, 막기 피격, 재방어 직후 패리와 `parry_flash` |
| Frey | `pursuit`, `spike`, `ultimate` | 뜬 더미의 추격 표식, L 재입력 고리와 강스파이크, 지상 궁 충전·좌우 파동·여진 |
| Luna / Brave | `star-charge`, `transform`, `aura` | J 적중으로 모은 별 3개 궤도, 12프레임 변신, 1.5초 Brave 오라 |
| Yuki | `seals`, `ultimate` | 봉인부 2개와 한 장 파괴, 대결계 경고·활성·마지막 폭발 |
| Nova | `momentum`, `ultimate` | 최고속도 잔상→K 시프트→시프트 준비 신호, I 3단계 코어→궤도→발사 |
| Rio | `rune`, `ultimate` | 룬 방패의 흡수와 반격 폭발, 원과 여섯 보석검의 궤도·발사 |
| Frey | `status` | 기절 아이콘 뒤 슈퍼아머 아이콘 |

## 실행과 확인

`smash-nine-prototype/`에서 다음 순서로 실행했다.

```powershell
$env:PYTHONDONTWRITEBYTECODE = '1'
$godot = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
& $godot --headless --path . --import
& $godot --path . --fixed-fps 60 -s tests/capture_move_clips.gd
```

- 19쌍 모두 FX/무FX 프레임 수와 시간이 같고, 모든 쌍에서 시각 차이가 검출됐다(차이 프레임 13~118장).
- `middle-frames-fx.png`와 `middle-frames-nofx.png`로 새 클립 38개의 중간 프레임을 전부 직접 확인했다. 무FX에는 캐릭터·바닥·훈련 더미만 남는다.
- Frey 추격은 중간 프레임에서 실제 적중 피해, 뜬 더미, 머리 위 표식이 함께 보이도록 재캡처했다.
- 모션 뷰어 빌드는 성공했고 산출 HTML에 두 그룹 제목과 `끔 / 지금 / 새 후보` 모드가 들어갔다.
- 전체 Godot assertion과 soak는 통과 문구/exit 0을 냈지만, 샌드박스 고정 경고 `Failed to read the root certificate store`를 러너가 엔진 오류로 집계해 최종 `run_all.ps1` 종료 코드는 1이었다.

## 남은 제한

- 로컬 브라우저 확인은 `127.0.0.1:8073` 접근 권한이 거부되어 실제 클릭 검증을 하지 못했다. 정적 빌드·경로 검증까지만 완료했다.
- 훈련 더미는 게임의 `setup_dummy`가 그리는 회색 직사각형 그대로다.
- `art/clips-new`의 새 주위 이펙트 후보 클립은 리드가 나중에 채운다.
