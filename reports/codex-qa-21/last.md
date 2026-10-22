확정 버그 **2건**, 카드 요구 불일치 **1건**을 기록했습니다. 제품 코드는 수정하지 않았습니다.

| 심각도 | 발견 사항 | 재현 / 수정 후보 |
|---|---|---|
| 중 | 문 출구 **7/7곳**이 발판과 불일치. 상층 5곳에서 **159~364px 추가 낙하** | `gate_geometry.gd` / `RealmCatalog.gd:104` |
| 중·요구 차이 | 몬스터는 문·벨트 미적용. 벨트 이동은 사람·봇 **45px**, 몬스터 **0px** | `gimmick_actors.gd` / `RealmHazards.gd:409,473` 및 생성 등록 |
| 하 | 후속 대화 중 궁극기 컷인이 **51프레임·0.85초** 잔류 | `story_cutin.gd` / `MatchHud.gd:924` |

[상세 보고서·재현 명령·실측 그림](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/reports/codex-qa-21/README.md)

검증은 14여정·126스테이지, 메뉴 14회, 몬스터 36조건, 대화 190장면을 포함합니다. 기존 **51개 테스트와 봇 경기 3회**는 통과했습니다. 문 통과 14회에서 반복 왕복 루프는 관측되지 않았습니다.

Web 핵심 파일은 **63.23MiB**, 바이트 동일성을 확인한 gzip 실험값은 **33.06MiB**입니다. 실제 브라우저 시작 시간·영구 저장 복원·사람 난이도는 미확인입니다.

`.git` 읽기 전용으로 [commit.ps1](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/reports/codex-qa-21/commit.ps1)을 준비했습니다. 다음 권장 단계는 리드의 문 좌표 수정과 해당 재현 재검증입니다.