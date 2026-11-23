from pathlib import Path
import json,shutil,hashlib,sys
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];REPORT=ROOT/'reports/codex-art-97a';RAW=ROOT/'art/raw/xion-97a'
sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
from head_scale import face_centre,BOX
def dump(path,data):path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
rows={
 'attack':{'fps':35.25,'cell':128,'attempt':1,'status':'HOLD','note':'검토 보류: 동시 조준·발사·반동·회복 6프레임. F4 펌프 동작이 약하고 F3 위 스카프 직선거리가 앵커보다 약 11% 짧음. 2차는 원본 칸 경계 침범으로 제외. 자동 채택 금지.'},
 'shield':{'fps':12,'cell':128,'attempt':1,'status':'CANDIDATE','note':'가슴 앞에서 두 산탄총을 교차해 버티는 6프레임 방어 후보. 얼굴을 가리지 않고 스카프가 가라앉음. 게임 미연결.'},
 'victory':{'fps':8,'cell':192,'attempt':2,'status':'HOLD','note':'검토 보류: 두 총을 돌린 뒤 한 자루를 어깨에 걸치고 다른 총은 아래로 든 승리 6프레임. 마지막 장면 유지용. 2차도 프레임 사이 발 중심 가로 이동 최대 13px가 남음. 자동 채택 금지.'},
}
scarf=json.loads((REPORT/'scarf.json').read_text(encoding='utf-8'))
feet=json.loads((REPORT/'feet.json').read_text(encoding='utf-8'))
metrics={'anchor':'art/bakeoff/xion/b/xion-idle-b2.png:0','method':'내장 ImageGen, 동작당 한 원본; 실패한 동작만 두 번째 생성. normalize.py 공통 배율 한 개, LANCZOS, sharpen 60, despill auto, palette none, green #00ff00, ground-all. 프레임별 크기/위치 보정 없음.','detail_definition':'normalize.py 내부 명암 변화량. 해부학 또는 예술적 완성도 점수가 아님. 비율 기준은 앵커 6프레임 평균.','rows':{}}
for row,cfg in rows.items():
    folder=REPORT/f'{row}-trial';source=folder/f'{row}.png';out=ROOT/f'art/bakeoff/xion/b/xion-{row}-b2.png'
    shutil.copy2(source,out)
    meta={'note':cfg['note'],'fps':cfg['fps'],'frames':6,'loop':False}
    dump(out.with_suffix('.json'),meta)
    nm=json.loads((folder/'metrics.json').read_text(encoding='utf-8'))
    hm=json.loads((folder/'heads.json').read_text(encoding='utf-8'))[0]
    strip=Image.open(out).convert('RGBA');boxes=[]
    for i in range(6):
        c=cfg['cell'];f=strip.crop((i*c,0,(i+1)*c,c));cy,cx=face_centre(np.asarray(f));cx,cy=round(cx),round(cy)
        boxes.append([cx+BOX[0],cy+BOX[1],cx+BOX[2],cy+BOX[3]])
    centres=[f['centres'] for f in feet[row]['frames']]
    shift=max(abs(b[j]-a[j]) for a,b in zip(centres,centres[1:]) for j in range(min(len(a),len(b))))
    summary=nm['summary'];details=[float(f['interior_detail']) for f in nm['frames']]
    item={'status':cfg['status'],'delivered':True,'frames':6,'fps':cfg['fps'],'cell':cfg['cell'],'raw_attempt':cfg['attempt'],'factor':summary['common_scale'],'head_scale':hm,'head_template_boxes':boxes,'head_template_box_definition':'도구의 피부 중심 주변 검색창; 수동 해부학적 머리 경계가 아님.','detail':{'range':details,'mean':summary['interior_detail_mean'],'anchor_mean':summary['reference_interior_detail_mean'],'ratio':summary['interior_detail_ratio'],'per_frame_ratios':[f['interior_detail_ratio_to_reference_mean'] for f in nm['frames']]},'border_clear':summary['borders_clear'],'minimum_margin_px':min(f['margin']['minimum'] for f in nm['frames']),'spill':summary['remaining_spill_pixels'],'height_range':summary['body_height_range'],'bottom_range':summary['bottom_range'],'alpha_binary':summary['alpha_binary'],'scarf':scarf['rows'][row],'max_consecutive_foot_run_shift_px':shift,'visual_review':{'all_frames_viewed_at_4x':True,'one_face':True,'two_arms_hands_and_guns_visible':True,'coat_hair_gloves_boots_match_by_eye':True,'no_effects':True,'individual_finger_count':'이 출력 해상도에서 모든 손가락 수를 확정하지 않음'},'limitations':cfg['note'],'candidate':out.relative_to(ROOT).as_posix()}
    metrics['rows'][row]=item
    print(row,summary['common_scale'],'head',hm['median'],'detail',summary['interior_detail_range'],'ratio',summary['interior_detail_ratio'],'margin',item['minimum_margin_px'],'feet shift',shift)
metrics['rows']['defeat']={'status':'NOT_DELIVERED','delivered':False,'planned_frames':6,'planned_fps':10,'planned_cell':192,'factor':None,'head_scale':None,'detail':None,'border_clear':None,'minimum_margin_px':None,'spill':None,'attempts':2,'reason':'두 원본 모두 6x1 원본 칸 경계를 침범하여 정규화 전 실패. 원본을 다른 간격으로 잘라 다시 조립하거나 조각을 지우지 않음.','source_gate_errors':[{'attempt':1,'cell':'0,0','edge':'right'},{'attempt':2,'cell':'2,0','edge':'right'}],'visual_review':'양쪽 원본 각 6포즈를 원본 4배로 직접 검사. 2차 F5/F6 총이 몸보다 아래까지 내려와 접촉선도 확정하지 못함.'}
dump(REPORT/'metrics.json',metrics)
raws=[]
for p in sorted(RAW.glob('*.png')):raws.append({'path':p.relative_to(ROOT).as_posix(),'size':Image.open(p).size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
dump(REPORT/'provenance.json',{'tool':'builtin image_gen.imagegen','source_reference':'anchor-f1-4x.png','generations':{'attack':2,'shield':1,'victory':2,'defeat':2},'raws':raws,'selected':{'attack':1,'shield':1,'victory':2,'defeat':None}})

# Compact delivery preview, actual final pixels enlarged four times.
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
canvas=Image.new('RGB',(1536,600),'#252c39');d=ImageDraw.Draw(canvas)
for col,(row,frame) in enumerate((('attack',1),('shield',3),('victory',5))):
    cfg=rows[row];c=cfg['cell'];im=Image.open(ROOT/f'art/bakeoff/xion/b/xion-{row}-b2.png').convert('RGBA').crop((frame*c,0,(frame+1)*c,c))
    if c==192:im=im.crop((32,32,160,160))
    tile=im.resize((512,512),Image.Resampling.NEAREST);canvas.paste(tile,(col*512,64),tile)
    d.text((col*512+20,20),f'{row.upper()} F{frame+1} / {cfg["status"]}',font=font,fill='white')
canvas.save(REPORT/'delivery-preview.png')

# Annotated raw failure board; detailed source crops remain at four times source size.
raw=Image.open(RAW/'defeat-2.png').convert('RGB');board=Image.new('RGB',(raw.width,raw.height+50),'#151923');board.paste(raw,(0,50));d=ImageDraw.Draw(board)
d.text((12,12),'DEFEAT ATTEMPT 2 - REJECTED SOURCE GRID; NOT A CANDIDATE',font=font,fill='white')
for i in range(1,6):
    x=raw.width*i//6;d.line((x,50,x,board.height-1),fill='#ff4060',width=3)
board.save(REPORT/'defeat.png')

totals={}
for label,folder in [('report',REPORT),('raw',RAW),('clone',ROOT)]:
    totals[label]={'path':str(folder),'bytes':sum(p.stat().st_size for p in folder.rglob('*') if p.is_file())}
dump(REPORT/'workspace-size.json',totals)
print('sizes MiB',{k:round(v['bytes']/2**20,2) for k,v in totals.items()})
