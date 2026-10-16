# CODEX-DOC-02 이미지 출처와 프레임

프레임 번호는 0부터 센 값이다. `전`과 `후`는 각 비교에서 같은 번호를 사용했다.

| 파일 | 패널 출처 |
|---|---|
| `01-summary.png` | `1b61483`의 8형태 base sheet `idle`, frame 2 (Frey, Luna, Brave Luna, Yuki, Nova 남/여, Rio 남/여), 2× NEAREST |
| `02-guard.png` | `guard-fx.webp`, frame 29, 6형태. 전 `28ffe0a`, 후 `de5e589`; 바닥 기준선 y=500과 그 아래 40px 표시 |
| `03-j-trail.png` | Frey `ground-j` f21; Rio `ground-j` f4; Luna `air-j` f9. 전 `de5e589`, 후 `1b61483` |
| `04-doubled.png` | Rio `rune` f25; Nova `ground-j` f4; Nova `up-j` f4. 전 `de5e589`, 후 `1b61483` |
| `05-ground-down.png` | Frey `down-j` f8; Luna `down-j` f8. 전 `de5e589`, 후 `1b61483`; 바닥선 y=518 표시 |
| `06-bloom.png` | `1b61483` Frey base sheet `idle` f2(2×)와 `effects/skill/luna_star_bloom.png` f4(2× 게임 표시 크기)의 실제 스프라이트 합성; 전은 별꽃을 Frey 위, 후는 Frey 뒤에 배치 |
| `07-ultimate-flash.png` | Luna `transform` f45; Nova `ultimate` f41; Yuki `ultimate` f118. 전 `de5e589`, 후 `1b61483` |
| `08-rio-head.png` | `1b61483` sheet frame 2: Rio 남 `idle`, base `attack`; Rio 여 `idle`, base `attack`, moves `low_sweep`, moves `dimension_slash`; 머리카락을 포함한 머리 크롭을 모두 4× NEAREST로 표시하고 형태별 턱선을 맞춤. 각 칸의 노란 외곽선은 같은 턱선에 맞춘 해당 형태 `idle` 머리 크기 |
| `09-nova-hurt.png` | `1b61483`: `art/bakeoff/nova/nova_female-hurt-v1.png` 첫 셀과 `-v2.png` frame 0, 모두 3×; 셀 바닥선 y=120, v1 발끝 y=112의 8px 간격 표시 |
| `10-kept.png` | `1b61483`: Brave Luna `aura` f0, Rio `ultimate` f32; Frey base sheet `idle` f2(2×)와 42×64 피격 상자 |

## 400×225 확인

`images/contact.png`에는 10개 이미지를 각각 400×225로 NEAREST 축소해 그 크기 그대로 2열로 배치했다.

| 파일 | 400×225 판독 결과 |
|---|---|
| 01 | 2×의 8형태와 그림/이펙트 점의 의미가 구분된다. |
| 02 | 섬광이 없는 6형태의 전·후 호와 노란 바닥선이 구분된다. |
| 03 | Frey·Rio·Luna 모두 후 궤적이 얇아졌고 Luna 전신이 보인다. |
| 04 | Rio의 공용 베기 제거와 Nova 두 전용 신호가 구분된다. |
| 05 | 노란 바닥선 위·아래의 궤적 차이가 구분된다. |
| 06 | 같은 Frey와 별꽃의 전후 레이어 순서 차이가 구분된다. |
| 07 | 세 궁극기의 전·후 투명도 차이가 구분된다. |
| 08 | 4× 머리 크롭과 `idle` 크기 외곽선이 남·여 두 줄에서 구분되며, 작은 네 머리가 외곽선을 채우지 않는 차이가 보인다. |
| 09 | 같은 크기의 두 패널과 v1의 8px 간격 브래킷이 구분된다. |
| 10 | 유지 효과 두 개와 2× Frey의 42×64 상자가 구분된다. |

## 표시하지 못한 것

- Nova·Rio 여성형의 실제 이펙트 클립은 캡처 도구가 남성형만 기록했으므로 넣을 수 없었다. 여성형 스프라이트 자체는 01, 08, 09에 실제 시트/후보 이미지로 표시했다.
