"""Package ART-72/78-normalized candidates and 4x comparisons, new files only."""
import json, shutil, hashlib
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np

ROOT=Path('reports/codex-art-82')
ROWS=json.loads((ROOT/'selection.json').read_text(encoding='utf-8'))
FONT=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',18)
SMALL=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',15)
BG=(31,38,55)

def write(path,data):
    path=Path(path)
    assert not path.exists(),f'Never overwrite: {path}'
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def save(im,path):
    path=Path(path);assert not path.exists(),path
    path.parent.mkdir(parents=True,exist_ok=True);im.save(path)

def copy(src,dst):
    dst=Path(dst);assert not dst.exists(),dst
    dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)

def label(f,excluded=False):
    if excluded:return '측정 제외 (윙크)'
    e=f.get('eye_ratio');w=f.get('face_width_ratio')
    return f'E {e:.3f}' if w is None and e is not None else f'E {"—" if e is None else format(e,".3f")} / W {"—" if w is None else format(w,".3f")}'

def ratio_range(data,key,excluded):
    vals=[f[key] for f in data['frames'] if f.get('frame') not in excluded and f.get(key) is not None]
    return None if not vals else [min(vals),max(vals)]

def fmt_range(r):
    return '—' if r is None else f'{r[0]:.3f}' if r[0]==r[1] else f'{r[0]:.3f}–{r[1]:.3f}'

def ratio_text(d,exc):
    return fmt_range(ratio_range(d,'eye_ratio',exc))+' / '+fmt_range(ratio_range(d,'face_width_ratio',exc))

def crop(sheet,i,cell):return sheet.crop((i*cell,0,(i+1)*cell,cell))

result=[]
for row in ROWS:
    stem,move=row['stem'],row['row'];key=f'{stem}-{move}'
    attempt=ROOT/stem/move/f'attempt-{row["attempt"]}'
    best=ROOT/'best'/stem/move
    assert not best.exists(),best
    old=Path(f'art/bakeoff/{row["folder"]}/{key}-v{row["old"]}.png')
    before_face=Path(row.get('before_face',f'reports/codex-art-{row.get("before_report")}/best/{stem}/{move}/face-measured.json'))
    before=json.loads(before_face.read_text(encoding='utf-8'))
    measured=attempt/('face-measured.json' if stem.startswith('rio_') else 'face-proposed.json')
    after=json.loads(measured.read_text(encoding='utf-8'))
    exc=row.get('excluded',[])
    after['excluded_frames']=exc
    after['review_note']=row['judgment']
    after['review_limit']='4배 육안과 표식 검토. 좌표 정밀도는 정확도 보증이 아니며 얼굴 경계 판독 약 1px 오차 가능. 허용 범위 0.96~1.04를 확대하지 않음.'
    face_ok=all(.96<=f[k]<=1.04 for f in after['frames'] if f['frame'] not in exc for k in ['eye_ratio','face_width_ratio'] if f.get(k) is not None)
    after['measurable_face_passed']=face_ok
    after['candidate_delivered']=row['deliver']
    after['visual_passed']=row['deliver']
    metrics=json.loads((attempt/'metrics.json').read_text(encoding='utf-8'))
    summary=metrics['summary'];cell=metrics['normalization']['cell'];count=summary['frame_count']
    assert summary['borders_clear'] and summary['all_have_4px_margin'] and summary['alpha_binary']
    assert not any(summary['remaining_spill_pixels']) and min(summary['interior_detail_range'])>=79
    if row['deliver']:assert face_ok
    copy(attempt/f'{key}.png',best/'best-attempt.png')
    copy(attempt/'metrics.json',best/'metrics.json')
    copy(attempt/'head-scale.json',best/'head-scale.json')
    copy(before_face,best/'before-face.json')
    write(best/'face-measured.json',after)
    face_board=attempt/('face-measured.png' if stem.startswith('rio_') else 'face-landmarks-proposed.png')
    copy(face_board,best/'face-measured.png')
    old_im=Image.open(old).convert('RGBA');new_im=Image.open(best/'best-attempt.png').convert('RGBA')
    idle_version={'frey':2,'luna':3,'luna_brave':4}.get(stem,2)
    anchor=Image.open(f'art/bakeoff/{row["folder"]}/{stem}-idle-v{idle_version}.png').convert('RGBA').crop((0,0,128,128))
    unchanged=[]
    for i in range(count):
        same=bool(np.array_equal(np.array(crop(old_im,i,cell)),np.array(crop(new_im,i,cell))))
        unchanged.append(same)
        if row['deliver'] and i+1 not in row['redone']:assert same,(key,i+1,'unrequested change')
    before_frames={f['frame']:f for f in before['frames']};after_frames={f['frame']:f for f in after['frames']}
    w=512+cell*8;h=48+cell*4
    board=Image.new('RGB',(w,h*count),BG)
    for i in range(count):
        page=Image.new('RGB',(w,h),BG);d=ImageDraw.Draw(page)
        d.text((8,7),f'{key} / idle 4×',font=FONT,fill='white')
        d.text((520,7),f'기존 F{i+1}: '+label(before_frames[i+1],i+1 in exc),font=FONT,fill='white')
        state='후보' if row['deliver'] else '미전달'
        d.text((520+cell*4,7),f'{state} F{i+1}: '+label(after_frames[i+1],i+1 in exc),font=FONT,fill='white')
        a=anchor.resize((512,512),Image.Resampling.NEAREST)
        page.paste(a,(0,48+(cell//2+56-120)*4),a)
        for x,im in [(512,crop(old_im,i,cell)),(512+cell*4,crop(new_im,i,cell))]:
            tile=im.resize((cell*4,cell*4),Image.Resampling.NEAREST);page.paste(tile,(x,48),tile)
        board.paste(page,(0,i*h))
        save(page,ROOT/'comparisons'/key/f'F{i+1:02}.png')
    save(board,ROOT/f'{key}.png')
    min_margin=min(f['margin'][side] for f in metrics['frames'] for side in ['left','right','top','bottom'])
    record={**row,'cell':cell,'frames':count,'factor':summary['common_scale'],'min_margin':min_margin,'detail_range':summary['interior_detail_range'],'before_ratios':ratio_text(before,exc),'after_ratios':ratio_text(after,exc),'face_pass':face_ok,'unchanged_frames_pixel_identical':unchanged,'best':best.as_posix(),'old_file':old.as_posix()}
    if row['deliver']:
        dest_dir=old.parent;n=row['old']+1
        while (dest_dir/f'{key}-v{n}.png').exists() or (dest_dir/f'{key}-v{n}.json').exists():n+=1
        dest=dest_dir/f'{key}-v{n}.png'
        metadata=json.loads(old.with_suffix('.json').read_text(encoding='utf-8'))
        for field in ['adopted','status']:metadata.pop(field,None)
        ratios='; '.join(f'F{f["frame"]} '+label(f,f['frame'] in exc) for f in after['frames'])
        metadata.update({'note':f'ART-82 후보. {row["judgment"]} 행 공통 배율 {summary["common_scale"]}. {ratios}. 남은 점: {row["remaining"]} 게임 미연결.', 'replaces':old.name,'frames':count,'cell':cell,'feet':cell//2+56,'factor':summary['common_scale'],'fps':10 if move=='jump' else 8,'loop':move=='fall','hold_last':move!='fall'})
        copy(best/'best-attempt.png',dest);write(dest.with_suffix('.json'),metadata)
        record['candidate']=dest.as_posix()
    result.append(record)

write(ROOT/'results.json',result)
lines=['# CODEX-ART-82 결과','',f'새 후보 **{sum(r["deliver"] for r in result)}/13행**, 총 35프레임(실제 새로 교체한 프레임 9장). 4행은 요청한 수정 완료, 3행은 부분 개선 후보다. 미전달 6행은 best/와 비교판에만 보존했다. 내장 ImageGen 34회, 각 행 최대 3회. 게임 연결·Godot 실행·뷰어 배포·커밋 실행은 하지 않았다.','', '## 행별 결과','', 'E=눈 간격 / W=눈 아래 노출 얼굴 폭, 해당 폼 idle=1.000. 범위는 측정 가능한 프레임만 집계. “전달”은 새 후보 파일을 작성했다는 뜻이며 사용자 채택이 아니다.','', '| 행 | 다시 그린 F | 배율 | 전 E / W → 후 E / W | 최소 여백 | detail | 전달 |','|---|---|---:|---|---:|---:|---|']
for r in result:
    key=f'{r["stem"]}-{r["row"]}';status=('부분 전달' if r.get('partial') else '전달') if r['deliver'] else '미전달'
    lines.append(f'| [{key}]({key}.png) | {",".join(map(str,r["redone"]))} | {r["factor"]} | {r["before_ratios"]} → {r["after_ratios"]} | {r["min_margin"]}px | {r["detail_range"][0]:.2f}–{r["detail_range"][1]:.2f} | {status} |')
lines+=['','## 현재 상태와 남은 작업','']
for r in result:
    lines.append(f'- **{r["stem"]} {r["row"]}**: {r["judgment"]} **남은 작업:** {r["remaining"]}')
lines+=['','## 측정과 육안 판단','',
'- **측정:** ART-72/78의 정규화·얼굴 패치 매칭을 복사해 사용했다. Yuki/Nova와 Rio는 ART-75/77의 같은 계열 스크립트를 복사했다. 공통 배율, LANCZOS, sharpen 60, despill auto, palette none. 기존 도구는 읽기·실행만 했다.',
'- **육안:** 최종 선택 13행의 58프레임을 idle 옆 최근접 4배 판에서 직접 확인했다. 얼굴 하나, 의상, 손·무기, 동작과 발선을 확인했다. 이후 기존/수정 비교판도 검토했다. 수치가 통과해도 동작이 무너진 Frey jump는 전달하지 않았다.',
'- **얼굴 제외:** Luna victory F6는 카드가 지정한 윙크 제외를 유지했다. Nova female 및 Rio 양폼은 기준부터 반대 눈이 머리카락에 가려져 눈 간 거리 검증 불가다. 이를 통과값으로 만들지 않고 —로 표시했다.',
'- **Rio 측정:** ART-77처럼 눈 아래 노출 얼굴의 수동 경계를 사용했다. 미변경 프레임은 기존 후보와 픽셀 동일함을 검사하고 기존 표식을 유지했다. 새 male F2와 female F6은 격자에서 경계를 확인했다. 자동 제안 원본도 보존했으며 가려진 눈을 잡은 자동 E 값은 폐기했다.',
'- **한계:** 1× 얼굴 폭이 약 12~18px라 경계 1px 차이가 크다. 좌표의 소수점은 출력 정밀도이며 측정 정확도 보증이 아니다. 허용 범위 0.96~1.04를 완화하지 않았다. head_scale은 보조 검사이며 얼굴 판정이 우선이다.',
'- **원본:** 사용한 기준 이미지·생성 원본·전체 셀 조립본을 art/raw/motions-82/에 보존했다. 단일 프레임 재시도는 셀 전체를 교체했다. 생성 해상도가 다르면 전체 캔버스를 원본 셀 좌표계로 등록한 뒤 행 공통 배율을 적용했다. 머리 붙이기, 특징 코드 그리기, 프레임별 신체 크기 보정은 하지 않았다.',
'- **탈락 시도:** Frey victory 1차와 Rio male victory 1차는 원본 셀 침범으로 정규화 중단. Yuki victory 생성 2회째는 6칸 대신 2칸이라 사용하지 않았다. Frey victory 3차와 jump 3차는 자세 손상, Rio male victory 3차 F3은 발 접지 문제로 제외했다.',
'- **시도 번호:** 정규화 배율 시험이나 기존 생성 셀 조합은 새 이미지 생성이 아니다. Brave fall attempt-4는 생성 2회째, Nova female victory attempt-4와 Rio male victory attempt-4는 3회 생성 중 통과한 셀을 조합한 결과다. generation-ledger.json에 34회 프롬프트와 출력 위치를 보존했다.',
'','## 시각적 확인','', '![유키 낙하 F2 비교](comparisons/yuki-fall/F02.png)','', '왼쪽은 idle, 가운데는 기존 F2, 오른쪽은 새 F2다. 머리끝·술·소매가 위로 흩날리는 변화와 유지된 얼굴 비율을 보여준다. 모든 행의 루트 PNG는 같은 방식의 전 프레임 비교판이다.','',
'## 파일과 검증','',
'- results.json: 행별 선택 결과·수치·후보 경로·미변경 프레임 동일성. best/: 선택한 결과와 측정 원본. comparisons/: 프레임별 기존/수정 4배 판.',
'- 후보는 새 버전에만 썼고 기존 파일·제품 소스·tools/를 변경하지 않았다. commit.ps1은 명시한 파일만 stage하도록 만들었으며 실행하지 않았다. raw·__pycache__·run.log는 제외한다.',
'- audit.json에서 파일 구조·알파·여백·spill·detail·얼굴·원본 보존·커밋 범위 검증 결과를 확인할 수 있다. 실제 게임 재생은 이번 카드의 금지 사항이므로 검증하지 않았다.',
'','## 다음 권장 단계','',
'사용자가 모션 뷰어에서 7개 후보의 실제 재생을 확인하고 채택 여부를 정한다. 다음 작업에서는 미전달 6행의 얼굴/자세, Luna victory 회전 연결, Nova female 교대 잽, Rio male F3→F4 연결을 수정한다. 이 작업에서 자동 후속 실행은 예약하지 않았다.']
readme=ROOT/'README.md';assert not readme.exists();readme.write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps([{'row':f'{r["stem"]}-{r["row"]}','deliver':r['deliver'],'candidate':r.get('candidate'),'after':r['after_ratios']} for r in result],ensure_ascii=False,indent=2))
