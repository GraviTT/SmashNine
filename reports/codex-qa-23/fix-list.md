# 이미지 세션 수리 목록

현재 게임 38건, 후보 고유 행 23건. 건수는 파일·문제 묶음 기준이다. 같은 문제의 여러 프레임은 한 건이며 서로 다른 문제는 같은 행에서도 따로 센다. 후보 합본과 개별 스트립은 픽셀 해시로 중복 제거했다.

순서: 현재 대기 → 걷기 → J/몬스터 공격 → 나머지 기술 → 공중/피격 → 예비 공격·투사체, 이후 후보. 상=신체/무기 큰 누락, 중=눈에 띄는 연속성·정렬·색/부분 절단, 하=작은 여백·기준 크기·효과 분리. `re-slice`는 원본이 온전할 때만 가능하며 원본도 잘렸다면 `redraw`로 전환한다. 머리만 잘라 붙이는 수리는 하지 않는다.

| ID/등급 | 파일 | 행 · 프레임 | 문제(직접 관찰) | 측정값 | 수리 종류 |
|---|---|---|---|---|---|
| L01 상 | [jotunheim_rune_golem_sheet.png](../../smash-nine-prototype/assets/art/monsters/jotunheim_rune_golem_sheet.png) | idle · 1–4 | 몸 아래가 긴 수평선으로 잘려 다리가 보이지 않는다. 위쪽 바위가 달라져도 잘린 하단은 고정된다. | idle F1 L/R/B=1/7/93,F2 L/R/B=1/7/88,F3 L/R/B=1/6/90,F4 L/R/B=2/8/67px; 셀 외곽 0 | re-slice |
| L02 상 | [muspelheim_magma_boar_sheet.png](../../smash-nine-prototype/assets/art/monsters/muspelheim_magma_boar_sheet.png) | idle · 1–4 | 대기 네 칸의 배·다리가 수평으로 끊겨 상반신만 보인다. 보행 행에는 다리가 있다. | idle F1 L/R/B=3/11/72,F2 L/R/B=3/8/71,F3 L/R/B=3/9/74,F4 L/R/B=3/7/70px; 셀 외곽 0 | re-slice |
| L03 상 | [niflheim_glacier_wolf_sheet.png](../../smash-nine-prototype/assets/art/monsters/niflheim_glacier_wolf_sheet.png) | idle · 1–4 | 대기 네 칸의 다리가 아래쪽에서 잘린다. 보행 행의 다리와 비교하면 대기 하단의 누락이 뚜렷하다. | idle F1 L/R/B=2/2/15,F2 L/R/B=1/3/13,F3 L/R/B=2/2/14,F4 L/R/B=2/3/17px; 셀 외곽 0 | re-slice |
| L04 중 | [ember_imp_sheet.png](../../smash-nine-prototype/assets/art/monsters/ember_imp_sheet.png) | idle/walk/attack/hurt · 전체 15프레임 | 붉은 몸과 불꽃 바깥에 보라색 사각 계단 테두리가 연속으로 남아 있다. 원인이 배경 제거인지는 이미지로 단정하지 않는다. | 관찰색 외곽 5,294px; 부분 알파 6,326px (색 오염의 자동 증명 아님) | clean pixels |
| L05 중 | [mossling_sheet.png](../../smash-nine-prototype/assets/art/monsters/mossling_sheet.png) | idle/walk/attack/hurt · 전체 15프레임 | 나무 몸 바깥에 청록색 사각 테두리와 밝은 안쪽 테두리가 둘러 있다. 잎의 녹색과 구분되는 외곽 띠다. | 관찰색 외곽 4,522px; 부분 알파 5,296px (색 오염의 자동 증명 아님) | clean pixels |
| L06 하 | [ember_imp_sheet.png](../../smash-nine-prototype/assets/art/monsters/ember_imp_sheet.png) | idle/walk/attack · idle 1–4; walk 1–6; attack 1 | 뿔 끝/윗 테두리가 셀 상단 4px 여백 안에 있다. 먼저 색 테두리를 정리한 후 필요한 패딩만 확보한다. | idle F1=28px,F2=24px,F3=14px,F4=34px; walk F1=12px,F2=12px,F3=40px,F4=12px,F5=36px,F6=36px; attack F1=14px; 바깥 1px 접촉 0 | crop/pad |
| L07 하 | [jotunheim_rune_golem_sheet.png](../../smash-nine-prototype/assets/art/monsters/jotunheim_rune_golem_sheet.png) | idle/walk/attack/hurt · 해당 프레임은 수치 표 참고 | 넓은 어깨가 좌우 4px 여백 안에 들어간다. 잘린 하체 복원과 함께 셀 배치를 다시 잡는다. | idle F1=25px,F2=1px,F3=7px,F4=42px; walk F4=61px; attack F2=26px,F3=32px; hurt F1=69px; 바깥 1px 접촉 0 | crop/pad |
| L08 상 | [jotunheim_rune_golem_sheet.png](../../smash-nine-prototype/assets/art/monsters/jotunheim_rune_golem_sheet.png) | walk/attack/hurt · walk 1–6; attack 1–4; hurt 1 | 보행·공격·피격에서도 하단이 수평으로 끊긴다. 발 기준을 맞추는 이동만으로 빠진 하체를 복원할 수 없다. | walk F1 L/R/B=8/12/37,F2 L/R/B=4/13/25,F3 L/R/B=5/3/34,F4 L/R/B=6/7/25,F5 L/R/B=5/8/31,F6 L/R/B=5/7/31; attack F1 L/R/B=5/12/29,F2 L/R/B=5/12/24,F3 L/R/B=7/16/21,F4 L/R/B=5/16/30; hurt F1 L/R/B=12/6/39px; 셀 외곽 0 | re-slice |
| L09 중 | [nova_male_sheet.png](../../smash-nine-prototype/assets/art/nova/nova_male_sheet.png) | walk · 3 (비교 2·4·7) | F3의 청록 팔 보호대와 정강이 장갑이 다른 보행 칸보다 크고 복잡하다. F7과도 장비 형태가 이어지지 않는다. | H 99–102px, A 2928–3660px; F1 면적 idle 대비 +12.34%; 모양 결함 자체는 육안 판단 | redraw |
| L10 중 | [rio_female_sheet.png](../../smash-nine-prototype/assets/art/rio/rio_female_sheet.png) | walk · 4 | F3·F5는 검을 앞아래로 드는데 F4만 검이 몸 뒤에서 위로 향하고 검을 잡은 팔 연결이 달라 보인다. | H 94–100px, A 4408–5082px; F1 면적 idle 대비 -10.23%; 모양 결함 자체는 육안 판단 | redraw |
| L11 중 | [rio_male_sheet.png](../../smash-nine-prototype/assets/art/rio/rio_male_sheet.png) | walk · 1–8 | 대기와 비교하면 걷기의 검·망토·하체가 짧아지고, 특히 F7 검날이 짧게 보인다. 머리를 따로 붙여 맞추는 수리는 피한다. | H 90–95px, A 3805–4088px; F1 면적 idle 대비 -17.76%; 모양 결함 자체는 육안 판단 | redraw |
| L12 상 | [alfheim_moon_stag_sheet.png](../../smash-nine-prototype/assets/art/monsters/alfheim_moon_stag_sheet.png) | attack · 1–4 | F1–F2 오른쪽 머리·뿔이 잘리고 F3은 앞몸/머리가 없다. F4는 왼쪽 몸통이 잘린 머리 쪽 조각으로 바뀐다. | attack F1 L/R/B=4/28/6,F2 L/R/B=2/51/1,F3 L/R/B=4/34/1,F4 L/R/B=32/2/6px; 셀 외곽 0 | re-slice |
| L13 상 | [yggdrasil_root_guardian_sheet.png](../../smash-nine-prototype/assets/art/monsters/yggdrasil_root_guardian_sheet.png) | attack · 1–4 | F1–F2 오른쪽 주먹, F3–F4 전방 몸/머리가 같은 방향으로 잘린다. 특히 F3에서는 얼굴이 사라진다. | attack F1 L/R/B=5/16/5,F2 L/R/B=4/19/5,F3 L/R/B=1/20/5,F4 L/R/B=4/18/6px; 셀 외곽 0 | re-slice |
| L14 상 | [rio_female_moves_sheet.png](../../smash-nine-prototype/assets/art/rio/rio_female_moves_sheet.png) | mana_combo · 5–6 | F5 검날이 끝이 뭉툭한 직선으로 끊기고 F6 왼쪽에 연결되지 않은 검끝 조각이 남아 있다. | F5 bbox 우측 직선 7px; F6 분리 성분 80px; 셀 외곽 접촉 0 | re-slice |
| L15 중 | [asgard_runic_raven_sheet.png](../../smash-nine-prototype/assets/art/monsters/asgard_runic_raven_sheet.png) | attack · 3 | 부리 앞 발사 도형의 오른쪽 끝이 수직으로 잘리고 몸 시트에 함께 그려져 있다. | attack F1 L/R/B=2/4/18,F2 L/R/B=1/7/17,F3 L/R/B=2/13/17,F4 L/R/B=1/5/18px; 셀 외곽 0 | re-slice |
| L16 중 | [midgard_rooftop_slinger_sheet.png](../../smash-nine-prototype/assets/art/monsters/midgard_rooftop_slinger_sheet.png) | attack · 3 | 세 번째 공격 칸의 새총/전방 끈 끝이 오른쪽에서 잘린다. | attack F1 L/R/B=7/5/15,F2 L/R/B=7/5/14,F3 L/R/B=5/16/15,F4 L/R/B=7/4/15px; 셀 외곽 0 | re-slice |
| L17 중 | [muspelheim_magma_boar_sheet.png](../../smash-nine-prototype/assets/art/monsters/muspelheim_magma_boar_sheet.png) | attack · 2–3 | 돌진 중 F2–F3의 앞쪽 코·엄니가 오른쪽에서 수직으로 끊긴다. | attack F1 L/R/B=4/14/14,F2 L/R/B=7/28/13,F3 L/R/B=3/31/10,F4 L/R/B=5/12/12px; 셀 외곽 0 | re-slice |
| L18 중 | [niflheim_glacier_wolf_sheet.png](../../smash-nine-prototype/assets/art/monsters/niflheim_glacier_wolf_sheet.png) | attack · 2 | 공격 두 번째 칸의 코와 앞부분이 오른쪽에서 잘린다. | attack F1 L/R/B=2/12/11,F2 L/R/B=2/24/12,F3 L/R/B=1/11/11,F4 L/R/B=2/16/11px; 셀 외곽 0 | re-slice |
| L19 중 | [svartalfheim_cog_drone_sheet.png](../../smash-nine-prototype/assets/art/monsters/svartalfheim_cog_drone_sheet.png) | attack · 2 | 두 번째 공격 칸의 포구 끝이 수직 절단되어 다른 칸의 둥근 포구와 다르다. | attack F1 L/R/B=6/3/2,F2 L/R/B=5/18/3,F3 L/R/B=5/14/2,F4 L/R/B=5/9/2px; 셀 외곽 0 | re-slice |
| L20 중 | [svartalfheim_gear_beetle_sheet.png](../../smash-nine-prototype/assets/art/monsters/svartalfheim_gear_beetle_sheet.png) | attack · 2–3 | F2–F3의 전방 드릴 끝이 오른쪽에서 잘린다. 전방의 작은 불꽃/파편도 몸에서 분리해 보존한다. | attack F1 L/R/B=7/3/20,F2 L/R/B=7/7/10,F3 L/R/B=5/12/9,F4 L/R/B=7/6/15px; 셀 외곽 0 | re-slice |
| L21 하 | [alfheim_moon_moth_sheet.png](../../smash-nine-prototype/assets/art/monsters/alfheim_moon_moth_sheet.png) | attack · 2 | 몸 앞에 분리되어 날아가는 빛 구슬이 몸 프레임에 포함되어 있다. 독립 투사체와 겹쳐 보일지는 실행 확인이 필요하다. | 4칸 행, A 1971–2934px; 효과 포함은 육안 판단 | redraw |
| L22 하 | [asgard_aegis_ram_sheet.png](../../smash-nine-prototype/assets/art/monsters/asgard_aegis_ram_sheet.png) | attack · 3 | 돌진 몸의 위와 발 아래에 파란 속도 궤적이 함께 그려져 있다. 몸과 궤적을 분리해 보존할 대상이다. | 4칸 행, A 2698–2759px; 효과 포함은 육안 판단 | redraw |
| L23 하 | [ember_imp_sheet.png](../../smash-nine-prototype/assets/art/monsters/ember_imp_sheet.png) | attack · 2·4 | 뻗은 손 앞의 불꽃/불덩이와 주변 작은 불씨가 공격 몸 시트에 함께 그려져 있다. 꼬리 불꽃은 신체 디자인으로 보존하고 발사 부분만 분리한다. | 4칸 행, A 2437–3504px; 효과 포함은 육안 판단 | redraw |
| L24 하 | [jotunheim_storm_wisp_sheet.png](../../smash-nine-prototype/assets/art/monsters/jotunheim_storm_wisp_sheet.png) | attack · 4 | 발사 방향의 큰 파란 호와 파편이 몸 프레임에 함께 포함되어 있다. 몸과 발사 효과를 나눠 보존한다. | 4칸 행, A 2553–2820px; 효과 포함은 육안 판단 | redraw |
| L25 하 | [svartalfheim_cog_drone_sheet.png](../../smash-nine-prototype/assets/art/monsters/svartalfheim_cog_drone_sheet.png) | attack · 4 | 포구 오른쪽의 노란 발사 섬광이 몸 시트 안에 있다. 별도 발사 효과로 보존할 대상이다. | 4칸 행, A 2700–2804px; 효과 포함은 육안 판단 | redraw |
| L26 하 | [yggdrasil_root_oracle_sheet.png](../../smash-nine-prototype/assets/art/monsters/yggdrasil_root_oracle_sheet.png) | attack · 2 | 앞쪽 분홍 발사 구슬이 몸 그림과 같은 프레임에 포함되어 있다. 실제 중복 투사체 여부는 확인하지 않았다. | 4칸 행, A 2285–2609px; 효과 포함은 육안 판단 | redraw |
| L27 중 | [alfheim_moon_stag_sheet.png](../../smash-nine-prototype/assets/art/monsters/alfheim_moon_stag_sheet.png) | hurt · 1 | 피격 자세 오른쪽 뿔이 수직으로 끊긴다. | hurt F1 L/R/B=4/14/6px; 셀 외곽 0 | re-slice |
| L28 중 | [nova_female_sheet.png](../../smash-nine-prototype/assets/art/nova/nova_female_sheet.png) | hurt · 1 | 피격 한 칸의 가장 낮은 부츠가 다른 기본 지상 자세보다 8px 위에 떠 있다. | 최하단 y=112; 기준 120 (그림의 부츠도 확인) | move |
| L29 하 | [mossling_sheet.png](../../smash-nine-prototype/assets/art/monsters/mossling_sheet.png) | hurt · 1 | 머리 오른쪽 위의 노란 별/충격 표시가 피격 몸 그림에 포함된다. 외곽 색 정리와 함께 효과를 분리한다. | 1칸 행, A 3772–3772px; 효과 포함은 육안 판단 | redraw |
| L30 하 | [muspelheim_magma_boar_sheet.png](../../smash-nine-prototype/assets/art/monsters/muspelheim_magma_boar_sheet.png) | hurt · 1 | 머리 오른쪽 위의 작은 별 세 개가 피격 몸 그림에 포함된다. 상태/피격 효과로 분리할 대상이다. | 1칸 행, A 2782–2782px; 효과 포함은 육안 판단 | redraw |
| L31 중 | [asgard_runic_raven_projectile.png](../../smash-nine-prototype/assets/art/monsters/asgard_runic_raven_projectile.png) | projectile · 1 | 까마귀의 금테 룬 장식과 깃털 일부가 직사각형으로 잘린 그림이다. 독립된 발사체 외곽으로 복원한다. | projectile F1 L/R/B=13/18/18px; 셀 외곽 0 | redraw |
| L32 중 | [jotunheim_storm_wisp_projectile.png](../../smash-nine-prototype/assets/art/monsters/jotunheim_storm_wisp_projectile.png) | projectile · 1 | 발광 코어와 주변 돌 일부가 사각형으로 잘려 있다. 특히 왼쪽/상하 경계가 그림 내부에서 끊긴다. | projectile F1 L/R/B=17/13/8px; 셀 외곽 0 | redraw |
| L33 중 | [svartalfheim_cog_drone_projectile.png](../../smash-nine-prototype/assets/art/monsters/svartalfheim_cog_drone_projectile.png) | projectile · 1 | 주황 눈과 포신 일부가 ㄴ자 조각으로 남아 있고 왼쪽이 직선으로 끊긴다. | projectile F1 L/R/B=18/6/5px; 셀 외곽 0 | redraw |
| L34 하 | [nova_female_moves_sheet.png](../../smash-nine-prototype/assets/art/nova/nova_female_moves_sheet.png) | gravity_brake · 4–6 | 마지막 세 칸에서 양발이 앞선 접지 칸보다 위에 있다. 지상 정지 자세의 수직 연결을 손질한다. | 최하단 y=151,152,152,148,148,148; 기준 152 (그림의 부츠도 확인) | move |
| L35 중 | [rio_female_sheet.png](../../smash-nine-prototype/assets/art/rio/rio_female_sheet.png) | attack · 5–6 | 기본 예비 공격도 F5 검날 절단과 F6 왼쪽의 분리 검 조각을 포함한다. 현재 J는 기술 시트 mana_combo를 사용한다. | F5 bbox 우측 직선 6px; F6 분리 성분 55px; 셀 외곽 접촉 0 | re-slice |
| L36 중 | [rio_male_sheet.png](../../smash-nine-prototype/assets/art/rio/rio_male_sheet.png) | attack · 1–6 | 기본 예비 공격의 머리와 몸 전체가 대기보다 작다. 현재 J mana_combo는 별도 기술 시트다. | 머리 추정 중앙값 0.72; 신뢰도≥0.6 5/6; 허용 0.96–1.04 | redraw |
| L37 하 | [frey_sheet.png](../../smash-nine-prototype/assets/art/frey/frey_sheet.png) | attack · 3–6 | 기본 예비 공격의 후반 머리/투구가 대기보다 작다. 현재 J의 attack_chain은 별도 기술 시트라 우선순위는 낮다. | 머리 추정 중앙값 0.92; 신뢰도≥0.6 6/6; 허용 0.96–1.04 | redraw |
| L38 하 | [rio_female_sheet.png](../../smash-nine-prototype/assets/art/rio/rio_female_sheet.png) | attack · 1–6 | 기본 예비 공격의 머리와 몸이 대기보다 작다. 검 절단 수리 시 함께 기준 크기로 재정규화한다. 현재 J는 별도 기술 시트다. | 머리 추정 중앙값 0.90; 신뢰도≥0.6 6/6; 허용 0.96–1.04 | redraw |

## 후보 — 채택하지 않고 수리 정보만 전달

| ID/등급 | 파일 | 행 · 프레임 | 문제 | 측정값 | 수리 종류 |
|---|---|---|---|---|---|
| C01 하 | [jotunheim_rune_golem_sheet-v1.png](../../art/bakeoff/monsters/jotunheim_rune_golem_sheet-v1.png) | walk · 3,4,6 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F3=3px, F4=3px, F6=4px; 셀 외곽 0 | crop/pad |
| C02 하 | [jotunheim_rune_golem_sheet-v1.png](../../art/bakeoff/monsters/jotunheim_rune_golem_sheet-v1.png) | attack · 2,3,4 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F2=4px, F3=8px, F4=7px; 셀 외곽 0 | crop/pad |
| C03 하 | [jotunheim_storm_wisp_sheet-v1.png](../../art/bakeoff/monsters/jotunheim_storm_wisp_sheet-v1.png) | attack · 3 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F3=5px; 셀 외곽 0 | crop/pad |
| C04 하 | [midgard_rooftop_slinger_sheet-v1.png](../../art/bakeoff/monsters/midgard_rooftop_slinger_sheet-v1.png) | attack · 3 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F3=2px; 셀 외곽 0 | crop/pad |
| C05 하 | [muspelheim_magma_boar_sheet-v1.png](../../art/bakeoff/monsters/muspelheim_magma_boar_sheet-v1.png) | attack · 3 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F3=7px; 셀 외곽 0 | crop/pad |
| C06 하 | [niflheim_glacier_wolf_sheet-v1.png](../../art/bakeoff/monsters/niflheim_glacier_wolf_sheet-v1.png) | attack · 3,4 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F3=3px, F4=4px; 셀 외곽 0 | crop/pad |
| C07 하 | [vanaheim_seed_sprite_sheet-v1.png](../../art/bakeoff/monsters/vanaheim_seed_sprite_sheet-v1.png) | attack · 3 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F3=4px; 셀 외곽 0 | crop/pad |
| C08 하 | [yggdrasil_root_guardian_sheet-v1.png](../../art/bakeoff/monsters/yggdrasil_root_guardian_sheet-v1.png) | attack · 1 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F1=9px; 셀 외곽 0 | crop/pad |
| C09 중 | [niflheim_glacier_wolf_sheet-v1.png](../../art/bakeoff/monsters/niflheim_glacier_wolf_sheet-v1.png) | hurt · 1 | 올려든 머리 상단이 수평으로 끊겨 보인다. 6배 확대에서 귀/머리 위 윤곽 누락을 확인했으며 원본과 대조 후 다시 자른다. | 상단 y=21; 최상단 연속 수평선 8px; 셀 외곽 0 | re-slice |
| C10 하 | [jotunheim_rune_golem_sheet-v1.png](../../art/bakeoff/monsters/jotunheim_rune_golem_sheet-v1.png) | hurt · 1 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F1=3px; 셀 외곽 0 | crop/pad |
| C11 하 | [alfheim_moon_moth_sheet-v1.png](../../art/bakeoff/monsters/alfheim_moon_moth_sheet-v1.png) | defeat · 4 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F4=2px; 셀 외곽 0 | crop/pad |
| C12 하 | [asgard_aegis_ram_sheet-v1.png](../../art/bakeoff/monsters/asgard_aegis_ram_sheet-v1.png) | windup · 2 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F2=4px; 셀 외곽 0 | crop/pad |
| C13 하 | [asgard_runic_raven_sheet-v1.png](../../art/bakeoff/monsters/asgard_runic_raven_sheet-v1.png) | windup · 2 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F2=2px; 셀 외곽 0 | crop/pad |
| C14 하 | [jotunheim_rune_golem_sheet-v1.png](../../art/bakeoff/monsters/jotunheim_rune_golem_sheet-v1.png) | defeat · 3,4 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F3=7px, F4=9px; 셀 외곽 0 | crop/pad |
| C15 하 | [midgard_rooftop_slinger_sheet-v1.png](../../art/bakeoff/monsters/midgard_rooftop_slinger_sheet-v1.png) | defeat · 4 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F4=9px; 셀 외곽 0 | crop/pad |
| C16 하 | [muspelheim_magma_boar_sheet-v1.png](../../art/bakeoff/monsters/muspelheim_magma_boar_sheet-v1.png) | windup · 4 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F4=3px; 셀 외곽 0 | crop/pad |
| C17 하 | [muspelheim_magma_boar_sheet-v1.png](../../art/bakeoff/monsters/muspelheim_magma_boar_sheet-v1.png) | defeat · 4 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F4=4px; 셀 외곽 0 | crop/pad |
| C18 하 | [niflheim_frost_owl_sheet-v1.png](../../art/bakeoff/monsters/niflheim_frost_owl_sheet-v1.png) | defeat · 4 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F4=1px; 셀 외곽 0 | crop/pad |
| C19 하 | [svartalfheim_cog_drone_sheet-v1.png](../../art/bakeoff/monsters/svartalfheim_cog_drone_sheet-v1.png) | defeat · 3,4 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F3=7px, F4=7px; 셀 외곽 0 | crop/pad |
| C20 하 | [vanaheim_seed_sprite_sheet-v1.png](../../art/bakeoff/monsters/vanaheim_seed_sprite_sheet-v1.png) | defeat · 3 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F3=3px; 셀 외곽 0 | crop/pad |
| C21 하 | [vanaheim_vine_hound_sheet-v1.png](../../art/bakeoff/monsters/vanaheim_vine_hound_sheet-v1.png) | defeat · 4 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F4=6px; 셀 외곽 0 | crop/pad |
| C22 하 | [yggdrasil_root_guardian_sheet-v1.png](../../art/bakeoff/monsters/yggdrasil_root_guardian_sheet-v1.png) | defeat · 1,4 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F1=2px, F4=3px; 셀 외곽 0 | crop/pad |
| C23 하 | [yggdrasil_root_oracle_sheet-v1.png](../../art/bakeoff/monsters/yggdrasil_root_oracle_sheet-v1.png) | windup · 2 | 몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다. | F2=6px; 셀 외곽 0 | crop/pad |

## 후보 중복 파일 대응

- C01: `art/bakeoff/monsters/jotunheim_rune_golem-walk-v1.png` / walk; `art/bakeoff/monsters/jotunheim_rune_golem_sheet-v1.png` / walk
- C02: `art/bakeoff/monsters/jotunheim_rune_golem-attack-v1.png` / attack; `art/bakeoff/monsters/jotunheim_rune_golem_sheet-v1.png` / attack
- C03: `art/bakeoff/monsters/jotunheim_storm_wisp-attack-v1.png` / attack; `art/bakeoff/monsters/jotunheim_storm_wisp_sheet-v1.png` / attack
- C04: `art/bakeoff/monsters/midgard_rooftop_slinger-attack-v1.png` / attack; `art/bakeoff/monsters/midgard_rooftop_slinger_sheet-v1.png` / attack
- C05: `art/bakeoff/monsters/muspelheim_magma_boar-attack-v1.png` / attack; `art/bakeoff/monsters/muspelheim_magma_boar_sheet-v1.png` / attack
- C06: `art/bakeoff/monsters/niflheim_glacier_wolf-attack-v1.png` / attack; `art/bakeoff/monsters/niflheim_glacier_wolf_sheet-v1.png` / attack
- C07: `art/bakeoff/monsters/vanaheim_seed_sprite-attack-v1.png` / attack; `art/bakeoff/monsters/vanaheim_seed_sprite_sheet-v1.png` / attack
- C08: `art/bakeoff/monsters/yggdrasil_root_guardian-attack-v1.png` / attack; `art/bakeoff/monsters/yggdrasil_root_guardian_sheet-v1.png` / attack
- C09: `art/bakeoff/monsters/niflheim_glacier_wolf-hurt-v1.png` / hurt; `art/bakeoff/monsters/niflheim_glacier_wolf_sheet-v1.png` / hurt
- C10: `art/bakeoff/monsters/jotunheim_rune_golem-hurt-v1.png` / hurt; `art/bakeoff/monsters/jotunheim_rune_golem_sheet-v1.png` / hurt
- C11: `art/bakeoff/monsters/alfheim_moon_moth-defeat-v1.png` / defeat; `art/bakeoff/monsters/alfheim_moon_moth_sheet-v1.png` / defeat
- C12: `art/bakeoff/monsters/asgard_aegis_ram-windup-v1.png` / windup; `art/bakeoff/monsters/asgard_aegis_ram_sheet-v1.png` / windup
- C13: `art/bakeoff/monsters/asgard_runic_raven-windup-v1.png` / windup; `art/bakeoff/monsters/asgard_runic_raven_sheet-v1.png` / windup
- C14: `art/bakeoff/monsters/jotunheim_rune_golem-defeat-v1.png` / defeat; `art/bakeoff/monsters/jotunheim_rune_golem_sheet-v1.png` / defeat
- C15: `art/bakeoff/monsters/midgard_rooftop_slinger-defeat-v1.png` / defeat; `art/bakeoff/monsters/midgard_rooftop_slinger_sheet-v1.png` / defeat
- C16: `art/bakeoff/monsters/muspelheim_magma_boar-windup-v1.png` / windup; `art/bakeoff/monsters/muspelheim_magma_boar_sheet-v1.png` / windup
- C17: `art/bakeoff/monsters/muspelheim_magma_boar-defeat-v1.png` / defeat; `art/bakeoff/monsters/muspelheim_magma_boar_sheet-v1.png` / defeat
- C18: `art/bakeoff/monsters/niflheim_frost_owl-defeat-v1.png` / defeat; `art/bakeoff/monsters/niflheim_frost_owl_sheet-v1.png` / defeat
- C19: `art/bakeoff/monsters/svartalfheim_cog_drone-defeat-v1.png` / defeat; `art/bakeoff/monsters/svartalfheim_cog_drone_sheet-v1.png` / defeat
- C20: `art/bakeoff/monsters/vanaheim_seed_sprite-defeat-v1.png` / defeat; `art/bakeoff/monsters/vanaheim_seed_sprite_sheet-v1.png` / defeat
- C21: `art/bakeoff/monsters/vanaheim_vine_hound-defeat-v1.png` / defeat; `art/bakeoff/monsters/vanaheim_vine_hound_sheet-v1.png` / defeat
- C22: `art/bakeoff/monsters/yggdrasil_root_guardian-defeat-v1.png` / defeat; `art/bakeoff/monsters/yggdrasil_root_guardian_sheet-v1.png` / defeat
- C23: `art/bakeoff/monsters/yggdrasil_root_oracle-windup-v1.png` / windup; `art/bakeoff/monsters/yggdrasil_root_oracle_sheet-v1.png` / windup

현재 문제와 같은 채택 이력 후보: `nova_female-hurt-v1`(8px), `rio_female-attack-v1`(55px 조각/축소), `rio_female-mana_combo-v1`(80px 조각), `rio_male-attack-v1`(머리 0.72). 새 후보 결함 건수에는 다시 더하지 않았다.

머리 추정만 경계를 넘은 후보 Luna fall/victory, Brave fall/hurt와 Nova meteor_kick은 [후보 표](candidate-rows.md)에 수동 재확인 대상으로 남겼다. 얼굴 방향 차이를 배제하지 못했으므로 확정 수리 건수에서 제외했다.
