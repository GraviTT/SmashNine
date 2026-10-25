"""Write Korean handoff, reviewed visual notes and an explicit commit file list."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json
from pathlib import Path
from PIL import Image, ImageDraw
from audit import ROOT, OUT, digest
from repair import dump, FONT
JUDGMENTS={
'C01':'6장 모두 어깨 룬·얼굴·주먹과 발 자세 유지. 소폭 재축소로 내부 질감과 픽셀 계단이 바뀜.',
'C02':'F2–4 두 주먹과 룬 보존. 외곽을 자르지 않고 전신만 1px 이동.',
'C03':'F3 떠 있는 돌과 밝은 핵 배치 유지. 오른쪽 돌의 경계 여유 확보.',
'C04':'F3 새총과 뒤 옷자락 유지. 1px 이동 이외 그림 변화 없음.',
'C05':'F3 엄니와 등가시 보존. C16과 함께 앞 엄니 준비→공격 간격은 8→6px로 줄어듦.',
'C06':'ART-83 v2의 공중 F3/F4는 QA 당시 v1과 다른 그림이고 경계 안쪽에 충분히 있음. 수정하지 않음.',
'C07':'F1–6 녹색 몸·흰 꽃·손 가지가 이어짐. F3뿐 아니라 F4도 여백 부족. 재축소로 잎의 미세 질감은 조금 바뀜.',
'C08':'F1 양 주먹의 위쪽이 3px 선에 닿음. 발을 내리거나 배율을 바꾸지 않고는 4px로 옮길 수 없음.',
'C09':'원본 전체 칸과 머리 확대에서 외곽선이 닫혀 있음. 맨 위 긴 선은 주로 머리 뒤 얼음 가시의 완만한 윗변이다. 전체 F1 재슬라이스로 직선이 8→5px로 완화됐으나 원본의 완만한 가시 모양은 남음. 새 머리나 귀를 덧그리지 않음.',
'C10':'F1 피격에서 두 주먹·룬·얼굴 형태 유지, 왼쪽 여백 확보.',
'C11':'F4 누운 날개·구형 머리·촉수 끝 유지.',
'C12':'F2 낮춘 뿔과 뒤 다리 유지. 발 높이 유지.',
'C13':'F2 날개 끝과 금색 원판 보존. 비행 그림 전체를 1px 아래로 이동했으며 지상 접지 판정 대상 아님.',
'C14':'F1–4 낮아지는 순서와 감기는 눈 유지. 공통 재축소 때문에 미세 명암·계단은 달라짐.',
'C15':'최종 원본 재구축 F1·3·4를 재검수. 후드·귀·새총과 누운 자세가 유지됨. F2는 새 공통 배율의 반올림 결과가 기존과 픽셀 동일.',
'C16':'F4 웅크린 몸과 엄니 보존. 오른쪽 1px 이동으로 준비→공격 간격 감소에 기여.',
'C17':'F4 누운 갑각·엄니 외곽 유지.',
'C18':'F4 접힌 날개와 감은 눈 유지.',
'C19':'F3·4 포구·구형 몸체·날개/기어 외곽 유지.',
'C20':'F3 씨앗 몸·꽃·가지 유지. 오른쪽 꽃 끝 여백 확보.',
'C21':'F4 눕는 덩굴 몸과 잎 형태 유지. ART-83 색·질감은 픽셀 그대로 평행이동.',
'C22':'F4 왼쪽 뿌리 여백은 확보. F1 위쪽 봉오리는 3px로 남으며 접지 조건 때문에 유지.',
'C23':'F2 눈·꽃봉오리·촉수 끝 유지. 비행 중심이 가로로 1px 이동한 후보.'}
def status(c):
    if c['id']=='C06':return '수정 불필요(최신 v2)'
    if c['id']=='C08':return '미수정'
    if c['id']=='C22':return '부분 수정'
    return '수정'
def main():
    repairs=json.loads((OUT/'repairs.json').read_text('utf-8'));delivery=json.loads((OUT/'delivery.json').read_text('utf-8'));verification=json.loads((OUT/'verification.json').read_text('utf-8'));base=json.loads((OUT/'baseline.json').read_text('utf-8'));sizes=json.loads((OUT/'sizes.json').read_text('utf-8'))
    reviews=[]
    for c in repairs:
        boards=sorted(p.name for p in OUT.glob(c['id']+'-*-4x-*.png'))
        reviews.append(dict(id=c['id'],changed_frames=c['changed_frames'],boards=boards,reviewed_by='Codex root: direct tool image viewing at original detail, nearest 4x',judgment=JUDGMENTS[c['id']],output_sha256=digest(ROOT/c['output']) if c['output'] else None))
    dump(OUT/'visual-review.json',reviews)
    # Compact exact-4x preview: two representative frames before and after.
    preview=Image.new('RGB',(800,880),(24,29,40));d=ImageDraw.Draw(preview)
    for row,(cid,idx) in enumerate([('C01',4),('C09',1)]):
        c=next(x for x in repairs if x['id']==cid)
        for col,path in enumerate([OUT/'before'/Path(c['source']).name,ROOT/c['output']]):
            crop=Image.open(path).convert('RGBA').crop(((idx-1)*96,0,idx*96,96)).resize((384,384),Image.Resampling.NEAREST)
            tile=Image.new('RGBA',(384,384),(39,44,56,255));tile.alpha_composite(crop)
            x=8+col*400;y=48+row*440;preview.paste(tile.convert('RGB'),(x,y))
            d.text((x,y-32),f'{cid} F{idx} '+('BEFORE' if col==0 else 'AFTER')+' 4x',font=FONT,fill='white')
    preview.save(OUT/'overview.png')
    lines=['# ART-88 — 몬스터 후보 여백·늑대 피격·JSON 보완','',
    '**완료:** 후보 21행·39프레임 수정, JSON 43개 누락 필드 보완, 576×576 시트 14장 재조립. QA-23 23건 중 수정 20건, 최신 v2에서 수정 불필요 1건, 부분 수정 1건, 미수정 1건이다.',
    '**현재 상태:** 정적 검사 1,419개에서 예상 밖 실패 0. **C08 F1 / C22 F1의 3px 상단 여백은 미해결**로 제외·공개했으며 모든 항목 통과라는 뜻이 아니다. 후보만 수정했고 게임 적용·Godot·뷰어 빌드·이미지 생성·설치·다운로드·git stage/commit은 하지 않았다.','',
    '## QA-23 ID별 결과','',
    '측정: QA-23과 동일하게 alpha≥128, 셀 외곽 1px 접촉과 안쪽 4px 경계 픽셀 수를 각각 센다. alpha>0도 함께 측정했으며 이번 그림은 alpha 0/255라 같다. 원래 목록의 `F3=3px`는 **경계 안 픽셀 수**이며 여백 거리 3px라는 뜻이 아니다. 아래 수치는 최신 입력(v2 우선)의 **최소 여백 거리**다. bbox는 오른쪽/아래 제외 좌표, 발 y72는 포함 좌표다.','',
    '| QA | 몬스터 / 행 | 판정 | 측정·수정 | 4배 직접 확인 |','|---|---|---|---|---|']
    for c in repairs:
        mid=c['monster'];row=c['row'];cid=c['id']
        if cid=='C06':summary='F3 5px, F4 9px; v2 전 6장 경계 픽셀 0. v1은 각 3px.'
        elif cid=='C08':summary='F1 상단 3px·하단 y72 유지; 높이 70px.'
        elif cid=='C09':summary='F1 원본 전체 재슬라이스. 상단 직선 8→5px, 여백 6→6px, 발 y72. F2 그대로.'
        elif cid=='C22':summary='F4 여백 3→4px; F1 상단 3px 미해결.'
        else:
            bad=[o for o in c['operations'] if o['before']['solid']['inside_4px']]
            summary=', '.join('F'+str(o['frame']) for o in bad)+' 여백 3→4px; '
            if c['scale']!=1:summary+=f'행 공통 factor {next(x for x in sizes if x["id"]==cid)["factor_before"]}→{next(x for x in sizes if x["id"]==cid)["factor_after"]}.'
            else:summary+='전체 그림 1px 이동.'
            if cid=='C07':summary+=' 최신 v2 F4 추가 확인.'
        links=' · '.join(f'[{i+1}]({p})' for i,p in enumerate(next(x for x in reviews if x['id']==cid)['boards']))
        lines.append(f'| {cid} | `{mid}` / {row} | {status(c)} | {summary} | {links} |')
    lines+=['','### 미해결 이유와 부수 변화','',
    '- **C08 / C22 F1:** 접지 그림 높이 70px, top=3, bottom=72다. top≥4와 bottom=72를 동시에 만족할 수 있는 높이는 69px다. 전신을 1px 내리면 발 y73이 된다. 두 행의 최대 폭은 각각 74px·84px로 88px 이하이므로 카드의 “폭 88px 초과 때만 행 배율 축소” 조건에 따라 줄이거나 일부를 잘라내지 않았다. C08 행은 만들지 않았고 C22 v2에는 F4 이동만 반영했다.',
    '- **멧돼지 C05+C16:** 이전 ART-76 fix-1의 동일 엄니 표식 `(84,64)→(92,59)`가 `(85,64)→(91,59)`로 이동해 전진 간격 **8→6px**가 됐다(끝점 불확실성 약 ±1px, 간격 ±2px). 모두 실제 불투명 픽셀임을 확인했다. 이 간격은 게임 이동량/공격 판정이 아니다. 여백 수리는 완료했지만 종전 전진 목표 8px는 다시 충족하지 못하므로 리드 검토 대상이다.','',
    '## 시각적 확인','',
    '![골렘 보행 F4와 늑대 피격 F1 전후, 정확히 4배](overview.png)','',
    '왼쪽은 작업 전, 오른쪽은 작업 후다. 위는 골렘의 양쪽 여백 확보, 아래는 늑대 원본 재슬라이스 결과다. 실제 게임 화면이 아닌 후보 PNG 비교다. 개별 보드는 위=전/아래=후이며 회색 사각형이 4px 안전선, 분홍 선은 y72 픽셀 아래쪽 경계다. 변경된 39프레임을 모두 원본 크기의 4배 보드로 직접 봤다. 미해결 F1 두 장과 C06 최신 v2도 별도 확인했다.','',
    '### 늑대 원본 판단','',
    '[원본 전체 칸과 머리 확대](C09-raw-evidence.png)에서 머리·얼음 가시의 외곽은 닫혀 있고 원본 경계와 떨어져 있다. 원본 절단은 관찰하지 않아 이미지 도구는 사용하지 않았다. 두 칸 1774×887 원본에서 첫 887×887 칸의 **전신**을 다시 읽었다. 기존 tight bbox 축소 대신 투명 주변 40px를 포함하고 같은 factor 0.105, LANCZOS + unsharp 60 + despill auto, alpha 0/255로 재구축했다. F2는 픽셀 동일하다.','',
    '측정상 top y21·최소 여백 6px는 같고 최상단 연속 길이는 8→5px다. 육안상 긴 수평 마감은 완화됐지만 원본 얼음 가시의 낮은 기울기 자체는 남는다. 이 결과를 새 머리/귀를 그려 복원한 것으로 설명하지 않는다.','',
    '## 배율과 같은 부위 크기','',
    'C01·C07·C14는 기존 최신 전체 그림에 행 공통 축소를 적용했고, C15는 최종 고해상도 원본에서 한 번 축소했다. 모두 폭이 88px를 넘은 행뿐이다. 다른 행은 전신 평행이동이며 투명 bbox 내부 RGBA가 이동 전후 그대로임을 검증했다.','',
    '| QA | 같은 부위 / 대표 프레임 | 기준 idle → 수정 전 → 후 | 후/idle | 근거 |','|---|---|---|---|---|']
    for s in sizes:lines.append(f'| {s["id"]} | {s["part"]} / F{s["sample_frame"]} | {s["idle"]["size"]:.3f} → {s["before"]["size"]:.3f} → {s["after"]["size"]:.3f} | {s["ratio"]:.4f} | [4배 눈금]({s["id"]}-size-4x.png) |')
    lines+=['','명목 비율은 ±5% 안이다. C01/C07/C14는 ART-74 fix-1 또는 ART-83의 수동 경계를 전체 변환으로 추적해 픽셀 경계로 반올림했다(경계 ±1px). C15는 같은 후드 색 마스크의 최대 연결 영역 √면적을 다시 쟀고, y48 자르기 선에 닿지 않았다. 대표 부위의 투영/색 면적 지표이며 전 프레임 해부학 크기 인증은 아니다. [크기 원자료](sizes.json).','',
    '## JSON 43개 — 누락 필드만 추가','',
    '원래 키·값·note는 모두 동일하다. Frey/Luna 계열 8개에 cell=128·feet=120을, 나머지 35개에는 loop를 추가했다. fall의 누락 loop만 true, 나머지 누락 loop는 false다. 이미 있는 cell=192·feet=152 등은 유지했다. ART-68/69/72/75/77 규격 및 ART-81 예외 목록과 대조했다. Nova female hurt-v2의 기존 1칸 PNG 규격 문제는 이번 JSON 보완과 별개이며 이미지 변경 대상이 아니다.','',
    '| JSON 경로 | 추가한 필드 |','|---|---|']
    for m in delivery['metadata']:lines.append(f'| [{m["path"]}](../../{m["path"]}) | `'+json.dumps(m['added'],ensure_ascii=False)+'` |')
    lines+=['','## 재조립한 시트 14장','',
    '모두 `art/bakeoff/monsters/`의 576×576 PNG다. 행 순서 idle/walk/windup/attack/hurt/defeat, 최신 v2가 있으면 v2·없으면 v1을 사용했다. 14×6=84행 모두 원본 행과 픽셀 동일하다. 수호자 시트에는 위에서 공개한 상단 여백 두 건이 남아 있다.','',
    '| 시트 | 이번에 바뀐 행 |','|---|---|']
    for sh in delivery['sheets']:
        mid=Path(sh['path']).name.removesuffix('_sheet-v2.png')
        changed=', '.join(c['row'] for c in repairs if c['monster']==mid and c['output'])
        lines.append(f'| [{Path(sh["path"]).name}](../../{sh["path"]}) | {changed} |')
    lines+=['','## 확인 및 인계','',
    '- [verification.json](verification.json): 정적 검사 1,419개, 예상 밖 실패 0. 공개 미해결 2프레임을 통과로 세지 않았다. 변경 행의 RGBA 규격, 이진 알파, 빈 패딩, 4px 경계(미해결 두 장 제외), 발/하단 유지(비행 까마귀 1px 하강 제외), 시트 84행 조립 일치를 검사했다.',
    '- 원래 PNG/읽기 전용 QA·감사 파일 중 변경 대상이 아닌 479개 SHA-256 일치. 모든 v1 PNG 보존. 원본 raw 두 장 해시 일치. `smash-nine-prototype/`·`tools/` 추적 파일 변경 없음. git index 비어 있음.',
    '- [visual-review.json](visual-review.json): 변경한 모든 프레임의 직접 4배 관찰 기록. 정지 PNG 검수이며 Godot·실제 애니메이션 재생·플레이 테스트는 하지 않았다.',
    '- [commit.ps1](commit.ps1)은 **작성과 구문 검사만**, 실행하지 않았다. [delivery-files.txt](delivery-files.txt)에 적힌 파일만 대상으로 하며 카드·프롬프트를 포함한다. `qa23/`, `ref81/`, 다른 유닛 보고서, raw, 중간 검토용 review-rows, run.log, __pycache__는 제외한다.',
    '- 재검증: 지정 Python에 `-B`로 `verify.py` 실행. `repair.py`는 보존한 입력 `before/`에서 report의 검토 PNG/보드만 재생성하며 제품 후보에는 쓰지 않는다. `sizes.py`는 크기 자료를 재생성한다. `audit.py`와 `deliver.py`는 기존 baseline/delivery가 있으면 덮어쓰기 방지로 중단한다.',
    '', '**남은 작업 / 다음 권장 단계:** 리드가 C08·C22 F1에서 높이 때문에 필요한 행 축소도 허용할지 결정하고, 멧돼지의 전진 간격 감소와 후보 연결을 모션 뷰어에서 검토한다. 사용자의 후보 선택·게임 연결은 수행하지 않았다.','']
    (OUT/'README.md').write_text('\n'.join(lines),'utf-8')
    report_names=['README.md','audit.py','repair.py','sizes.py','deliver.py','verify.py','finish.py','baseline.json','repairs.json','sizes.json','delivery.json','verification.json','visual-review.json','overview.png','C09-raw-evidence.png','commit.ps1','commit-message.txt','delivery-files.txt','commit-syntax.json','delivery-check.json']
    report_names += [p.name for p in sorted(OUT.glob('C*-*4x*.png'))]
    report_names += ['before/'+p.name for p in sorted((OUT/'before').glob('*.png'))]
    paths=delivery['rows']+[x['path'] for x in delivery['metadata']]+[x['path'] for x in delivery['sheets']]
    paths+=['reports/codex-art-88/'+p for p in report_names]+['design/tasks/CODEX-ART-88.md','design/tasks/CODEX-ART-88.prompt.md']
    paths=sorted(set(paths));(OUT/'delivery-files.txt').write_text('\n'.join(paths)+'\n','utf-8')
    (OUT/'commit-message.txt').write_text('art: repair monster candidate margins and complete metadata (ART-88)\n\nRepair 21 rows, re-slice the wolf hurt frame, complete 43 JSON files, and rebuild 14 sheets. Record two remaining top-margin conflicts and the boar reach tradeoff.\n\nCo-Authored-By: Codex <noreply@openai.com>\n','utf-8')
    print('report and file list written:',len(paths),'paths')
if __name__=='__main__':main()
