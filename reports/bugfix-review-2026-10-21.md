# 전체 코드 버그 점검 (2026-10-21)

- 브랜치: `claude/bugfix-review-2026-10-21` (워크트리 `.claude/worktrees/bugfix-review`, `main` `7b54932`에서 시작)
- 범위: `smash-nine-prototype/scripts/`, `smash-nine-prototype/characters/` 전체 (최근 변경분이 아니라 코드 전체)
- 방식: code-review(high) 관점으로 직접 읽고, 후보마다 코드로 재현 → 실제 버그만 수정 → 버그 하나당 커밋 하나
- 회귀 테스트: `smash-nine-prototype/tests/test_bugfix_review.gd` (6건, `run_all.ps1`에 추가). 각 건은 수정 없이 실패하고 수정 후 통과하는 것을 확인했다.
- push, merge, PR은 하지 않았다.

## 고친 버그

| # | 파일:줄 (수정 후) | 증상 | 심각도 | 커밋 |
|---|---|---|---|---|
| 1 | `characters/common/PlayerBase.gd:1388` (`apply_forced_launch_hit`) | 띄우기 공격(발사형 피격)을 맞아도 진행 중인 스킬 대시가 끊기지 않음. 프레이가 공중 필살기 강하 중 띄우기를 맞으면 최대 1.2초 동안 강하 속도로 계속 떨어짐(루나·리오 대시도 피격 후 계속 진행). 일반 피격(`apply_hit`)은 이미 대시를 끊고 있었음 | 중 | `c0e9ede` |
| 2 | `scripts/Main.gd:577-580` (`_update_hud`) | P1이 소울 카드를 고르는 중에 탈락하면 카드 패널("press 1 / 2 / 3")이 멈춘 채 관전 내내 화면에 남음. SoulGrowth는 탈락 시 제안을 지우지만 `offer_closed`를 보내지 않아 패널을 끄는 곳이 없었음 | 중하 | `a9dea31` |
| 3 | `characters/common/PlayerBase.gd:1051` (`_wait_action`), `characters/frey/Frey.gd:398`, `characters/luna/Luna.gd:574` | 모든 기술의 선딜·지연 타격이 렌더 프레임(유휴) 타이머로 계산되어, 경직·공격 잠금·이동(물리 틱)과 시계가 어긋남. 60fps 미만(느린 기기의 웹 빌드)에서 0.5초 대기가 29~36틱으로 흔들려 기술이 일찍/늦게 나가고 루나 별 메아리 블룸이 빗나감. 기준 실행에서 `test_frey_kit`, `test_luna_kit`가 부하 때문에 실패했고 `--max-fps 20`에서 `test_luna_kit`가 재현됨 | 중 | `501f097` |
| 4 | `scripts/ui/MatchHud.gd:461` (`set_status`) | 결과 화면이 경기 HUD를 숨긴 뒤에도 Main이 매 프레임 `set_status`를 불러 HP 바를 다시 켬(결과 표 뒤로 비침) | 하 | `6355541` |
| 5 | `characters/common/PlayerBase.gd:1626` (`_respawn`) | 링아웃 후 리스폰 시 공격 잠금·경직·히트스톱 타이머가 남음(포털·붕괴 이동의 `reset_for_map`은 이미 지움). 프레이가 공중 필살기로 떨어져 링아웃되면 리스폰 후 남은 1.45초 잠금 동안 점프·공격 불가 | 중 | `2195855` |
| 6 | `characters/common/PlayerBase.gd:1303, 1334, 1398` | 공격자 없는 피격(용암 기둥·빛 기둥·지진 등 렐름 기믹)으로 탈락하면, 얼마나 오래전이든 마지막으로 때린 사람에게 KO 점수(+1)와 소울 12를 줌. 링아웃은 8초 기억(`LAST_ATTACKER_MEMORY`) 안에서만 인정하고 있었음 | 중하 | `50aa0be` |

## 찾았지만 고치지 않은 것

| 파일:줄 | 내용 | 심각도 | 안 고친 이유 |
|---|---|---|---|
| `scripts/RealmMonster.gd:175, 180` | 몬스터 경직 중 `velocity.x = knockback_velocity.x` 다음에 `velocity += knockback_velocity`를 또 해서 가로 넉백이 2배로 적용됨 | 하 | 처음부터 이렇게 동작했고 몬스터 밀림 손맛·밸런스가 이 값으로 맞춰져 있음. 의도인지 확인 필요(사용자 결정) |
| `scripts/RealmMonsterSpawner.gd:70`, `scripts/SoulCrystalSpawner.gd:51` | 경기가 끝난 뒤에도 몬스터·크리스털 재생성 타이머가 돌아, 결과 화면 뒤에서 새 몬스터가 움직임(전투원은 무적이라 피해 없음) | 하 | 결과 표(불투명도 0.92) 뒤라 거의 보이지 않고 게임 결과에 영향 없음 |
| `characters/yuki/Yuki.gd:118-124` | 발동한 봉인은 `seals` 목록에서 빠져서, 유키가 포털로 떠나거나 탈락해도 0.58초 뒤 원래 렐름에서 터지고 피해가 유키에게 기록됨 | 하 | 발동 직후의 짧은 창이고 설계 의도(이미 던진 기술)일 수 있음 |
| `characters/common/PlayerBase.gd:1569` | 연습용 허수아비(H)를 쓰러뜨려도 KO 점수와 소울을 받음 | 하 | 연습 기능이라 의도일 수 있음 |
| `characters/nova/NovaGravityBurst.gd:66-72`, `NovaBodyHitbox.gd` | `_on_body_entered` 경로에서 `source` 유효성 확인 없이 `source.facing` 등을 읽음 | 하 | 노바가 경기 중 해제되는 경로가 없어 실제로는 발생하지 않음 |
| `characters/common/PlayerBase.gd:489` 등 | 히트스톱 중에도 입력으로 공격이 시작되고, 선딜 타이머는 히트스톱 동안에도 흐름 | 설계 | 버그라기보다 타격감 설계 문제. 바꾸면 모든 기술 타이밍이 달라짐 |

## 깊이 보지 못한 부분

- `scripts/EnemyAI.gd`(1741줄): 봇 튜닝이 보류 중(D30)이라 `update`·`reset`·상태 선택 흐름만 읽음. 경로 탐색·가드·노바 슬링샷 조종은 보지 않음(소크 매치에서 오류 없음).
- `scripts/realms/RealmWorld.gd`, `RealmCatalog.gd`, `scripts/RealmBackdrop.gd`, `scripts/Vfx.gd`, `scripts/ArtSettings.gd`, `characters/common/MotionSpeeds.gd`: 그림·데이터 위주라 훑어보기만 함.
- 노바 필살기(궤도·발사 단계), 리오 오버드라이브, 루나 혜성(`LunaComet.gd`)의 세부 판정.
- 저장/불러오기는 게임 속도 설정(`user://game_speed.cfg`) 하나뿐이고 이상 없음.

## 테스트·빌드 결과

- 수정 전(`main` `7b54932`, `run_all.ps1`): 34개 중 32개 통과, `test_frey_kit`(J 연타가 경직 안에 이어지지 않음)과 `test_luna_kit`(별 메아리 블룸 빗나감) 실패. 단독으로 다시 돌리면 통과 → 부하·프레임레이트에 따라 흔들리는 실패였고, 원인은 수정 3(유휴 프레임 타이머).
- 수정 후(`run_all.ps1`, 새 테스트 포함 35개 + 봇 8인 소크 매치 seed 1001): **모두 통과(ALL PASSED)**, 엔진 오류 줄 0.
- 각 수정마다: 새 회귀 테스트가 수정 없이 실패하고 수정 후 통과하는 것, 관련 기존 테스트가 통과하는 것을 확인한 뒤 커밋했다.
- 게임 직접 확인(창 모드, 원본 그림): `bugfix-review-2026-10-21/`
  - `fix2_a_card_offer.png` — P1(프레이) 소울 카드 제안이 뜬 상태
  - `fix2_b_p1_out_no_panel.png` — P1 탈락 직후, 카드 패널이 사라짐(수정 전에는 남아 있었음)
  - `fix4_results_no_hp_bar.png` — 결과 화면, 뒤에 HP 바 없음
- 웹 빌드는 하지 않았다(배포 단계가 아님).
