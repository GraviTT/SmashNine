import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,datetime,hashlib
from pathlib import Path
import process as p

def feet(mid,row,bottoms):
    if mid=='svartalfheim_cog_drone':return '낙하 '+','.join(map(str,bottoms)) if row=='defeat' else '비행'
    if mid=='vanaheim_vine_hound' and row=='attack':return '지상72 / 공중53·60'
    if mid=='vanaheim_seed_sprite' and row=='attack':return '지지발72 / 잎끝74(2·3번)'
    return '72'

if __name__=='__main__':
    v=json.loads((p.REPORT/'verification.json').read_text('utf-8'));sz=json.loads((p.REPORT/'size-measurements.json').read_text('utf-8'))
    sizes={(s['monster'],s['row']):s for s in sz}
    prompts=[]
    for mid in p.WINDUP:
        for row in p.ROWS:
            for file in sorted((p.REPORT/mid/row).glob('prompt*.txt'),key=lambda x: (0 if x.name=='prompt.txt' else int(x.stem[-1]))):
                prompts += [f'=== {mid}/{row}/{file.name} ===',file.read_text('utf-8').strip(),'']
    (p.REPORT/'prompts.txt').write_text('\n'.join(prompts),'utf-8')
    sources=[]
    for mid in p.WINDUP:
        for row in p.ROWS:
            file=p.ROOT/f'art/raw/monsters-74/{mid}-{row}.png'
            sources.append(dict(monster=mid,row=row,file=file.relative_to(p.ROOT).as_posix(),sha256=hashlib.sha256(file.read_bytes()).hexdigest()))
    (p.REPORT/'accepted-raws.json').write_text(json.dumps(sources,indent=2),'utf-8')
    text='''# CODEX-ART-74 — 몬스터 2차 여섯 종 후보

## 작업 완료

카드 순서의 **6종·36행·168프레임**, 행별 PNG/JSON 36쌍과 576×576 조립 시트 6장을 전달한다. 모두 **사용자 선택용 후보**이며 게임 적용·채택·외부 게시를 한 것이 아니다. 제품과 tools의 추적 소스는 수정하지 않았고, Godot·패키지 설치·다운로드·스테이징·커밋은 실행하지 않았다.

## 시각적 확인

![기존 대기와 후보 대기, 새 준비 자세](overview.png)

위쪽은 기존/후보를 실제 1배로 비교하고, 아래쪽은 새 준비 2번 자세를 1.5배로 보여준다. 전체 행 비교는 각 `<id>.png`(1배+4배), `<id>-1x.png`, `<id>-4x.png`에 있다. 각 행의 `anchor-4x.png`는 채택한 대기 첫 장과 전 프레임을 정확한 4배로 나란히 보여준다. `<id>-walk-feet-4x.png`는 y71~73의 실제 접촉부 x 위치를 프레임마다 표시한다. `<id>-size-4x.png`의 분홍 상자는 크기 측정 부위다.

## 선택한 기준 대기 — 육안 판단

| 몬스터 | 선택 | 유지한 특징 / 선택 이유 |
|---|---|---|
| midgard_rooftop_slinger | 1번 | 갈색 후드·초록 얼굴·청록 망토·슬링이 읽히고 재봉과 천 층이 선명함 |
| svartalfheim_gear_beetle | 1번 | 남색 금속 돔·황동 톱니·주황 눈·짧은 금속 다리 유지 |
| svartalfheim_cog_drone | 1번 | 떠 있는 둥근 기체·측면 기어·앞 노즐·청록 하부 부품 유지 |
| vanaheim_vine_hound | 2번 | 1번 디테일 73.13~76.64를 제외하고 잎맥·나무결 대비가 개선된 2번 선택 |
| vanaheim_seed_sprite | 1번 | 둥근 씨앗 몸·청록 얼굴·잎·덩굴·꽃 가지 유지 |
| jotunheim_rune_golem | 1번 | 낮고 넓은 바위 몸·큰 주먹·머리와 어깨 룬 판 유지 |

## 제작 방법과 측정 범위

- 내장 ImageGen만 사용했다. 대기는 현재 게임 시트가 정체성 Image 1, Frey가 디테일 밀도 Image 2였다. 이후에는 선택한 대기 행이 Image 1, 현재 시트가 Image 2다. 사용·제외한 원본은 `art/raw/monsters-74/`에 보존한다. 정확한 프롬프트는 `prompts.txt`, 선택 회차는 `selection.json`, 선택 원본 해시는 `accepted-raws.json`이다.
- ART-71의 `process.py`·`verify.py`·뷰어 검사를 이 보고서 폴더에 복사해 수정했다. 공용 `tools/sprite_pipeline/normalize.py`는 수정하지 않고 호출한다. **LANCZOS / 선명화60 / despill auto / 팔레트 없음 / #00ff00**, 동작 한 장 생성·행당 배율 하나를 유지했다. 몸 조각 붙이기·프레임별 확대/축소·팔레트 교체는 하지 않았다.
- 드론은 밝은 눈의 중심을 기존 시트의 (64,40) 부근으로 프레임 전체만 평행 이동했다. 준비는 눈 y40→38→35→34, 공격은 40·40·36·38·40·40으로 수평 기체·위쪽 반동을 유지했다. `eye_alignment`에 색 임계값·검출 상자·이동량이 있다. 초기 잘못된 황동 검출은 경계 검사에서 중단했고 최종 검사는 밝은 눈을 직접 확인한 뒤 수행했다.
- 사냥개 도약은 지상 1·2·5·6번을 y72에 맞추고 공중 3·4번은 최하단 y53·60으로 전체 이동했다. 씨앗 요정 공격 2·3번은 눈금판에서 확인한 뿌리발 y70을 전체 이동해 y72로 맞췄다. 그 때문에 펼친 잎끝은 y74다. 위치 수정은 각각 `ground_contacts`·`whole_frame_translations`에 있다.
- **디테일 수치**는 ART-61/71과 같은 내부 명암 라플라시안 지표다. Frey 대기 평균은 96.31. 수치가 보기 좋은지 또는 같은 그림체인지를 증명하지 않는다.
- **크기 수치**는 안정된 부위의 대표 프레임 가로폭을 대기 첫 장에 나눈 값이다. 슬링거는 주황 후드 색 영역의 4연결 성분, 나머지는 4배 눈금판에서 수동 지정한 외곽 상자(±2px)다. 측면 기어/머리/씨앗 몸/룬 판을 사용했다. 피격은 2번, 일부 공격은 회복 6번, 나머지는 1번이다. **전 프레임의 정밀 자동 머리 비율 검사는 아니다.** 전체 자세는 행별 4배 판에서 따로 확인했다.
- 기본 접촉값 72는 최하단 자동 측정과 확대판의 지지부 검토를 함께 기록한 것이다. 접촉 띠의 불투명 run은 발 위치 자료이며 **각 다리의 하중이나 좌우 정체성을 자동 판별하지 않는다.** 보행 판정은 아래 육안 판단과 구분한다.

## 행별 측정 결과

모든 행은 셀96·메타데이터 발 기준72·6열이다. 바깥 테두리 비움, 최소 여백≥3, spill0, 알파0/255, 빈 셀 투명, 중복 프레임 없음, 조립본/행 이미지 일치를 검사했다. 아래 수치는 최종 파일의 `audit96`·`final_summary` 기준이다. 최초 `summary`는 전체 평행 이동 전 값일 수 있다.
'''
    for mid in p.WINDUP:
        text+=f'\n### `{mid}`\n\n| 행 | 장 | fps | factor | 여백 px | 디테일 범위 | 발/접촉 y | 크기 폭/대기 | 전달 |\n|---|---:|---:|---:|---:|---:|---|---:|---|\n'
        for r in [r for r in v['results'] if r['monster']==mid]:
            s=sizes[mid,r['row']];bottoms=[x['bottom'] for x in r['frames_audit']]
            text+=f"| {r['row']} | {r['frames']} | {r['fps']:.3f} | {r['factor']:.6g} | {r['margin_min']} | {r['detail_min']:.2f}~{r['detail_max']:.2f} | {feet(mid,r['row'],bottoms)} | {s['width']}px / {s['ratio']:.2f} | 후보 |\n"
    text+='''
## ART-71 교훈 확인

| 항목 | 측정 | 육안 판단 / 결론 |
|---|---|---|
| 디테일≥85 | 골렘 대기 최저83.86. 나머지35행은 모든 프레임≥85 | 골렘 대기 일부의 넓은 돌 면이 비교적 부드러움. 목표 완전 통과로 보고하지 않음 |
| 보행 교대 | 5종 모두 프레임별 접촉 띠 x 위치를 4배 판에 표시 | 슬링거는 밝은/어두운 부츠 교대가 개선됨. 사냥개 앞발 내밈/접힘이 읽힘. 딱정벌레 6다리·골렘 두 팔·씨앗 짧은 뿌리발은 1배에서 교대가 여전히 약한 구간이 있음 |
| 접지 | 지상 최하단72, 사냥개 공중53·60, 드론 마지막 낙하72. 씨앗 공격의 지지발72·펼친 잎74 | 씨앗 잎이 지면 아래 2px 들어가는 부분은 남음. 모든 다리의 하중을 자동 검사했다고 주장하지 않음 |
| 전진≥8px | 슬링거 손10px, 사냥개 앞발13px, 씨앗 손/가지 접점6px | 씨앗은 목표보다 짧음. 3회 상한 중 동작이 가장 읽히는 3번을 전달 |
| 행별 크기 | 각 행 배율1개, 대표 부위 폭/대기 비율을 표에 공개 | 골렘 보행0.85·공격/피격0.89, 사냥개 공격/쓰러짐0.89는 작은 편. 수동 상자 오차와 자세 영향도 있으므로 실제 재생에서 확인할 부분 |

## 행동·루프 확인

- 슬링거: 뒤로 감기 → 앞팔 투척 → 후속 동작·회복. 돌 없음.
- 딱정벌레: 준비에서 머리·다리가 들어가고, 공격은 닫힌 껍질 슬라이드 반복. 바닥과 분리된 돌진 프레임은 없음. 첫/끝 알파 IoU 0.923, RGBA 평균 절대 차이9.799(인접 전이8.917~12.614).
- 드론: 수평 기체와 아래 해치 개방, 위쪽 반동 후 폐쇄. 급강하·폭탄 그림 없음. 첫/끝 알파 IoU0.977, 평균 절대 차이2.922(인접1.427~16.193). 첫·끝 눈 높이 같음.
- 사냥개: 낮은 웅크림 → 밀어내기 → 공중2장 → 착지. 덩굴은 몸에 붙어 있고 궤적·먼지 없음.
- 씨앗 요정: 모으고 부풀기 → 꼬투리 잎 개방 → 앞으로 내밀기 → 반동·회복. 씨앗 투사체 없음. 세 갈래 실루엣은 읽히지만 세 장의 잎이 모두 같은 강도로 분리되지는 않음(판단).
- 골렘: 준비2번부터 양 주먹이 머리 위로 올라가고, 공격3·4번에 양 주먹이 바닥에 닿음. 룬은 표면에만, 충격파·먼지 없음.

정지 프레임의 루프 차이 측정은 실제 재생의 매끄러움을 증명하지 않는다. 실제 뷰어 재생·사람의 느낌 평가는 남는다.

## 확인 및 테스트

- `final_check.py`: 원본에서 최종 36행을 다시 만들고 검사. 6종·36행·168프레임, 규격 검사 failures=[] (`verification.json`, `validation.log`).
- `node tools/motion_viewer/build.mjs`: 로컬 생성물 빌드. `verify_viewer.mjs`: 이번 후보36개·신규 행12개·기존 행 인덱스·반복 설정·복사 파일 존재 확인.
- `handoff_check.py`: 추적 파일 차이·스테이징 차이 없음, 후보78개와 보고서512개를 명시한 납품 목록, 원본 참조·선택 회차·해시를 확인했다. 빌드가 만든 git-ignored `tools/motion_viewer/dist/`는 커밋 대상에서 제외한다.
- Godot 실행, 실제 플레이·브라우저 애니메이션 재생, Artifact 재게시, 게임 적용은 하지 않았다.

## 아직 잘못되거나 약한 점

골렘 대기 일부의 디테일, 골렘·사냥개의 일부 행 크기 차이, 딱정벌레·골렘·씨앗의 보행 교대, 씨앗의 짧은 팔 전진(6px)과 펼친 잎끝 y74가 남는다. 드론의 해치 열린 자세는 하부 실루엣이 크게 바뀌므로 실제 반복 재생에서 자연스러운지 사용자 확인이 필요하다. 납품을 품질 완전 통과나 사용자 채택으로 표현하지 않는다.

## 남은 작업 / 다음 권장 단계

미착수 몬스터·행은 없다. 사용자의 후보 선택과 실제 뷰어 재생 판단이 다음 단계다. 위 약점 보완·게임 연결·외부 게시는 후속 범위다. `commit.ps1`은 작성만 하고 실행하지 않았으며, 명시한 `delivery-files.txt`만 스테이징하도록 만든다. raw·기존 run.log·제품 파일·tools 소스·캐시·다른 작업 파일은 포함하지 않는다.
'''
    text+=f'\n생성 프롬프트 {sum(1 for x in prompts if x.startswith("=== "))}개. 보고서 생성 UTC {datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")}.\n'
    (p.REPORT/'README.md').write_text(text,'utf-8')
    print('REPORT written; prompts',sum(1 for x in prompts if x.startswith('=== ')))
