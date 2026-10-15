# CODEX-DOC-01 결과

`design/SKILLS.md`에 2026-10-15 코드 기준으로 Frey 15행, Luna 23행, Yuki 11행, Nova 14행, Rio 13행을 정리했다. 지상·공중 J 분기, K/L, 궁극기 재입력, 패시브/특성, 공용 Guard까지 총 76행이다. 캐릭터 행의 이펙트 상태는 그림 70, 도형 0, 없음 1, 공용 5다.

Godot은 실행하지 않았다. 아래 검증은 소스 정적 대조 결과다.

## 코드와 캐릭터 문서의 차이

### 직접 충돌

- `Rio.md`의 Infinity Overdrive 첫 설명은 검마다 피해 6이라고 적지만, `Rio.gd`는 앞 5자루 11 `[OVERDRIVE_SWORD_DAMAGE]`, 마지막 18 `[OVERDRIVE_LAST_DAMAGE]`이다. 같은 `.md` 아래의 “궁극기 조정” 문단은 코드와 맞는다.
- `Rio.md`는 보석 검 사거리를 약 600px이라고 적지만, 코드의 투사체는 속도 `980×COMBAT`와 수명 0.62초이므로 장애물이 없을 때 약 911.4 화면 px를 간다. 자동 표적 탐색도 `720×COMBAT=1080` 화면 px다.
- `Luna.md`는 변신 순간 “반경 120 폭발”이라고 부르지만, 코드는 원형 반경 판정이 아니라 기본 `240×192` 직사각형 쓸기 판정을 만들고 `COMBAT`을 적용해 실제 `360×288`이 된다. `TRANSFORM_BURST_RADIUS=120`은 그 직사각형을 만드는 기준값이다.

### 기본 단위만 적어 런타임 화면 거리와 달라지는 곳

- `Rio.md`의 J 3타 검기 약 150px는 배율 전 비행 거리 153.6px와 가깝다. 현재 코드는 `640×COMBAT×0.24=230.4` 화면 px다.
- `Rio.md`의 K 최대 200px는 `[BLINK_DISTANCE]` 기본값이다. 현재 실제 최대 이동은 `200×WORLD=300` 화면 px다.
- `Nova.md`의 운동량 170~700은 배율 전 기준이다. 상수에 `MOVE=1.2`가 이미 곱해져 실제 강화 구간은 204~840이다.

Frey와 Yuki의 기술 설명에서는 동작이나 수치의 직접 충돌을 찾지 못했다. 위 차이는 `design/SKILLS.md`에서 코드 기준값과 적용 배율을 함께 써서 해소했다.

## 입력 분기 확인

- 공통: `PlayerBase._unhandled_input` → `basic_attack`/`skill_one`/`skill_two`/`ultimate` → `perform_basic_attack`, `perform_skill_one`, `perform_skill_two`, `perform_ultimate`를 따라갔다. 재입력은 `try_skill_one_followup`, `try_skill_two_followup`, `try_ultimate_followup`까지 확인했다. J는 `_get_basic_attack_type`의 지상 `neutral/side/up/down`, 공중 `air_side/air_up/air_down`을 확인했다.
- Frey: 위·공중 위, 아래·공중 아래, 공중 옆, 기본 3연타, K, L, L 재입력, 지상/공중 I, 추격 패시브를 모두 행으로 만들었다.
- Luna: 평상시 J 6변형과 K/L/I, Brave J 8행(3연타 포함), Brave K, 지상/공중 L, I 재입력, 별빛 충전을 모두 넣었다.
- Yuki: J 6변형, K, 봉인부 유/무의 L 두 분기, I를 모두 넣었다.
- Nova: J 6변형, K, L, I 3단계, 투석 중 K 재지정, 운동량을 모두 넣었다.
- Rio: J 3연타와 방향별 5변형, K, L, I, 공중 추가 점프를 모두 넣었다.
- 별도 공용 대시 입력이나 함수는 현재 `PlayerBase.gd`에 없다. `skill_dash_velocity`는 캐릭터 기술의 이동 구현에만 쓰인다. 대신 모든 캐릭터 표에 공용 Guard/패리를 넣었다.

## 캐릭터별 수치 대조

각 항목은 문서에 적은 값과 코드의 동일 값을 다시 확인한 것이다.

### Frey

1. K: `[DASH_SPEED]=760`, `[DASH_TIME]=0.18`.
2. L: 피해 15, 강제 발사 `(105,-760)`, 재입력 `[RISING_FOLLOWUP_WINDOW]=0.18`.
3. 강스파이크: 피해 18, 넉백 700, 판정 76×48.
4. I: `[ULTIMATE_WAVE_DAMAGE]=26`, `[ULTIMATE_WAVE_REACH]=240`, 여진 피해 10/지연 0.28초.
5. 추격: `[PURSUIT_TIME]=1.0`, `[PURSUIT_SPEED]=1.15`, 표식 높이 118.

### Luna

1. 변신: `[TRANSFORM_MOTION_TIME]=1.0`, 폭발 시점 `8/12초`, 지속 6초.
2. 변신 폭발: 기준 120으로 240×192 판정, 피해 14.
3. K 폭발: 피해 12, 넉백 390, 기본 판정 96×82.
4. L: 반경 90, 피해 12, 넉백 405, 활성 0.24초.
5. Heart Laser: 틱 피해 3.4, 간격 0.22초, 기본 길이/높이 560/112.

### Yuki

1. 지상 직선 J: 피해 6, 넉백 190, 속도 `660×COMBAT`, 수명 0.95초.
2. K: 설치 기본 거리 145, 최대 2개, 수명 5초.
3. L: 흡입/폭발 반경 `135×COMBAT`/`148×COMBAT`, 피해 11, 활성 0.58초.
4. 빈 L: 좌우 피해 6, 넉백 260, 판정 58×62.
5. I: 반경 `205×COMBAT`, 예고 0.7초, 활성 2.35초, 피해 4/16, 마지막 기절 1.2초.

### Nova

1. 운동량 구간: `170×MOVE`부터 `700×MOVE`, 즉 204~840.
2. K: 0.22초, 가속 `5400×MOVE`, 최대 속도 `760×MOVE`.
3. L: 반경 58→112, 피해 6→15, 넉백 210→640.
4. 궁 핵: 흡입 반경 `230×COMBAT`, 힘 240; 붕괴 반경 `118×COMBAT`, 피해 18.
5. 최종 폭발: 반경 124→170 `×COMBAT`, 피해 34→46, 넉백 700→940.

### Rio

1. J 연계: 근접 피해 7/8/7, 검기 피해 6·속도 `640×COMBAT`·수명 0.24초.
2. K: `[BLINK_DISTANCE]=200`, 실제 `×WORLD`, 준비/후딜 0.06/0.20초, 피해 10.
3. L: 지속 0.5초, 피해 배율 0.5, 쿨 3초, 헛침 후딜 0.32초.
4. L 반격: 피해 `min(6+3×횟수,15)`, 넉백 `min(320+흡수넉백×0.5,820)`.
5. I: 6자루, 공전 0.55초, 간격 0.07초, 피해 11/마지막 18.

## `assets/art/effects/` 파일 대조

런타임 기술 행 또는 공용 효과 설명에서 최종 파일을 모두 이름으로 연결했다. `.import`는 Godot 메타데이터라 별도 효과 파일로 세지 않았다.

공격자별 최종 피격 그림은 `hit/frey_hit.png`, `hit/luna_hit.png`, `hit/luna_brave_hit.png`, `hit/nova_hit.png`, `hit/rio_hit.png`, `hit/yuki_hit.png`다. 캐릭터별 파일을 못 읽으면 `hit_spark.png`가 공용 폴백이다. `skill/attack_afterimage.png`는 `Attack._spawn_trail_afterimage`가 전용 공격 그림이 없는 쓸기 판정에 쓰는 공용 잔상이다.

### 런타임에서 참조되지 않는 파일

- `nova_gravity_orb.png`: README와 아트 프리뷰에서만 나오며 제품 코드 참조가 없다.
- 생성 원본 12개: `hit/frey_hit_source.png`, `hit/luna_hit_source.png`, `hit/luna_brave_hit_source.png`, `hit/nova_hit_source.png`, `hit/rio_hit_source.png`, `hit/yuki_hit_source.png`, `skill/common_skill_fx_source.png`, `skill/luna_skill_fx_source.png`, `skill/nova_skill_fx_source.png`, `skill/rio_skill_fx_source.png`, `skill/yuki_grand_ward_source.png`, `realm/realm_markers_source.png`. 최종 런타임 그림을 다시 만드는 보존 원본이다.

### 캐릭터 기술 밖에서 쓰는 파일

- `realm/seal_barrier.png`, `realm/collapse_cracks.png`, `realm/warning_edge.png`는 캐릭터 기술이 아니라 `scripts/realms/RealmWorld.gd`가 렐름 잠금·붕괴·경고에 사용한다. 미사용 파일이 아니다.

## 불명확하거나 주의할 점

- 표의 “기술 수”는 독립 입력 이름이 아니라 코드 분기/결과 행 수다. 그래서 Luna의 두 형태와 궁 재입력, Nova의 3단 궁극기처럼 같은 버튼의 서로 다른 결과도 따로 센다.
- 이펙트 상태는 해당 행에 전용 그림이 하나라도 있으면 `그림`으로 분류했다. Nova 궁극기 공전처럼 전용 핵 그림과 절차적 예고선이 같이 있는 행도 `그림`이다.
- Rio J 3타의 마력 검기는 `rio_mana_wave.png`로 비행하지만 `impact_vfx`가 없고 `Projectile._on_body_entered`도 `source.on_attack_landed`를 부르지 않아 적중 순간 별도 스파크 없이 사라진다. 후속 이펙트 작업 목록에 넣었다.
- Nova 궁극기의 흡입 중심은 `ultimate_center`인데, 핵 그림과 핵 붕괴 판정은 `ultimate_center + Vector2(0,-32)`에 놓인다. 그림과 게임 효과 중심이 32px 어긋나므로, 새 그림을 만들기 전에 코드 위치 계약을 하나로 정해야 한다.
- 공격 범위는 대부분 기본 판정에 `COMBAT`을 곱하지만, 몸 중심 `Vector2(0,-32)`은 그대로 두고 그 중심에서 거리만 키운다. 문서의 “실제 화면 크기”는 이 규칙을 반영했다.
- 코드만 읽는 작업이므로 애니메이션과 판정이 실제 화면에서 시각적으로 정확히 포개지는지는 확인하지 않았다.

