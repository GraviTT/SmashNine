"""Write the Korean review handoff from the verified final artifacts."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json
import process as p

if __name__=='__main__':
 v=json.loads((p.REPORT/'verification.json').read_text('utf-8'))
 sizes=json.loads((p.REPORT/'fix-1/sizes.json').read_text('utf-8'))
 changed=[x for x in sizes if x['before_factor']!=x['after_factor']]
 low=[x for x in v['results'] if x['detail_min']<85]
 reaches=json.loads((p.REPORT/'reach-measurements.json').read_text('utf-8'))
 text='''# CODEX-ART-74 — 몬스터 2차, 리드 검수 수정 1회차

## 작업 완료

6종·36행·168프레임 후보를 유지하면서 **하운드·씨앗 요정의 색을 복원하고, 22행의 공통 배율을 수정**했다. 최종 대표 부위 측정은 36행 모두 각자의 idle 대비 ±5% 이내다. 행별 PNG/JSON 36쌍과 576×576 조립 시트 6장을 갱신했다.

모두 **사용자 검토용 후보**다. 기존 미커밋 작업과 raw를 보존했다. 게임·tools 변경, Godot 실행, 추가 이미지 생성, 스테이징·커밋은 하지 않았다. [검수 요청 원문](fix-1.prompt.md)도 납품 목록에 포함한다.

## 이번 색상 수정

| 몬스터 | 수정 방법 | 결과 |
|---|---|---|
| `vanaheim_vine_hound` | 현재 게임 시트에서 이끼색 잎·갈색 나무·녹색 눈의 5단계 색을 추출. 후보의 노랑/주황/청록을 이 색 사이로 보간. 잎은 노란 하이라이트를 제외한 녹색 표본을 사용하고, 나무결이 눌리지 않도록 원본 밝기 차이를 일부 보존 | 녹색 잎, 갈색 몸, 녹색 눈 테두리 복원. 모든 행 디테일 최솟값 93.10 이상 |
| `vanaheim_seed_sprite` | 현재 게임 시트의 잎·눈 색에서 같은 방식의 보간 매핑. 주황 몸도 녹색 계열로 이동. 밝고 채도가 낮은 꽃잎은 흰색 유지, 청록 광원의 중심은 흰색·테두리는 녹색 | 녹색 잎과 눈, 흰 꽃 유지 |

Python/Pillow로 몬스터마다 **동일 RGB→RGB 매핑 하나를 6행 전체에 적용**했다. 위치별 칠하기·프레임별 색 변경·팔레트 양자화는 하지 않았다. 수정 전후 알파가 같고 모든 불투명 픽셀이 공통 매핑과 일치함을 검사했다. 색이 뭉개지는 초기 매핑은 밝기 보존 방식으로 보완했으며 추가 생성은 필요하지 않았다.

![기존 / 수정 전 / 수정 후, 1배와 4배](fix-1/colour-focus.png)

각 줄의 왼쪽은 현재 게임, 가운데는 수정 전 후보, 오른쪽은 수정 후 후보다. 작은 그림은 정확한 1배, 큰 그림은 최근접 4배다.

전 행을 나란히 둔 색상판:

- 하운드: [1배](vanaheim_vine_hound-colour-1x.png) · [4배](vanaheim_vine_hound-colour-4x.png) · [1배+4배 합본](vanaheim_vine_hound-colour.png)
- 씨앗 요정: [1배](vanaheim_seed_sprite-colour-1x.png) · [4배](vanaheim_seed_sprite-colour-4x.png) · [1배+4배 합본](vanaheim_seed_sprite-colour.png)

현재 시트에는 windup/defeat 행이 없으므로 해당 칸만 비어 있다. 매핑 색과 전체 LUT는 `fix-1/<id>-palette.json`, 픽셀 검증은 [palette-verification.json](fix-1/palette-verification.json)에 있다.

## 크기 수정

수정한 행은 **각 raw에서 행당 factor 하나로 다시 축소**했다. 프레임별 확대·축소나 몸 조각 교체는 하지 않았다. 원본을 여유 있는 작업 캔버스에 정리한 다음, 그림 전체만 평행 이동해 최종 96px 셀·3px 여백·발 y72를 맞췄다. 모든 불투명 픽셀은 보존한다. 비행 눈 위치와 하운드의 공중 높이 53/60도 유지했다.

하운드와 골렘은 작은 행을 전부 키우면 넓은 프레임이 셀을 넘는다. 따라서 **하운드 idle/walk .20→.19, 골렘 idle .19→.18**로 기준을 조금 줄이고 작은 동작을 확대했다. 골렘 walk는 .17→.188이다. 드론은 이전의 측면 기어 폭 대신 **중앙 장갑 타원 높이**로 측정해, hurt .115→.13726 등 몸통 차이를 수정했다.

### 측정 방법과 한계

각 행의 같은 안정 부위를 4배 눈금판에서 비교했다. 보통 F1, hurt는 회복 F2, 하운드·씨앗·골렘 attack은 회복 F6다. 수동 경계는 약 ±1px 오차가 있으며 원본 배율·전체 이동으로 추적한 같은 부위를 최종 픽셀 경계로 반올림했다. 슬링거는 외곽폭이 1px 연결 여부에 흔들려 **목 아래를 뺀 주황 후드 면의 √면적**을 동일 색 조건으로 전후 재측정했다(선형 크기 단위 px).

따라서 **±5%는 표에 표시한 대표 부위의 명목 측정값**이다. 모든 자세·프레임의 해부학적 크기를 자동으로 인증한 것은 아니다. 최종 부위 상자와 수정 전후 그림을 공개하며 실제 반복 재생 판단은 남는다.

'''
 text+=(p.REPORT/'fix-1/size-table.md').read_text('utf-8')
 text+='''
### 크기 비교판

![골렘 행별 수정 전후](fix-1/jotunheim_rune_golem-size-before-after-4x.png)

위쪽은 수정 전, 아래쪽은 수정 후다. 분홍 상자는 같은 어깨 룬 원판이며 각 캡션에 크기와 idle 비율을 적었다.

![드론 몸통 수정 전후](fix-1/svartalfheim_cog_drone-size-before-after-4x.png)

기어·노즐·엔진을 제외한 중앙 장갑 타원의 높이를 비교했다. 작은 피격 몸통을 같은 배율로 키웠다.

나머지 4배 크기판: [슬링거](fix-1/midgard_rooftop_slinger-size-before-after-4x.png) · [등딱지 벌레](fix-1/svartalfheim_gear_beetle-size-before-after-4x.png) · [하운드](fix-1/vanaheim_vine_hound-size-before-after-4x.png) · [씨앗 요정](fix-1/vanaheim_seed_sprite-size-before-after-4x.png). 수치 원본은 [sizes.json](fix-1/sizes.json).

## 확인 및 테스트

- `final_check.py`: raw 재구축 → PNG/JSON/조립본 검사 → 발/행 비교판 → 크기·공통 팔레트 검증까지 완료. **6종·36행·168프레임, 규격 실패 0, 크기 범위 실패 0**.
- 최소 여백 3px, 테두리 비움, 알파 0/255, 미사용 셀 투명, 중복 프레임 없음, 6장 조립본과 행 PNG의 픽셀 일치 확인.
- 지상 접촉 y72, 하운드 공중 53/60, 드론 낙하 마지막 접촉 y72 확인. 씨앗 attack 2·3번은 지지발 y72와 펼친 잎끝 y74를 구분한다.
- 녹색 번짐: 보정 전 chroma 정리 결과 0. 보정 후 공통 LUT 일치·알파 불변·순수 키색 #00ff00 없음 확인. 기존 `G > max(R,B)+20` 검사는 정상 녹색 잎/눈도 세므로 그 원시 수치를 `legacy_green_dominance_count`로 따로 공개했다. 정상 녹색을 제거해 숫자를 맞추지 않았다.
- 원본 생성은 이전 작업의 내장 ImageGen 55회 그대로다. 이번 추가 생성 0회. `accepted-raws.json`의 원본 해시 일치, 제품·tools 추적 변경 없음, index 비움은 `handoff_check.py`로 확인한다.
- 모션 뷰어 파일명·행 수는 기존과 같다. 이전 회차의 로컬 빌드/36후보 확인 기록은 유지하며, 이번에는 tools 아래에 쓰지 않도록 빌드를 재실행하지 않았다. Godot·실제 애니메이션 재생·외부 게시·게임 적용은 실행하지 않았다.

디테일은 기존 ART-61/71의 내부 명암 라플라시안 지표다(Frey 대기 평균 96.31). 형태·밝기에도 영향을 받으며 그림의 좋고 나쁨 자체를 증명하지 않는다.

'''
 text+='| 85 미달 행 | 최솟값 |\n|---|---:|\n'
 text+='\n'.join(f"| {x['monster']} / {x['row']} | {x['detail_min']:.2f} |" for x in low)+'\n'
 text+='''
## 남은 약점

'''
 for x in reaches:
  text+=f"- {x['monster']}: 전진 부위 측정 {x['before_forward_px']}→{x['forward_px']}px.\n"
 text+='''
씨앗 요정의 공격 전진은 **5px로 목표 8px 미달**이다. 커진 몸통을 3px 여백 안에 넣으면서 이전 6px보다 1px 줄었다. 단순 위치 이동으로 더 내밀면 최장 잎이 셀을 넘으므로 이번에는 크기·색 수정 범위에서 남겼다. 이 부분을 고치려면 잎 배치와 뻗는 자세를 다시 그리는 편이 맞다.

골렘 idle 일부의 디테일 83.97, 벌레·골렘·씨앗의 약한 보행 교대, 씨앗 공격 잎끝 y74가 남는다. 두 녹색 몬스터의 고밀도 밝은 잎 하이라이트와 강한 외곽은 현재 게임보다 더 날카롭게 보인다. 실제 반복 재생에서 드론 해치·하부 핀, 행 전환의 크기 느낌은 사용자 검수가 필요하다.

## 다음 권장 단계 / 납품

사용자 또는 리드가 색상판과 모션 뷰어의 행 전환을 확인한 뒤 후보를 선택한다. 씨앗 공격 reach 보완과 게임 연결은 별도 후속 작업이다.

- 재현: Codex 런타임 Python에 `-B`를 붙여 `reports/codex-art-74/final_check.py` 실행. 초기 `rebuild.py`/`make_report.py`는 첫 회차 기록이며 이번 최종 재현 진입점은 `final_check.py`다.
- 원본: `art/raw/monsters-74/` 보존, 커밋 제외. 수정 전 후보는 `fix-1/before/`, 색 보정 전 후보는 `fix-1/colour-input/`에 보존했다.
- [commit.ps1](commit.ps1)은 **작성만 했고 실행하지 않았다**. [delivery-files.txt](delivery-files.txt)의 명시된 파일만 대상으로 하며 검수 요청 원문을 포함한다. raw·작업 캔버스·`__pycache__`·어느 위치의 `run.log`도 포함하지 않는다. 다른 기존 미추적 파일은 건드리지 않는다.
- 자세한 검증: [verification.json](verification.json), [validation.log](validation.log), [handoff-check.json](handoff-check.json).
'''
 (p.REPORT/'README.md').write_text(text,'utf-8',newline='\n')
 print(f'REPORT: {len(changed)} row factors changed; {len(sizes)} rows in tolerance; {len(low)} low-detail rows disclosed.')
