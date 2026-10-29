# 체크포인트 뒤 작업 기록 — 이미지/스프라이트 (art-sprite)

- 기준: main `c51a417f` = 태그 `checkpoint-2026-10-25`. 여기 적은 결과물은 **main에 들어가지 않는다**. 사용자 점검이 끝난 뒤 따로 점검·적용한다.
- 지시: 점검 세션 "게임 상태 점검 및 정리" (사용자 요청, 2026-10-25) — Codex 사용량 초기화, 사용자 확인이 필요 없는 이미지·스프라이트 보수와 추가 작업.
- 방식: 카드마다 Codex 클론(`SmashNine-units/art-a`, `art-b`)에서 작업, 브랜치는 체크포인트에서 시작. 검토 뒤 메인 저장소에는 `git fetch <클론> <브랜치>:<브랜치>`만 한다(merge 없음). 마지막에 클론 안에서 모아 `after-cp/art-sprite` 브랜치로 가져온다.
- 모든 결과는 **새 후보 버전**(기존 파일 덮어쓰기 없음). 뷰어 재게시·웹 빌드·게임 코드 연결은 하지 않는다.

## 계획 (카드 목록)

| 순서 | 카드 | 무엇 | 클론 |
|---|---|---|---|
| 1 | ART-81 | 후보 전수 기술 점검(측정만): 모션 뷰어 후보 201개 — 프레임 수·칸 크기·여백·발 위치·고정 폭 슬라이싱(칸 경계 잘림)·알파·같은 프레임 반복·행 사이 크기·현재 시트 대비 팔레트 차이 | art-a |
| 2 | ART-82 | 캐릭터 동작 보수: 얼굴 비율 1px 때문에 보류였다가 후보로 넘긴 9줄을 기준(0.96~1.04) 안으로, 약한 동작(Luna 점프 F2·F3, Yuki 낙하 F1·F2 거의 같음, Nova 여 승리 같은 팔 두 번, Luna 승리 F3→F4, Rio 남 승리 F2·F3→F4) | art-b |
| 3 | ART-83 | 몬스터 보수: 보고서의 약점(임프·숫양 디테일, 모슬링·임프 걷기 교대, 모슬링 물기·씨앗 요정 전진 거리, 나방 준비 F2 크기, 사냥개 잎 가장자리 자글거림, 멧돼지 보폭, 늑대 도약 정점, 수호자 주먹 크기, 예언자 촉수, 위습 피격) + ART-81 몬스터 지적 | art-a |
| 4 | ART-84 | 초상화 보수: Yuki·Rio 남 아픔 표정, 그림자 초상화(피부·금속 밝기, Yuki 부적, Rio 여 눈빛 크기) | art-b |
| 5 | ART-85 | 투사체 보수: 폭탄 회전, 얼음 꼬리 흔들림, 뿌리 수호자용 충격파 색 변형(연결은 적용 단계) | art-a 또는 art-b |
| 6 | ART-86 | QA-23 지적 — **지금 게임의 캐릭터 시트** 수리(새 후보 버전으로): Rio 여 마나 콤보 F5·6 검날 절단과 떨어진 검끝(L14), Nova 남 걷기 F3 장갑(L09), Rio 여 걷기 F4 검 방향(L10), Rio 남 걷기 크기 −18%(L11), Nova 여 gravity_brake F4–6 발 4px(L34), Frey 예비 공격 머리 0.92(L37). L28(Nova 여 피격 8px)·L36/L38(Rio 예비 공격 머리)·L35(Rio 여 예비 공격 검)는 이미 있는 후보(D40 `nova_female-hurt-v2`, ART-68 `rio_*-attack-v2`)로 해결되는지 확인만 | 남는 클론 |
| 7 | ART-87 | QA-23 지적 — **지금 게임의 옛 몬스터 4줄 시트** 수리(원본 `_source.png`에서 다시 자르기, 테두리 색 정리, 몸 시트에 섞인 발사 효과 분리): 골렘·멧돼지·늑대·사슴·수호자의 절단(상), 공격 칸 오른쪽 절단 6종, 임프·모슬링 테두리(중), 효과 섞임 8건(하). 새 6줄 후보를 고르면 필요 없어지지만, 지금 게임에 보이는 결함이라 대비용 후보로 만든다 | 남는 클론 |
| 8 | ART-88 | QA-23 지적 — **새 몬스터 후보** 여백(C01–C23)과 늑대 피격 머리 윗부분(C09), ART-81의 json 빠진 칸 43개 정리. ART-83의 v2와 겹치므로 `codex/art-83` 위에서 이어서 한다 | ART-83을 한 클론 |
| 9 | ART-89 | (추가) ART-82에서 못 고친 동작 줄 두 번째 시도: 프레임 하나씩이 아니라 줄 전체를 새로 그림. Frey 승리·도약, 브레이브 피격·도약·낙하, Yuki 승리, Luna 승리 회전, Nova 여 승리 번갈아 잽, Rio 남 승리 F3→F4, Rio 남 걷기 다리 교대. ART-82·86 위에서(클론 안에서 합침) | art-a |
| 10 | ART-90 | (추가) 남은 작은 보수: 뿌리 수호자 F1 위 여백(QA-23 C08·C22), 사냥개 v2 잔점, 옛 사슴 시트 공격 줄 크기·F4 재사용(ART-87), QA-23 손 확인 대상 Luna 낙하·Nova meteor_kick 머리. ART-88·87 위에서(클론 안에서 합침) | art-b |
| 11 | — | 카드 브랜치를 클론 안에서 `after-cp/art-sprite`로 모아 메인 저장소로 fetch | — |

QA-23 수리 목록 원문: 버그 확인 세션 브랜치 `bug-check/after-checkpoint-2026-10-25` `12e55d49`의 `reports/codex-qa-23/fix-list.md` (작업 폴더 `.claude/worktrees/bugfix-review/`). 지금 게임 38건 중 캐릭터 시트 10건은 ART-86(그중 4건은 이미 있는 후보로 해결), 몬스터 시트·투사체 28건은 ART-87(옛 투사체 3건 L31–33은 ART-79 새 후보가 대신하거나 게임에서 쓰지 않음 — 까마귀 투사체), 후보 23건은 ART-88.

동시에 도는 Codex 유닛은 2개까지. 사용자 판단이 필요한 일(후보 고르기, 스타일, 밸런스·타이밍, D 번호 결정)은 하지 않는다.

## 카드별 기록

"적용할 때 주의" 칸에는 새 버전마다 **어떤 기존 후보의 새 버전인지**(옛 파일 경로 → 새 파일 경로)를 적는다. 사용자가 지금 뷰어(체크포인트 버전)에서 옛 버전을 고르면, 적용할 때 이 표로 새 버전으로 바꿔 넣을지 정한다. 새 파일의 json에도 `replaces` 필드로 같은 내용이 들어 있다. 줄이 많은 카드는 아래 "새 버전 ↔ 기존 후보" 표에 따로 적는다.

| 카드 | 브랜치 | 무엇을 바꿨나(파일) | 어떻게 확인했나 | 사용자 확인 필요? | 적용할 때 주의(다른 브랜치와 겹침 등) |
|---|---|---|---|---|---|
| ART-81 | `codex/art-81` (`4c85ccc7`) | 그림은 바꾸지 않음. `reports/codex-art-81/`(감사 보고서, `audit.py`·`audit.json`, 4배 보드 20장)만 추가 | 리드가 보고서·결함 표를 읽음. 감사 자체 검사 73개 통과. 결과: 후보 219개 중 확정 결함 1건(`nova_female-hurt-v2`가 1칸짜리 — D40 때 기본 시트의 피격 1칸을 바꾸려고 만든 것이라 6칸 규격 대상이 아님, 리드 판단), 얼굴 비율 검토 8줄(ART-82에서 보수 중), 몬스터 크기 "검토" 다수는 회전·가림 때문인 측정값이라 Codex도 배율 변경 근거가 아니라고 함, json에 `cell`·`feet`·`loop` 빠진 후보 43개(뷰어 기본값으로 동작) | 아니오 | 보고서 파일만 추가, 다른 브랜치와 겹치지 않음 |
| ART-82 | `codex/art-82` (`b7ae92be`) | 새 후보 7개: `art/bakeoff/luna/luna-jump-v4`, `luna-victory-v2`, `luna_brave-victory-v2`, `nova/nova_female-victory-v2`, `rio/rio_female-victory-v2`, `rio/rio_male-victory-v2`, `yuki/yuki-fall-v3` (각 `.png`+`.json`) + `reports/codex-art-82/` | Codex가 58프레임 4배 확인·파일 검사 246개 통과, 리드가 4배 비교판으로 Luna 점프(정점 구분)·Yuki 낙하(F2 휘날림)·Nova 여 승리(얼굴 폭 1.000)를 직접 봄. 13줄 중 6줄(Frey 승리·도약, 브레이브 피격·도약·낙하, Yuki 승리)은 다시 그려도 얼굴이나 자세가 나빠져 **내지 않음**. Luna 승리·Nova 여 승리·Rio 남 승리는 얼굴만 고쳐지고 동작 약점(지팡이 회전, 같은 팔 잽, F3→F4)은 남음(부분) | 아니오(고를 때 옛/새 버전 비교) | 아래 "새 버전 ↔ 기존 후보" 표 참고. 커밋에서 시도별 중간 프레임 588개(28MB)는 뺐다(클론에만 있음) |
| ART-83 | `codex/art-83` (`234f1a9e`) | 새 후보 15줄(`art/bakeoff/monsters/*-v2.png`+`.json`)과 조립 시트 8장(`*_sheet-v2.png`: mossling, ember_imp, asgard_aegis_ram, vanaheim_seed_sprite, vanaheim_vine_hound, alfheim_moon_moth, jotunheim_storm_wisp, niflheim_glacier_wolf) + `reports/codex-art-83/` | Codex가 전 프레임 1×·4× 확인·파일 검증, 리드가 전후 비교판 확인(모슬링·임프 걷기 다리 교대, 씨앗 요정 전진, 늑대 정점 F3). 측정: 임프 대기 디테일 72–76→97–101, 숫양 대기 75–81→92–97, 모슬링 물기 전진 −2→16px, 씨앗 요정 5→10px, 나방 준비 F2 크기 0.896→1.020, 위습 피격 돌–핵 간격 5→16px, 사냥개 잎 가장자리 점 지표 약 절반 | 아니오(고를 때 v1/v2 비교) | 조립 시트 v2는 바꾼 줄만 v2, 나머지는 v1. **ART-88이 이 브랜치 위에서 여백을 고치므로 적용은 ART-88 결과를 쓴다.** 사냥개 잔점·나방 더듬이는 아직 약함 |
| ART-87 | `codex/art-87` (`674b7895`) | 지금 게임의 옛 몬스터 4줄 시트 수리본 15장 `art/bakeoff/monsters/legacy/<id>_sheet-fix1.png`(+`.json`, 게임과 같은 576×384) + `reports/codex-art-87/` | QA-23 지적 25건 중 24건 수리, L06은 테두리 정리로 여백이 생겨 추가 조정 불필요. 원본 `_source.png`에서 다시 잘랐고 원본도 잘린 칸만 다시 그림. 손대지 않은 284칸은 게임 시트와 RGBA 일치(검증). 리드가 전후 비교판 확인(골렘 하체, 멧돼지·늑대 다리, 사슴 머리, 임프 테두리, 위습 발사 호 제거) | 아니오. 다만 새 6줄 후보를 고르면 필요 없음 | **새 6줄 후보(ART-71/74/76)와 별개**. 사용자가 새 시트를 고르지 않은 몬스터에만 `smash-nine-prototype/assets/art/monsters/<id>_sheet.png`를 이 파일로 바꾼다. 사슴 공격 줄은 체격이 조금 작아졌고 F4는 다른 칸 재사용, 골렘은 전보다 작아짐 |
| ART-88 | `codex/art-88` (`5884321c`, `codex/art-83` 위) | 새 몬스터 후보 여백 수리 21줄·39프레임: 새 v2 19줄(아래 표) + ART-83의 v2 2줄(씨앗 요정 공격, 사냥개 쓰러짐) 고침, 늑대 피격 머리 재절단(`niflheim_glacier_wolf-hurt-v2`), 조립 시트 v2 14장 다시 맞춤, **체크포인트 후보 json 43개에 빠진 `cell`·`feet`·`loop` 칸만 추가**(다른 값 변경 없음, 리드가 diff 확인) + `reports/codex-art-88/` | Codex가 변경 프레임 4배 확인, 시트 84행 픽셀 일치. 리드가 전후 비교판과 json diff 확인 | 아니오 | QA-23 C08·C22의 수호자 F1 상단 3px는 발 y72와 크기 ±5%를 함께 지키며 고칠 수 없어 남김. 멧돼지 준비→공격 엄니 간격 8→6px(여백 수정 부작용). **적용할 때는 ART-83이 아니라 이 브랜치를 쓴다**(ART-83을 포함) |
| ART-86 | `codex/art-86` (`b61fd696`) | 지금 게임 캐릭터 시트의 수리 후보 6개: `rio/rio_female-mana_combo-v2`, `nova/nova_male-walk-v3`, `rio/rio_female-walk-v4`, `rio/rio_male-walk-v2`, `nova/nova_female-gravity_brake-v2`, `frey/frey-attack-v5` + `reports/codex-art-86/` | QA-23 L14·L09·L10·L11·L37 완료, L34 파일은 만들었으나 원래 줄의 얼굴 검사가 기준 밖이라 Codex가 '보류' 표시. L35·L36·L38(Rio 예비 공격)·L28(Nova 여 피격)은 이미 있는 후보로 해결됨을 확인. 바뀐 19프레임 4배 확인, 안 바뀐 23프레임 바이트 동일. 리드 검토에서 마나 콤보 F5 몸이 7px 뒤로 튀는 것을 찾아 Codex가 다시 고침(몸통 중심 98→102→105, 칼끝 한 덩어리·여백 4px, 리드 재측정) | 아니오 | Rio 남 걷기는 크기만 복구, 다리 교대는 약함. Frey 예비 공격 F3 가려진 볼 경계는 다시 볼 것 |
| ART-85 | `codex/art-85` (`720663d5`) | 새 후보 3개: `art/bakeoff/monsters/svartalfheim_cog_drone-projectile-v2`(폭탄 8장 45° 회전·불꽃 깜박임), `niflheim_frost_owl-projectile-v2`(얼음 본체 고정·꼬리만 반짝임), `yggdrasil_root_guardian-shockwave-v1`(수호자 색 뿌리 충격파, 64×48 4장) + `reports/codex-art-85/` | Codex가 1배·36px·4배 확인과 규격 검사, 나머지 투사체 5종은 다시 보고 결함 없어 유지. 리드가 수호자 충격파 비교판 확인 | 아니오 | 폭탄은 8장이 되어도 지금 연결(SYS-07: 가로÷세로 = 장 수)로 재생됨. **수호자 충격파는 게임이 아직 몬스터별 충격파를 읽지 않음** — 채택하면 `RealmMonster.gd`에 스킨별 파일 이름 연결이 필요(이번엔 코드 안 바꿈) |
| ART-84 | `codex/art-84` (`92b02ae5`) | 대화 초상화 v2 후보 10개: 아픔 표정 2(`yuki/yuki_face-hurt-v2`, `rio/rio_male_face-hurt-v2`), 그림자 8(`<stem>_face-shadow-v2`, 8폼 모두) + `reports/codex-art-84/` | 아픔 표정은 ART-73 방식(얼굴 마스크 합성), 마스크 밖 변경 0px. 그림자는 피부·금속을 어둡게, 눈/얼굴 밝기비 약 2배(예: Frey 1.12→2.27), Yuki 부적 밝기 낮춤, Rio 여 한쪽 눈 강화. 검증 228항목, 1배·142×164·대화 목업 확인. 리드가 전후 비교판 확인 | 아니오(고를 때 v1/v2 비교) | 그림자 v2는 어두운 대화창 위에서 머리·옷 세부가 덜 보임 — v1과 나란히 보고 고를 것. Yuki 그림자 눈과 Rio 여 한쪽 눈은 작은 크기에서 여전히 작음 |
| ART-90 | `codex/art-90` (`919789f6`, ART-88·87 위) | 새 `art/bakeoff/monsters/yggdrasil_root_guardian-attack-v2`; ART-88의 `yggdrasil_root_guardian-defeat-v2`·사냥개 v2 6줄·두 몬스터의 `_sheet-v2`와 ART-87의 `legacy/alfheim_moon_stag_sheet-fix1`을 고쳐 씀(아직 게시 안 된 파일) + `reports/codex-art-90/` | 수호자 F1 위 여백 3→4px(발 y72, 크기 0.995/1.003), 사냥개 28프레임 잔점 1,636→183(알파·눈 보존), 옛 사슴 공격 4장 모두 다른 칸·배율 0.25→0.294·여백 4px. Luna 낙하 머리는 기준 안(고칠 필요 없음). Nova meteor_kick(지금 게임 줄)은 손 측정 여 0.940–1.002, 남 0.998–1.125(F5는 표식 오차로 보임, 나머지 약 1.06) — 줄 전체를 줄이면 몸도 작아져 그대로 둠. 정적 검사 173개, 리드가 Nova 표식판 확인 | 아니오 | **적용할 때는 ART-88·87 대신 이 브랜치를 쓴다**(둘을 포함). Nova 남 meteor_kick 머리 약 6% 큼은 적용 단계에서 리드가 다시 볼 것 |
| ART-89 | `codex/art-89` (`b7bf9ebe`, ART-82·86 위) | 새 후보 5개: `frey/frey-jump-v3`, `luna/luna_brave-hurt-v3`, `yuki/yuki-victory-v2`, `luna/luna-victory-v3`, `nova/nova_female-victory-v3` (각 `.png`+`.json`) + `reports/codex-art-89/`(10줄 모두의 최선 시도와 4배 비교판) | 줄 전체를 한 번에 새로 그림(줄당 최대 3회, 모두 24회), 줄마다 배율 하나, 머리 붙이기 없음. 낸 5줄은 측정할 수 있는 얼굴 비율이 모두 0.96–1.04(감은 눈·윙크 프레임은 측정 제외), 납품 검사 472항목 통과. 리드가 4배 비교판과 3배 전후 줄을 직접 봄(Frey 도약·상승·정점 구분, 브레이브 피격 젖힘→웅크림→가드, Yuki 부적→부채, Luna 한 방향 회전, Nova 번갈아 잽→주먹 유지). **못 낸 5줄**: Frey 승리(눈 간격 1.025–1.081), 브레이브 도약(F1 0.950), 브레이브 낙하(F1 폭 1.071), Rio 남 승리(F5 폭 1.067, F3 칼날 짧음), Rio 남 걷기(1배에서 다리 교대가 안 읽힘, 폭 최대 1.100) — 최선 시도는 보고서 폴더에만 있고 후보로 만들지 않음. 작업 중 이번에 만든 중간 파일 하나를 덮어쓴 실수 1건(기존 파일 영향 없음, 그 결과는 납품에서 뺌) | 아니오(고를 때 옛/새 버전 비교) | 아래 표 참고. Luna 승리·Nova 여 승리는 ART-82 v2의 다음 버전(v1→v2→v3). Luna 승리 F3→F4 지팡이 이동은 아직 큰 편이라 뷰어 재생으로 볼 것. 커밋에서 시도별 중간 파일(`attempts/`, `review/`)은 뺐다(클론에만 있음) |

## 새 버전 ↔ 기존 후보

모션 뷰어의 후보 이름은 파일 이름에서 `.png`를 뺀 것과 같다(예: `frey-victory-v1`).

| 기존 후보(체크포인트, 모션 뷰어) | 새 버전(브랜치의 파일) | 카드 | 무엇이 달라졌나 |
|---|---|---|---|
| `luna-jump-v3` | `art/bakeoff/luna/luna-jump-v4.png` | ART-82 | F3를 무릎 당긴 정점으로 다시 그림(F2와 구분). F1·F2 그대로 |
| `luna-victory-v1` | `art/bakeoff/luna/luna-victory-v2.png` | ART-82 | F2 얼굴 폭 0.929→1.000. 지팡이 회전 F3→F4 간격은 그대로(부분) |
| `luna_brave-victory-v1` | `art/bakeoff/luna/luna_brave-victory-v2.png` | ART-82 | F1 얼굴 폭 1.071→1.000 |
| `nova_female-victory-v1` | `art/bakeoff/nova/nova_female-victory-v2.png` | ART-82 | F1·F3·F6 얼굴 폭 0.931~1.069→1.000. 두 잽이 같은 팔인 것은 그대로(부분) |
| `rio_female-victory-v1` | `art/bakeoff/rio/rio_female-victory-v2.png` | ART-82 | F6 얼굴 폭 1.083→1.000 |
| `rio_male-victory-v1` | `art/bakeoff/rio/rio_male-victory-v2.png` | ART-82 | F2 다시 그림. F3→F4 간격은 그대로(부분) |
| `yuki-fall-v2` | `art/bakeoff/yuki/yuki-fall-v3.png` | ART-82 | F2 머리카락·소매·장식이 F1과 다르게 날림 |
| `mossling-walk-v1` | `art/bakeoff/monsters/mossling-walk-v2.png` | ART-83 | 다리 교대가 1배에서 보임 |
| `mossling-attack-v1` | `art/bakeoff/monsters/mossling-attack-v2.png` | ART-83 | 물 때 몸이 16px 앞으로 나감 |
| `ember_imp-walk-v1` | `art/bakeoff/monsters/ember_imp-walk-v2.png` | ART-83 | 다리 교대가 1배에서 보임 |
| `ember_imp-idle-v1` | `art/bakeoff/monsters/ember_imp-idle-v2.png` | ART-83 | 디테일 72–76 → 97–101 |
| `asgard_aegis_ram-idle-v1` | `art/bakeoff/monsters/asgard_aegis_ram-idle-v2.png` | ART-83 | 디테일 75–81 → 92–97 |
| `vanaheim_seed_sprite-attack-v1` | `art/bakeoff/monsters/vanaheim_seed_sprite-attack-v2.png` | ART-83 | 앞으로 뻗는 거리 5 → 10px |
| `vanaheim_vine_hound-{idle,walk,windup,attack,hurt,defeat}-v1` | `art/bakeoff/monsters/vanaheim_vine_hound-<같은 줄>-v2.png` (6줄) | ART-83 | 녹색 보정 뒤 잎 가장자리 자글거림을 줄임 |
| `alfheim_moon_moth-windup-v1` | `art/bakeoff/monsters/alfheim_moon_moth-windup-v2.png` | ART-83 | F2 크기 대기 대비 0.896 → 1.020 |
| `jotunheim_storm_wisp-hurt-v1` | `art/bakeoff/monsters/jotunheim_storm_wisp-hurt-v2.png` | ART-83 | 움찔하는 모양 변화가 커짐(돌–핵 간격 5 → 16px) |
| `niflheim_glacier_wolf-attack-v1` | `art/bakeoff/monsters/niflheim_glacier_wolf-attack-v2.png` | ART-83 | 도약 정점이 F4 → F3(가운데) |
| `<위 8종>_sheet-v1` (6줄 조립본) | `art/bakeoff/monsters/<id>_sheet-v2.png` | ART-83 | 바꾼 줄만 v2로 다시 조립 |
| (게임 시트) `smash-nine-prototype/assets/art/monsters/<id>_sheet.png` 15종: moth, stag, ram, raven, imp, golem, wisp, slinger, mossling, boar, wolf, cog_drone, gear_beetle, guardian, oracle | `art/bakeoff/monsters/legacy/<id>_sheet-fix1.png` | ART-87 | QA-23 L01–L30의 절단·테두리·섞인 발사 효과 수리(모션 뷰어 후보가 아니라 지금 게임 시트의 수리본) |
| `alfheim_moon_moth-defeat-v1` | `art/bakeoff/monsters/alfheim_moon_moth-defeat-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `asgard_aegis_ram-windup-v1` | `art/bakeoff/monsters/asgard_aegis_ram-windup-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `asgard_runic_raven-windup-v1` | `art/bakeoff/monsters/asgard_runic_raven-windup-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `jotunheim_rune_golem-attack-v1` | `art/bakeoff/monsters/jotunheim_rune_golem-attack-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `jotunheim_rune_golem-defeat-v1` | `art/bakeoff/monsters/jotunheim_rune_golem-defeat-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `jotunheim_rune_golem-hurt-v1` | `art/bakeoff/monsters/jotunheim_rune_golem-hurt-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `jotunheim_rune_golem-walk-v1` | `art/bakeoff/monsters/jotunheim_rune_golem-walk-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `jotunheim_storm_wisp-attack-v1` | `art/bakeoff/monsters/jotunheim_storm_wisp-attack-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `midgard_rooftop_slinger-attack-v1` | `art/bakeoff/monsters/midgard_rooftop_slinger-attack-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `midgard_rooftop_slinger-defeat-v1` | `art/bakeoff/monsters/midgard_rooftop_slinger-defeat-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `muspelheim_magma_boar-attack-v1` | `art/bakeoff/monsters/muspelheim_magma_boar-attack-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `muspelheim_magma_boar-defeat-v1` | `art/bakeoff/monsters/muspelheim_magma_boar-defeat-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `muspelheim_magma_boar-windup-v1` | `art/bakeoff/monsters/muspelheim_magma_boar-windup-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `niflheim_frost_owl-defeat-v1` | `art/bakeoff/monsters/niflheim_frost_owl-defeat-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `svartalfheim_cog_drone-defeat-v1` | `art/bakeoff/monsters/svartalfheim_cog_drone-defeat-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `vanaheim_seed_sprite-defeat-v1` | `art/bakeoff/monsters/vanaheim_seed_sprite-defeat-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `yggdrasil_root_guardian-defeat-v1` | `art/bakeoff/monsters/yggdrasil_root_guardian-defeat-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `yggdrasil_root_oracle-windup-v1` | `art/bakeoff/monsters/yggdrasil_root_oracle-windup-v2.png` | ART-88 | 4px 여백 확보(칸 안에서 이동, 일부 줄은 줄 배율을 조금 줄임) |
| `niflheim_glacier_wolf-hurt-v1` | `art/bakeoff/monsters/niflheim_glacier_wolf-hurt-v2.png` | ART-88 | 들어 올린 머리 윗부분이 잘린 것을 원본에서 다시 자름(직선 8 → 5px) |
| `vanaheim_seed_sprite-attack-v1`, `vanaheim_vine_hound-defeat-v1` | 위 ART-83 표의 같은 v2 파일(ART-88이 여백만 더 고침) | ART-88 | 4px 여백 |
| `<id>_sheet-v1` 조립본: raven, golem, slinger, boar, owl, cog_drone, guardian, oracle(새 v2) + moth, ram, wisp, wolf, seed_sprite, hound(ART-83 v2 다시 맞춤) | `art/bakeoff/monsters/<id>_sheet-v2.png` | ART-88 | 바뀐 줄로 다시 조립(14장) |
| (게임) `rio_female-mana_combo-v1` | `art/bakeoff/rio/rio_female-mana_combo-v2.png` | ART-86 | F5 칼끝 복원, F6 떨어진 칼 조각 제거(QA-23 L14) |
| (게임) `nova_male-walk-v2` | `art/bakeoff/nova/nova_male-walk-v3.png` | ART-86 | F3 장갑·정강이 다시 그림(L09) |
| (게임) `rio_female-walk-v3` | `art/bakeoff/rio/rio_female-walk-v4.png` | ART-86 | F4 검 방향을 F3·F5와 맞춤(L10) |
| (게임) `rio_male-walk-v1` | `art/bakeoff/rio/rio_male-walk-v2.png` | ART-86 | 걷기 전체를 대기 크기로(−18% → 맞춤, L11) |
| (게임) `nova_female-gravity_brake-v1` | `art/bakeoff/nova/nova_female-gravity_brake-v2.png` | ART-86 | F4–F6 발을 y152로(L34). 얼굴 검사 보류 표시 |
| (게임) `frey-attack-v4` (기본 시트 예비 공격) | `art/bakeoff/frey/frey-attack-v5.png` | ART-86 | F3–F6 머리 0.92 → 기준 안(L37) |
| `svartalfheim_cog_drone-projectile-v1` | `art/bakeoff/monsters/svartalfheim_cog_drone-projectile-v2.png` | ART-85 | 4장 90° 회전 → 8장 45° 회전 |
| `niflheim_frost_owl-projectile-v1` | `art/bakeoff/monsters/niflheim_frost_owl-projectile-v2.png` | ART-85 | 얼음 본체 고정, 꼬리만 조금 반짝임 |
| `slam_shockwave-v1` (골렘·수호자 공용) | `art/bakeoff/monsters/yggdrasil_root_guardian-shockwave-v1.png` (수호자 전용, 새 것) | ART-85 | 수호자 색으로 따로 그림. 골렘은 `slam_shockwave-v1` 그대로 |
| `yuki_face-hurt-v1` | `art/bakeoff/yuki/yuki_face-hurt-v2.png` | ART-84 | 감은 눈·벌린 입·땀방울로 아픔이 더 읽힘 |
| `rio_male_face-hurt-v1` | `art/bakeoff/rio/rio_male_face-hurt-v2.png` | ART-84 | 피곤한 얼굴이 아니라 아픈 얼굴로 |
| `<stem>_face-shadow-v1` (8폼: frey, luna, luna_brave, yuki, nova_male, nova_female, rio_male, rio_female) | `art/bakeoff/<folder>/<stem>_face-shadow-v2.png` | ART-84 | 피부·금속 더 어둡게, 눈빛 상대적으로 강조(Yuki 부적 낮춤, Rio 여 눈 강화) |
| `yggdrasil_root_guardian-attack-v1` | `art/bakeoff/monsters/yggdrasil_root_guardian-attack-v2.png` | ART-90 | F1 팔을 조금 낮춰 위 여백 4px |
| (ART-88 v2) `yggdrasil_root_guardian-defeat-v2`, `vanaheim_vine_hound-*-v2`, 두 `_sheet-v2` | 같은 파일(ART-90에서 고쳐 씀) | ART-90 | 수호자 F1 여백, 사냥개 잔점 정리 |
| (ART-87) `legacy/alfheim_moon_stag_sheet-fix1` | 같은 파일(ART-90에서 고쳐 씀) | ART-90 | 공격 4장 모두 다른 칸, 다른 줄과 같은 크기 |
| `frey-jump-v2` | `art/bakeoff/frey/frey-jump-v3.png` | ART-89 | 줄 전체 새로 그림: 도약(뒷다리 뻗음)·상승(무릎 접음)·정점(다리 풂, 망토 수평) 구분. 얼굴 0.971–1.016 |
| `luna_brave-hurt-v2` | `art/bakeoff/luna/luna_brave-hurt-v3.png` | ART-89 | 머리·상체 뒤로 젖힘 → 웅크림 → 가드 복귀. F3 얼굴 1.034(F1·F2는 감은 눈) |
| `yuki-victory-v1` | `art/bakeoff/yuki/yuki-victory-v2.png` | ART-89 | 부적 튕김 → 부채 반개방 → 완전 개방 → 턱 앞. 얼굴 0.966–0.985 |
| `luna-victory-v1` (ART-82 `luna-victory-v2`의 다음) | `art/bakeoff/luna/luna-victory-v3.png` | ART-89 | 한 방향 지팡이 회전, 같은 손, F5 별 자세·F6 윙크. 얼굴 0.971–1.003 |
| `nova_female-victory-v1` (ART-82 `nova_female-victory-v2`의 다음) | `art/bakeoff/nova/nova_female-victory-v3.png` | ART-89 | 두 잽이 서로 다른 팔, F4–F6 주먹 올린 채 유지·윙크. 얼굴 폭 1.000 |
| `frey-victory-v1`, `luna_brave-jump-v2`, `luna_brave-fall-v3`, (ART-82) `rio_male-victory-v2`, (ART-86) `rio_male-walk-v2` | 새 버전 없음 | ART-89 | 얼굴 기준이나 동작 목표를 못 맞춰 내지 않음. 지금 후보 그대로 |

## 모은 브랜치

- `after-cp/art-sprite` (`51b6ada6`; 그림 카드만 합친 시점은 `3449a1db`): 메인 저장소에는 fetch만 했다(merge 없음, main은 `c51a417f` 그대로). 체크포인트에서 시작해 ART-81~90 열 카드를 모두 합쳤다(ART-83·87·88은 ART-90을 거쳐, ART-82는 ART-89를 거쳐서도 들어옴). 충돌 없음. 그 위에 비교 뷰어 도구(TOOL-04, `codex/tool-04` `d044bab5`)를 합쳤다.
- 체크포인트 대비 1,040파일: `art/bakeoff/` 221, `reports/codex-art-81`~`90`, `design/tasks/` 카드 20. 바뀐 기존 파일은 후보 json 43개(빠진 `cell`·`feet`·`loop` 칸 추가)뿐이고 지운 파일은 없다. `smash-nine-prototype/`·`tools/` 변경 없음.
- 적용할 때는 이 브랜치 하나를 쓰면 된다(카드별 "어느 브랜치를 쓸지" 주의는 여기에 모두 반영됨). 이 브랜치는 **후보 파일을 늘릴 뿐 게임 시트를 바꾸지 않는다**. 사용자가 고른 것만 게임에 넣는 일은 적용 단계에서 따로 한다.

## 비교 뷰어 (후보 고르기)

- 비교 뷰어 URL: https://claude.ai/artifact/GQvLqKwLAGoPsQzVSmAAaA (새 Artifact, 사용자 전용. 기존 모션 뷰어 https://claude.ai/artifact/188Ryqb526Ue58MDf4BnbU 는 그대로 둠)
- 사용자 지시(2026-10-25, 점검 세션 전달): "기존 모션 뷰어는 그대로 두고, after-cp/art-sprite의 새 버전을 옛 버전 옆에 실은 별도 뷰어(새 URL)를 … 만들게 해줘. 후보는 거기서 한 번에 고를게."
- 실린 줄: 전체 222줄(캐릭터 8폼 58, 몬스터 108, 투사체 9, 대화 초상화 32, 옛 몬스터 시트 수리본 15) · 옛·새 나란히 64줄 · 게임 시트 수리본 비교 21(ART-86 캐릭터 6줄 + 옛 몬스터 시트 15) · 새 버전 없음 표시 5줄. 파일 326개(23.8MB).
- 줄마다 지금 게임 그림과 모든 버전을 같은 속도로 나란히 재생하고, "무엇이 달라졌나"는 위 대응표의 문장(`tools/compare_viewer/changes.json`)을 보여 준다. 고르기는 줄마다 하나(버전 하나 또는 "둘 다 아님")와 메모.
- 고른 기록: 이 새 Artifact의 DB `candidate_picks`, 문서 id `<kind>~<id>~<row>`(kind: fighter·monster·projectile·face·legacy_sheet), `choice`(`v3`·`fix1`·`none`)와 `file`(고른 그림의 저장소 경로). 리드는 `ArtifactData list candidate_picks`(URL은 위 비교 뷰어)로 읽고, `picked: true`만 지금 선택으로 본다.
- 도구: `tools/compare_viewer/`(`after-cp/art-sprite`에 있음). 다시 만들 때는 클론에서 `node tools/compare_viewer/build.mjs` → `dist/`를 같은 파일 경로로 다시 게시(이 세션) 또는 위 URL로 게시.
- 확인: 오프라인 검사 14개 통과. 리드가 같은 HTML을 로컬에서 열어 나란히 재생·같은 속도·발 기준선·375px 폭(가로 넘침 없음, 두 칸씩)을 확인했고, 리뷰에서 고친 것 3가지(한 장짜리 게임 줄의 속도 1 → 후보 속도, 기본 크기 1.5배, 안 고른 줄 보기에서 고른 줄이 바로 사라지던 것). DB는 페이지 형식 그대로 기록 1개를 쓰고 읽은 뒤 지웠다(지금 비어 있음). 게시된 페이지 안에서 직접 눌러 저장·새로고침 복원하는 확인은 내장 브라우저가 claude.ai에 로그인되어 있지 않아 아직 못 함.

## 남은 것

사용자 확인이 필요한 것:
- 후보 고르기: 위 비교 뷰어에서 한 번에 고른다.
- 옛 몬스터 시트 수리본(ART-87·90)은 새 6줄 후보를 고르지 않은 몬스터에만 필요하다.
- 그림자 초상화 v2(ART-84)는 어두워서 세부가 덜 보인다. v1과 나란히 보고 고를 것.

두 방법으로 해도 안 돼서 멈춘 것(같은 방법으로 다시 돌려도 실패할 가능성이 큼):
- ART-89에서 못 낸 5줄(Frey 승리, 브레이브 도약·낙하, Rio 남 승리·걷기). 프레임 단위(ART-82)와 줄 전체(ART-89) 모두 얼굴 기준이나 동작을 못 맞췄다. 지금 후보를 그대로 쓸지, 다른 방법을 쓸지는 사용자 판단.
- Nova 남 meteor_kick 머리 약 6% 큼(지금 게임 줄). 줄 전체를 줄이면 몸도 작아진다.

적용 단계에서 할 것(코드 변경이라 이번엔 하지 않음):
- 수호자 충격파(ART-85)를 고르면 `RealmMonster.gd`에 몬스터별 충격파 파일 연결이 필요하다.
- 기존 모션 뷰어를 이 브랜치로 다시 만들면 `yggdrasil_root_guardian-shockwave-v1.png`를 수호자의 "새 줄"로 잘못 읽는다(이름 규칙이 몬스터 줄과 같음). 비교 뷰어는 투사체 줄로 따로 처리했다. 모션 뷰어를 다시 게시할 때 함께 고칠 것.

## 새 동작 미리 만들기 (10-28)

- 사용자 지시(2026-10-28 14:30, 점검 세션 전달): "Codex에게 스프라이트를 더 만들게 하여 아직 게임에 없는 더 많은 행동 패턴 동작을 생성해볼것. 이후 사용 할수도 있으니 미리 만들어두는 것이고, 오늘 오후 4시에 종료. 그 동안 최대한 Codex 사용량을 1%까지 만들고, 작업 도중 Codex 사용량이 100%가 되면 남은 Codex 사용량 90%까지 진행 한 뒤 작업 중단."
- 이 세션 영역: 일반 행동 동작(스킬 동작은 캐릭터 스킬 세션). 게임에도 후보(`art/bakeoff`)에도 없는 줄만.
- 시작 14:35, Codex 사용량 used 62%(남은 38%, 주간 초기화 11-02 14:59).
- 유닛 2개(동시 최대 2), 둘 다 `after-cp/art-sprite`(`51b6ada6`)에서 시작, 15:45 이후 새 줄 시작 안 함, 15:57에 강제 종료:
  - ART-91 (`art-a`, `codex/art-91`): 지금 줄 목록과 빠진 동작 우선순위 정리(`reports/codex-art-91/inventory.md`) → 몬스터 18종 `appear`(등장) → `rage`(분노) → 남으면 `sleep`·`flee`. 96칸·발 72.
  - ART-92 (`art-b`, `codex/art-92`): 8폼 `dodge_roll`(회피 구르기, 128) → `taunt`(도발, 192) → `stun`(기절, 128) → `crouch`(숙이기, 128) → 남으면 `run_start`. 동작 하나씩 8폼 전부.
- 방법: ART-89와 같은 줄 전체 한 번에 그리기, 대기 그림 기준 한 배율, 6프레임, 효과 그리지 않음. 검사: 얼굴 0.96–1.04, 4px 여백, 칸 경계 넘김 없음(고정 폭 슬라이싱), 발 위치, 6장 서로 다름. json에 `cell`·`feet`·`loop`.
- 결과 브랜치: `after-cp/new-motions-art`(메인 저장소에는 fetch만). 리드가 4배로 본 줄만 아래 표에 적는다.

| 폼 | 동작 | 파일 | 프레임 수 | 검사 결과 | 비고 |
|---|---|---|---|---|---|
| 몬스터 alfheim_moon_moth | appear (등장) | `art/bakeoff/monsters/alfheim_moon_moth-appear-v1.png` | 6 (10fps, 반복 없음, 96/72) | 통과 — 리드 3배 확인: 최소 여백 12px, 칸 경계 넘김 없음, 6장 다름, 반투명 0, 색·모양 idle과 같음, 효과 없음 | 접힌 날개 → 펼침 → 부유 준비. F4–F6 정착 움직임은 작음 |
| 몬스터 asgard_runic_raven | appear | `art/bakeoff/monsters/asgard_runic_raven-appear-v1.png` | 6 (10fps, 반복 없음, 96/72) | 통과 — 여백 5px, 경계 넘김 없음, 6장 다름, 반투명 0, 문양·색 idle과 같음 | 웅크림 → 날개 크게 폄(F4) → 부유 준비. 날개 여백 때문에 몸을 2.5px 오른쪽에 둠 |
| Luna | dodge_roll (회피 구르기) | `art/bakeoff/luna/luna-dodge_roll-v1.png` | 6 (14fps, 반복 없음, 128/120) | 통과 — 여백 7px, 경계 넘김 없음, 발 y120, 6장 다름, 얼굴 F1 1.002·F6 1.031(나머지는 얼굴이 안 보임), 모자·리본·별 지팡이·옷 idle과 같음 | 웅크림 → 머리 숙임 → 거꾸로 → 등 구르기 → 낮은 착지 → 준비. 구르는 방향(앞/뒤)은 재생으로 볼 것 |
| Nova 남 | dodge_roll | `art/bakeoff/nova/nova_male-dodge_roll-v1.png` | 6 (14fps, 반복 없음, 128/120) | 통과 — 여백 7px, 경계 넘김 없음, 발 y120, 6장 다름, 얼굴 폭 1.000(F1·F6). 리드 재측정: 얼굴 피부 면적 idle 140px ↔ F1 137·F6 138(같은 크기) | 낮은 가드 → 몸 접기 → 거꾸로 → 등 구르기 → 무릎 착지 → 가드. 전체 높이가 낮은 것은 웅크린 가드 자세 때문(Codex 보조 머리 지표 0.90–0.92는 자세 영향) |
| Nova 여 | dodge_roll | `art/bakeoff/nova/nova_female-dodge_roll-v1.png` | 6 (14fps, 반복 없음, 128/120) | 통과 — 여백 7px, 경계 넘김 없음, 발 y120, 6장 다름, 얼굴 폭 1.000(F1·F6), 리드 재측정 얼굴 피부 idle 135px ↔ F1 145·F6 135 | 낮은 준비 → 웅크림 → 거꾸로 → 등 구르기 → 무릎 착지 → 일어섬. F6은 idle보다 곧게 선 자세(키 100 ↔ 89) |
| Rio 여 | dodge_roll | `art/bakeoff/rio/rio_female-dodge_roll-v1.png` | 6 (14fps, 반복 없음, 128/120) | 통과 — 여백 7px, 경계 넘김 없음, 발 y120, 6장 다름, 얼굴 폭 1.000(F1·F6), 리드 재측정 얼굴 피부 idle 72px ↔ F1 71·F6 72 | 검을 같은 손에 든 채 구름. 포니테일·갑옷·망토·수정검 idle과 같음. F6 칼끝이 발 높이에 가까움(재생으로 볼 것) |
| 몬스터 jotunheim_rune_golem | appear | `art/bakeoff/monsters/jotunheim_rune_golem-appear-v1.png` | 6 (10fps, 반복 없음, 96/72) | 통과 — 여백 4px(최소선), 경계 넘김 없음, 발 y72, 6장 다름, 얼굴 폭 0.989–1.011 | 접힌 바위 몸 → 앞주먹 짚고 일어남 → 준비 |
| 몬스터 niflheim_frost_owl | appear | `art/bakeoff/monsters/niflheim_frost_owl-appear-v1.png` | 6 (10fps, 반복 없음, 96/72) | 통과 — 여백 12px, 경계 넘김 없음, 발 y72, 6장 다름, 머리 크기 0.990–1.021, 번짐 0 | 웅크림 → 일어섬 → 날개 반쯤 폄(F4–F5) → 준비 |
| 몬스터 svartalfheim_gear_beetle | appear | `art/bakeoff/monsters/svartalfheim_gear_beetle-appear-v1.png` | 6 (10fps, 반복 없음, 96/72) | 통과 — 여백 8px, 경계 넘김 없음, 발 y72, 6장 다름, 외피 크기 0.988–1.019, 번짐 0 | 다리 접은 낮은 몸 → 다리 펴고 일어섬. F4–F6은 idle보다 다리를 조금 더 펴 높음(53–54 ↔ 50) |
| Frey | dodge_roll | — | — | 실패(2회 생성) — 1차 F6 얼굴 폭 1.043, 2차 F2가 칸 오른쪽 경계에 닿음 | 납품 안 함 |
| Luna | taunt | — | — | 실패(2회 생성) — 1차 별 지팡이가 칸 경계를 넘고 손이 바뀐 듯함, 2차 F1/F2 얼굴 폭 0.929·F4 눈 간격 1.071 | 납품 안 함 |
| Brave Luna | taunt | — | — | 실패(2회 생성) — F2 얼굴 폭 1.071, F5·F6 눈 간격 0.954–0.956 | 납품 안 함. 15:45 직후(약 15:46)에 시작한 줄 |

### 결과 (16:00 종료)

- 새 동작 **11줄**(66프레임), 리드가 모두 확대해 보고 통과: 캐릭터 `dodge_roll` 4줄(Luna, Nova 남·여, Rio 여), 몬스터 `appear` 7줄(달나방, 룬 까마귀, 불씨 임프, 룬 골렘, 폭풍 정령, 서리 올빼미, 톱니 딱정벌레).
- 납품 안 된 줄 10: 유닛 검사 실패 9(구르기 4 — Frey·Brave Luna·Rio 남·Yuki, 도발 3 — Frey·Luna·Brave Luna, 등장 2 — 달사슴·방패 산양), 리드 불합격 1(톱니 드론 등장 — 없는 집게 다리). 실패는 대부분 얼굴 비율 0.96–1.04 또는 칸 경계 닿음.
- 만들지 못한 것: 도발 나머지 5폼, `stun`·`crouch`·`run_start` 8폼, 몬스터 `appear` 나머지 8종, `rage`·`sleep`·`flee`. 우선순위 목록은 `reports/codex-art-91/inventory.md`(캐릭터 18종 동작, 몬스터 4종 동작).
- 브랜치: `after-cp/new-motions-art` `eaf9e16e`(= `after-cp/art-sprite` + `codex/art-92` `0b06b378` + `codex/art-91` `88673cd7`), 메인 저장소에는 fetch만. main은 `c51a417f` 그대로.
- 멈춘 이유: **16:00 시간 제한**. Codex 사용량: 시작 14:35 used 62% → 15:36쯤 used 83%(남은 17%)에서 **주간 초기화**(다음 초기화 11-04 15:35) → 멈출 때 15:55 used 6%(**남은 94%**). 초기화 뒤 90% 선(used 10%)에는 닿지 않았다. 이 수치는 같은 시간에 Codex를 돌린 캐릭터 스킬 세션 사용량도 포함한다.
- 15:57에 강제로 끊긴 유닛은 없음(두 유닛 모두 보고서를 쓰고 스스로 끝냄).
| Frey | taunt (도발) | — | — | 실패(2회 생성) — 1차 칸 경계 닿음, 2차 F3 눈 간격 1.050·F5/F6 얼굴 폭 1.057 | 납품 안 함 |
| 몬스터 svartalfheim_cog_drone | appear | — | — | **리드 검토 불합격** — Codex는 통과로 냈지만, 몸 아래 집게 다리를 새로 그렸다(idle·walk·windup·attack·defeat·게임 시트 어디에도 없음). F6에도 남아 있어 idle로 넘어갈 때 사라진다 | 커밋하지 않음(클론의 `art/raw/monsters-91/rejected/`로 옮김) |
| Rio 남 | dodge_roll | — | — | 실패(2회 생성) — 1차 검이 칸 경계를 넘음, 2차 F2 얼굴 폭 0.817 | 납품 안 함 |
| Yuki | dodge_roll | — | — | 실패(2회 생성) — 1차 칸 경계 닿음, 2차 디테일 67–71(<79)·얼굴 눈 간격 0.85/폭 1.083 | 납품 안 함 |
| 몬스터 ember_imp | appear | `art/bakeoff/monsters/ember_imp-appear-v1.png` | 6 (10fps, 반복 없음, 96/72) | 통과 — 여백 6px, 경계 넘김 없음, 발 y72, 6장 다름, 얼굴 폭 0.969–1.039. 처음 납품본은 초록 번짐 8px로 Codex가 스스로 철회 → 번짐 제거 후 다시 납품, 리드 재측정 초록 픽셀 0 | 낮은 웅크림 → 일어섬. F5에서 다리를 펴 idle보다 8% 높게 섰다가 F6 정착 |
| 몬스터 jotunheim_storm_wisp | appear | `art/bakeoff/monsters/jotunheim_storm_wisp-appear-v1.png` | 6 (10fps, 반복 없음, 96/72) | 통과 — 여백 15px, 경계 넘김 없음, 6장 다름, 돌 크기 idle 대비 0.985–1.026, 번짐 0 | 닫힌 룬돌이 열리며 핵이 드러남. F6이 idle보다 덜 벌어짐(높이 52 ↔ 56) — idle로 넘어갈 때 작게 튈 수 있음 |
| Brave Luna | dodge_roll | — | — | 실패(2회 생성) — 배율 하나로 얼굴 폭(1.071)과 눈 간격(0.913)을 함께 맞출 수 없음 | 납품 안 함 |
| 몬스터 alfheim_moon_stag | appear | — | — | 실패(2회 생성) — 모양이 idle과 달라짐 | 납품 안 함 |
| 몬스터 asgard_aegis_ram | appear | — | — | 보류 — 크기 확인 못 함 | 납품 안 함 |
