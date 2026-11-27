"""Package ART-100a candidates within the card's paths."""
from pathlib import Path
import json,shutil,hashlib,statistics,importlib.util,subprocess,os
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
R=ROOT/'reports/codex-art-100a';RAW=ROOT/'art/raw/jupi-100a';OUT=ROOT/'art/bakeoff/jupi'
ANCHOR=ROOT/'art/bakeoff/newchar-2026-11-26/jupi/2/jupi-idle-2.png'
spec=importlib.util.spec_from_file_location('proc',R/'process_row.py')
p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)
def dump(path,obj):path.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def frame(path,i,cell):return Image.open(path).convert('RGBA').crop((i*cell,0,(i+1)*cell,cell))
fps={'idle':6.3,'attack':35.25,'shield':12,'victory':8,'defeat':10}
ready=('idle','attack','shield')
notes={
'idle':'천둥 북잡이 대기 6프레임. F1은 지정 앵커 그대로, F2–F6은 호흡. 스태프 끝에 앵커 대비 최대 3px 차이가 남음.',
'attack':'스태프를 짧게 대각선 앞으로 찌르고 회수하는 기본 시트용 예비 공격. 두 발은 제자리에 고정.',
'shield':'턱 아래에서 양손으로 스태프를 받치는 방어. 몸을 낮추고 가슴 앞에서 유지.',
'victory':'미납품: 두 시도 모두 발 이동 3px 초과. 1차 7.5px, 2차 9px. 프레임별 위치 보정은 하지 않음.',
'defeat':'미납품: 1차 누운 몸이 바닥선 위에 있으며, 2차는 스태프가 공중에 떠 보임.'}
all_metrics={};checks=[];OUT.mkdir(parents=True,exist_ok=True)
for row in fps:
    m=json.loads((R/f'{row}-metrics.json').read_text(encoding='utf-8'))
    nm=json.loads((R/f'{row}-normalized/metrics.json').read_text(encoding='utf-8'))
    assert nm['summary']['common_scale']==m['factor'],(row,'stale metrics')
    cell=128 if row in ready else 192;src=R/f'{row}-normalized/{row}.png'
    fs=m['frames'];boots=[f['feet_band']['centres'][-2:] for f in fs] if row!='defeat' else []
    ds=[[round(b-a,3) for a,b in zip(boots[i],boots[i+1])] for i in range(5)] if boots else []
    if row=='idle':ds.append([round(b-a,3) for a,b in zip(boots[-1],boots[0])])
    ratios=[f['detail_ratio'] for f in fs]
    s={'delivered':row in ready,'status':'후보 납품' if row in ready else '미납품','attempt':m['attempt'],
       'frames':6,'fps':fps[row],'cell':cell,'factor':m['factor'],'fixed_source_anchor_x':m['fixed_source_anchor_x'],
       'head_scale':m['head']['median'] if m['head']['used']>=2 else None,'head_check':m['head'],
       'detail':{'definition':'내부 명암 변화량 / 앵커. 미술 완성도 점수가 아님.','anchor':m['anchor_detail'],
                 'ratio_range':[min(ratios),max(ratios)],'mean_ratio':round(statistics.mean(ratios),4)},
       'border_clear':all(f['border_clear'] for f in fs),'margin_min':min(f['margin']['minimum'] for f in fs),
       'spill':[f['remaining_spill_pixels'] for f in fs],'alpha_binary':all(f['alpha_binary'] for f in fs),
       'planted_boot_centres':boots,'boot_neighbour_dx':ds,
       'max_boot_dx':max(abs(x) for d in ds for x in d) if ds else None,
       'strip_sha256':sha(src),'frames_metrics':fs,'visual_judgement':notes[row]}
    if row in ready:
        assert s['border_clear'] and s['alpha_binary'] and s['margin_min']>=4 and sum(s['spill'])==0
        assert min(ratios)>=.9 and .96<=s['head_scale']<=1.04 and s['head_check']['used']>=2 and s['max_boot_dx']<=3
        dst=OUT/f'jupi-{row}-v1.png';shutil.copy2(src,dst)
        dump(dst.with_suffix('.json'),{'note':notes[row],'fps':fps[row],'frames':6,'loop':row=='idle','cell':128,'feet':120,'factor':m['factor']})
        im=Image.open(dst).convert('RGBA');assert im.size==(768,128) and sha(src)==sha(dst)
        for i in range(6):
            f=im.crop((i*128,0,(i+1)*128,128))
            assert set(f.getchannel('A').get_flattened_data())<={0,255}
            assert p.n.frame_metrics(f)['remaining_spill_pixels']==0
        checks.append({'row':row,'png_json_contract':True,'copy_sha256':True,'head_detail_margin_spill':True,'feet_max_dx':s['max_boot_dx']})
    else:assert not (OUT/f'jupi-{row}-v1.png').exists()
    all_metrics[row]=s
anc=Image.open(ANCHOR).convert('RGBA')
assert np.array_equal(np.asarray(anc),np.asarray(frame(OUT/'jupi-idle-v1.png',0,128)))
assert sha(ANCHOR)==sha(RAW/'anchor-original.png')
contact=[]
for i in (4,5):
    f=frame(R/'defeat-normalized/defeat.png',i,192);roi=(119,130,145,153)
    mask=np.asarray(f.getchannel('A'))[roi[1]:roi[3],roi[0]:roi[2]]>0
    bottom=int(np.nonzero(mask)[0].max()+roi[1])
    contact.append({'frame':i+1,'manual_body_foot_roi':list(roi),'body_bottom':bottom,'floor':152,'gap_px':152-bottom})
all_metrics['defeat']['body_contact']=contact
dump(R/'metrics.json',all_metrics);dump(R/'body-contact.json',contact)
dump(R/'feet.json',{k:{'boots':v['planted_boot_centres'],'neighbour_dx':v['boot_neighbour_dx'],'max_abs_dx':v['max_boot_dx']} for k,v in all_metrics.items() if k!='defeat'})
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
preview=p.n.checker((1536,550),24);d=ImageDraw.Draw(preview)
for j,(row,i) in enumerate((('idle',2),('attack',3),('shield',3))):
    f=frame(OUT/f'jupi-{row}-v1.png',i,128).resize((512,512),Image.Resampling.NEAREST)
    preview.paste(f,(j*512,38),f);d.text((j*512+14,9),f'{row.upper()} F{i+1} - DELIVERED',font=font,fill='white')
preview.save(R/'delivery-preview.png')
raw=Image.open(RAW/'defeat-2.png').convert('RGBA');review=R/'defeat-rejected-2';review.mkdir(exist_ok=True);panels=[]
for i in range(6):
    f=raw.crop((round(i*raw.width/6),0,round((i+1)*raw.width/6),raw.height))
    f=f.resize((round(f.width*.275)*4,round(f.height*.275)*4),Image.Resampling.NEAREST)
    f.save(review/f'F{i+1}.png');panels.append(f)
pw,ph=panels[0].size;b=Image.new('RGB',(pw*3,ph*2),(0,255,0))
for i,f in enumerate(panels):b.paste(f,((i%3)*pw,(i//3)*ph))
b.save(R/'defeat-rejected-2.png')
b=p.n.checker((1536,810),24);d=ImageDraw.Draw(b)
for j,i in enumerate((4,5)):
    f=frame(R/'defeat-normalized/defeat.png',i,192).resize((768,768),Image.Resampling.NEAREST);b.paste(f,(j*768,42),f)
    d.line((j*768,42+153*4,j*768+767,42+153*4),fill=(80,180,255),width=2)
    d.rectangle((j*768+119*4,42+130*4,j*768+145*4,42+153*4),outline=(255,170,60),width=2)
    d.text((j*768+12,10),f"F{i+1} BODY FLOOR GAP {contact[j]['gap_px']} PX",font=font,fill='white')
b.save(R/'defeat-floor.png')
head_boxes={}
for row in fps:
    cell=128 if row in ready else 192;refs=[anc]+[frame(R/f'{row}-normalized/{row}.png',i,cell) for i in range(6)]
    b=Image.new('RGB',(1344,230),(35,42,56));d=ImageDraw.Draw(b);boxes=[]
    for i,f in enumerate(refs):
        c=p.h.face_centre(np.asarray(f));cy,cx=(round(c[0]),round(c[1])) if c else (30,25)
        box=(cx-25,cy-30,cx+23,cy+18);boxes.append(list(box));cr=f.crop(box).resize((192,192),Image.Resampling.NEAREST)
        b.paste(cr,(i*192,38),cr);d.text((i*192+7,7),'ANCHOR' if i==0 else f'F{i}',font=font,fill='white')
    b.save(R/f'{row}-heads-4x.png');head_boxes[row]={'review_crop_boxes':boxes[1:],'anatomical_segmentation':False}
dump(R/'head-boxes.json',head_boxes)
prompts=sorted(R.glob('prompt-*.txt'));assert len(prompts)==9,[x.name for x in prompts]
(R/'prompts.txt').write_text('\n\n'.join('=== '+x.name+' ===\n'+x.read_text(encoding='utf-8') for x in prompts)+'\n',encoding='utf-8')
raws=['idle-1','idle-2','attack-1','attack-2','shield-1','victory-1','victory-2','defeat-1','defeat-2']
assert all((RAW/(x+'.png')).exists() for x in raws)
dump(R/'provenance.json',{'clock_checks_after_generation_utc':{"idle-1":"2026-11-27 11:13:53 UTC","idle-2":"2026-11-27 11:17:14 UTC","attack-1":"2026-11-27 11:19:43 UTC","attack-2":"2026-11-27 11:21:32 UTC","shield-1":"2026-11-27 11:22:57 UTC","victory-1":"2026-11-27 11:25:57 UTC","victory-2":"2026-11-27 11:35:49 UTC","defeat-1":"2026-11-27 11:38:41 UTC","defeat-2":"2026-11-27 11:46:01 UTC"},'generator':'built-in image_gen','reference':'art/raw/jupi-100a/anchor-4x.png',
 'generations':{x:sha(RAW/(x+'.png')) for x in raws},'selected':{'idle':2,'attack':2,'shield':1},
 'held':{'victory':[1,2],'defeat':[1,2]},'idle_f1':'Unchanged whole anchor frame; generated F1 unused; no body-part compositing'})
branch=subprocess.run(['git','branch','--show-current'],cwd=ROOT,capture_output=True,text=True,check=True).stdout.strip()
diff=subprocess.run(['git','diff','--name-only','--','smash-nine-prototype'],cwd=ROOT,capture_output=True,text=True,check=True).stdout.strip()
assert branch=='codex/jupi-100a' and not diff
size=0;errors=[]
def onerror(e):errors.append(str(e))
for base,dirs,files in os.walk(ROOT,onerror=onerror,followlinks=False):
    for fn in files:
        try:size+=(Path(base)/fn).stat().st_size
        except OSError as e:errors.append(str(e))
task=sum(f.stat().st_size for folder in (R,RAW) for f in folder.rglob('*') if f.is_file())
dump(R/'workspace-size.json',{'path':str(ROOT),'workspace_bytes':size,'workspace_GiB':round(size/2**30,3),'task_MiB':round(task/2**20,2),'errors':errors})
dump(R/'validation.json',{'checks':checks,'anchor_f1_exact':True,'anchor_source_unchanged':True,'branch':branch,
 'product_tracked_diff_empty':not diff,'raw_generations':9,'prompts':9,'game_run':False,'commit_executed':False,'held_rows_absent_from_bakeoff':True})
lines=[]
for row,v in all_metrics.items():
    hs=f"{v['head_scale']:.2f} ({v['head_check']['used']}/6)" if v['head_scale'] is not None else '수동 비교 (자동 유효 1/6)'
    lines.append(f"| {row} | 6 | {fps[row]} | {v['factor']:.3f} | {hs} | {v['detail']['mean_ratio']*100:.2f}% | {v['status']} |")
readme=f"""# ART-100A · Jupi 천둥 북잡이 기본 동작

**완료:** 대기·공격·방어 3행, 18프레임을 후보로 납품했다. **현재 상태:** 승리·패배는 두 번씩 생성했으나 아래 기준을 충족하지 못해 미납품이다. 게임 연결과 Godot 실행은 하지 않았다. commit.ps1은 작성만 했고 실행하지 않았다.

| 행 | 프레임 | fps | 공통 factor | 머리 배율 / 유효 프레임 | 디테일 평균 / 앵커 | 상태 |
|---|---:|---:|---:|---|---:|---|
{chr(10).join(lines)}

미납품 행의 수치는 보고서 검토본 값이다(승리 2차, 패배 1차). 자동 점수 0.6 이상이 두 프레임 미만인 패배는 자동 중앙값 1.00을 합격값으로 쓰지 않았다.

![납품 후보 4배](delivery-preview.png)

왼쪽부터 실제 납품 대기 F3, 공격 F4, 방어 F4의 최근접 4배 확대다. 각 행의 전체 판은 idle.png, attack.png, shield.png, victory.png, defeat.png에 있다. 192칸은 개별 4배 프레임도 직접 확인했다.

## 측정한 것

- normalize.py: LANCZOS, sharpen 60, despill auto, palette none, 초록 배경 제거, ground-all. 행마다 공통 배율 하나와 가로 기준점 하나만 썼다. 공용 도구 수정이나 몸 부위 붙이기는 없다.
- 대기 F1은 카드 지시대로 앵커 **전체 프레임 그대로**다. 원본 앵커 해시와 F1 RGBA 배열 일치를 확인했다.
- 납품 세 행 모두 이진 알파, 경계 침범 0, 초록 번짐 0, 최소 여백 7px. 모든 프레임 디테일은 앵커의 90% 이상이다. 디테일은 내부 명암 변화량이며 미술 완성도 점수가 아니다.
- 두 부츠 하단 띠의 중점을 순서대로 대응했다. 대기는 왼쪽 스태프 접촉점을 제외하고 루프도 포함했다. 최대 발 이동: 대기 {all_metrics['idle']['max_boot_dx']}px, 공격 {all_metrics['attack']['max_boot_dx']}px, 방어 {all_metrics['shield']['max_boot_dx']}px.
- 고정 가로 기준점(원본 칸 x): 대기 194.5, 공격 182.0, 방어 176.5. 방어는 원본 두 부츠 중점의 중앙값 하나를 썼다. 프레임별 위치 보정은 없다.
- 승리 1차 발 이동 최대 7.5px, 2차 {all_metrics['victory']['max_boot_dx']}px. 공통 기준점으로 정리해도 원본 이동이 남는다.
- 패배 1차 F5/F6 몸의 오른쪽 부츠 영역을 직접 지정해 잰 바닥 간격은 {contact[0]['gap_px']}/{contact[1]['gap_px']}px다. defeat-floor.png의 파란 선은 발선 바로 아래, 주황 상자는 스태프를 제외한 측정 영역이다.
- head-boxes.json은 검토용 크롭 좌표이며 해부학적 머리 분할 결과가 아니다. 패배의 기울어진 머리는 전체 4배 판과 크롭을 육안 비교했다.

## 직접 본 것

- 납품 세 행에서 검은 단발·옆 땋은 머리, 흰 의식복, 노란 매듭·술, 짙은 타이츠·흰 부츠, 다섯 북이 달린 스태프가 유지된다. 얼굴은 하나이며 손과 스태프가 얼굴을 가리지 않는다. 이펙트는 없다. 모든 손가락 수를 확정할 해상도는 아니다.
- 대기는 상체·매듭이 작게 호흡한다. F1 원본과 새 프레임 사이에 스태프 끝 최대 3px 높이 차이와 옷 주름·끈 세부 변화가 남는다. 완벽히 고정된 소품 또는 깜빡임 없는 재생이라고 주장하지 않는다.
- 공격은 F4에서 가장 뚜렷하게 뻗고 회수한다. 짧은 대각 찌르기여서 동작 폭은 작다. 기본 시트 예비 공격 후보로 제출한다.
- 방어는 스태프를 허리에서 턱 아래로 올리고 몸을 낮춘 뒤 유지한다.
- 승리는 회전·미소가 읽히지만 발이 미끄러져 미납품이다. 2차는 마지막 스태프를 손으로 잡지만 발 이동이 해결되지 않았다.
- 패배 1차는 여섯 단계가 읽히지만 몸이 바닥에 닿지 않는다. 2차는 스태프가 공중에 떠 보인다. 어느 것도 bakeoff 완성 후보로 복사하지 않았다.

## 제작 이력과 확인

내장 ImageGen만 사용했다. 대기 2회, 공격 2회, 방어 1회, 승리 2회, 패배 2회, 총 9회다. 원본과 앵커는 art/raw/jupi-100a/, 모든 프롬프트는 prompts.txt에 있다. 지정 Python과 Pillow/numpy만 사용했고 패키지를 설치하지 않았다.

대기 1차는 발 사이 검은 잔여 픽셀로 제외했다. 공격 1차는 F4 스태프가 원본 균등 칸의 오른쪽 경계에 닿아 도구가 거부했다. 칸을 임의 간격으로 다시 자르거나 조각을 지우지 않았다. 실패 원본도 확대 검토 자료로 남겼다.

PNG/JSON 규격, fps·반복 정보, 복사본 해시, 앵커 F1, 머리·디테일·여백·번짐·발 이동을 확인했다(validation.json). 실시간 애니메이션이나 Godot 재생은 검증하지 않았다. rebuild.ps1은 같은 정규화 재현용으로 작성했으며, 전체를 재실행했다고 주장하지 않는다.

로컬 저장 도구 두 차례 실패와 명령 응답 지연이 있었다. 실패한 프롬프트 저장은 PowerShell의 명시적 UTF-8 쓰기로 완료했다. 파일 존재와 해시를 확인했다.

## 남은 작업 / 다음 권장 단계

리드가 납품 3행을 검수하고 설치 여부를 결정한다. 승리는 고정된 발을 유지하는 원본, 패배는 몸과 떨어진 스태프가 함께 바닥에 놓이는 원본을 다시 그려야 한다. 카드의 2회 한도를 소진해 추가 생성하지 않았다. 다른 클론의 걷기·점프·낙하·피격·착지는 범위 밖이다. 새 할 일 위젯 항목은 만들지 않았다.

전체 클론 {ROOT}: **{size/2**30:.3f}GiB**, 이번 report+raw 약 **{task/2**20:.1f}MiB**. 크기 검사 오류 {len(errors)}건. 큰 영상 중간 파일은 만들지 않았다.
"""
(R/'README.md').write_text(readme,encoding='utf-8')
paths=['design/tasks/CODEX-ART-100.md']
paths += [str(f.relative_to(ROOT)).replace('\\','/') for f in sorted(OUT.glob('jupi-*-v1.*')) if any(f.name.startswith('jupi-'+r+'-v1.') for r in ready)]
paths += [str(f.relative_to(ROOT)).replace('\\','/') for f in sorted(R.rglob('*')) if f.is_file() and f.name!='commit.ps1']
paths += ['reports/codex-art-100a/commit.ps1']
assert len(paths)==len(set(paths)) and all(not x.startswith(('art/raw/','smash-nine-prototype/')) for x in paths)
ps="$ErrorActionPreference = 'Stop'\n$paths = @(\n"+''.join("    '"+x+"'\n" for x in paths)+")\n"
ps+="$message = @'\nAdd Jupi idle attack and shield candidates; document held rows\n\nCo-Authored-By: Codex <noreply@openai.com>\n'@\n"
ps+="git add -- $paths\nif ($LASTEXITCODE -ne 0) { throw 'git add failed' }\ngit diff --cached --check -- $paths\nif ($LASTEXITCODE -ne 0) { throw 'whitespace check failed' }\ngit commit --only -m $message -- $paths\nif ($LASTEXITCODE -ne 0) { throw 'git commit failed' }\n"
(R/'commit.ps1').write_text(ps,encoding='utf-8')
print(json.dumps({'delivered':list(ready),'held':['victory','defeat'],'head':{k:v['head_scale'] for k,v in all_metrics.items()},'detail_mean_percent':{k:round(v['detail']['mean_ratio']*100,2) for k,v in all_metrics.items()},'body_contact':contact,'workspace_GiB':round(size/2**30,3),'task_MiB':round(task/2**20,2),'commit_paths':len(paths)},ensure_ascii=False))
