# CODEX-ART-66 결과

기본 공격(J)에 쓰이는 13개 이펙트를 새 6프레임/192px 몸체의 세부 수준에 맞춰 후보로 다시 그렸다. 제품 폴더는 수정하지 않았으며, 채택 전 후보는 `art/bakeoff/effects/`에만 있다.

## 납품

- Frey: `frey_slash-v1.png`
- Luna: `luna_slash-v1.png`, `luna_star_bloom-v1.png`
- Brave Luna: `luna_brave_slash-v1.png`
- Yuki: `yuki_talisman-v1.png`, `yuki_slash-v1.png`, `yuki_l-v1.png`
- Nova: `nova_slash-v1.png`, `nova_vector_streak-v1.png`, `nova_impact_star-v1.png`, `nova_gravity_burst-v1.png`
- Rio: `rio_slash-v1.png`, `rio_mana_wave-v1.png`

각 PNG 옆의 JSON은 교체 대상, 프레임 수, FPS를 기록한다. 생성 원본은 `art/raw/fx-66/`에 복사했으며 커밋 대상이 아니다.

## 제작과 검증

`build_fx66.py`가 ImageGen 원화를 정규화했다. 생성 원화의 넓은 반투명 후광은 밝은 코어 주변의 한 논리 픽셀 외곽만 남기고 제거했으며, 기존 각 프레임의 화면상 외곽과 앵커 관계에 맞춰 LANCZOS 축소, 약한 샤픈, 이진 알파를 적용했다.

모든 후보는 다음을 통과했다.

- 현재 PNG와 같은 전체 크기·프레임 수·프레임 크기·앵커·FPS
- RGBA, alpha `{0,255}`, 1px 빈 테두리, 빈 프레임 없음
- 코드의 대표 J 좌표·회전·배율로 몸체 위에 합성한 4× 확인
- 현재/신규의 모든 프레임을 나란히 둔 4× 비교

수치 결과는 `verification.json`, 시각 결과는 캐릭터별 `*-compare.png`에 있다.

## 남은 확인

- 이 작업은 카드 지시대로 후보만 만들었으므로 실제 Godot 런타임 재생은 하지 않았다.
- Nova와 Rio는 남녀 공용 이펙트다. 생성 참고에는 두 몸체를 모두 넣었고, 최종 코드 배치 비교는 남성 몸체의 같은 J 프레임을 대표로 썼다.
- Yuki의 새 퇴마 파동은 기존보다 종이·청록 요소가 강하다. 게임 영상에서 다른 청록 이펙트와 겹칠 때 판독성이 낮아지면 주홍 비율을 늘리는 2차 조정이 필요하다.
