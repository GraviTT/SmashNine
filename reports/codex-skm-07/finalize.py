"""Place whole normalized frames, measure and package SKM-07 candidates.

Run from repository root with python -B. No generation or product writes.
Original normalized strips and metrics stay untouched in attempt folders.
"""
import sys, os, json, copy, hashlib, subprocess
from pathlib import Path
sys.dont_write_bytecode = True
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
sys.path.insert(0, str(Path('tools/sprite_pipeline').resolve()))
from PIL import Image, ImageDraw
import numpy as np
import normalize as n
import head_scale as h

ROOT = Path('reports/codex-skm-07')
ANCHOR = Path('art/bakeoff/xion/b/xion-idle-b2.png')
GAME_AIR = Path('smash-nine-prototype/assets/art/xion/xion_moves_sheet.png')
CORRECTIONS = {
    '1': {'points': [[110.5,63],[120.5,63]], 'reason': '양쪽 표식을 같은 눈 아래 높이에 배치. 폭은 그대로.'},
    '2': {'points': [[110.5,63],[120.5,63]], 'reason': '양쪽 표식을 같은 눈 아래 높이에 배치. 폭은 그대로.'},
    '3': {'points': [[98.5,60],[108.5,60]], 'reason': '서로 다른 높이의 자동 표식을 눈 아래 볼 경계 y60으로 통일. 폭은 그대로.'},
    '4': {'points': [[103.5,61],[113.5,61]], 'reason': 'y60 오른쪽 표식은 바깥 붉은 윤곽을 포함. 같은 눈 아래 볼 행 y61의 피부 x104~113 경계로 측정.'},
    '5': {'points': [[96.5,64],[106.5,64]], 'reason': 'y63 왼쪽 표식이 눈/구레나룻에 걸림. y64 피부 x97~106의 좌우 경계로 측정.'},
    '6': {'points': [[95.5,62],[105.5,62]], 'reason': 'y62 왼쪽 표식을 피부 음영 픽셀 x96의 왼쪽 경계로 이동. 자동 표식은 그 픽셀 내부였음.'},
}
SPECS = [
    dict(take=2,version='v2',factor=.36,belt_x=[108,110,98,100,99,97],
         dy=[1,0,0,0,0,0],boot_roi=[None,[104,120,120,145],None,None,None,None],
         expected_boots=[138,139,146,142,146,150],name='COMPACT TUCK'),
    dict(take=3,version='v3',factor=.38,belt_x=[111,111,98,103,98,97],
         dy=[5,5,5,4,1,2],boot_roi=[None,[106,120,124,145],None,None,None,None],
         expected_boots=[139,140,146,145,145,152],name='WIDER FLARE'),
]

def save_json(path, data):
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def face_box(frame, marks):
    # Bright skin bounding box within a reviewed face ROI; ears and scarf excluded.
    left = int(np.floor(marks[2]['x']))
    right = int(np.ceil(marks[3]['x'])) + 2
    top = frame.getbbox()[1] + 5
    bottom = int(max(p['y'] for p in marks[2:])) + 7
    ys,xs = np.nonzero(h.skin_mask(np.array(frame)[top:bottom,left:right]))
    return [int(xs.min()+left),int(ys.min()+top),int(xs.max()+left+1),int(ys.max()+top+1)]

def boots(frame, roi):
    if roi is None:
        return frame.getbbox()[3]-1
    left,top,right,bottom = roi
    ys,xs = np.nonzero(np.array(frame)[top:bottom,left:right,3])
    return int(ys.max()+top)

def make_board(path, frames, data, name):
    anchor=Image.new('RGBA',(192,192))
    source=Image.open(ANCHOR).convert('RGBA').crop((0,0,128,128))
    anchor.alpha_composite(source,(32,32))
    game=Image.open(GAME_AIR).convert('RGBA')
    airs=[game.crop((i*192,1152,(i+1)*192,1344)) for i in (2,3,4,5)]
    canvas=Image.new('RGB',(2560,2400),(24,30,43));draw=ImageDraw.Draw(canvas)
    for row in range(3):
        items=[(anchor,'IDLE / feet aligned',None),
               (airs[row],f'IN GAME recoil_jump F{row+3}',None),
               (airs[row+1],f'IN GAME recoil_jump F{row+4}',None)]
        items += [(frames[j],f'{name} F{j+1}',data[j]) for j in (row*2,row*2+1)]
        for col,(frame,label,m) in enumerate(items):
            x,y=col*512,row*800
            tile=n.checker((512,768),16)
            crop=frame.crop((32,0,160,192)).resize((512,768),Image.Resampling.NEAREST)
            tile.paste(crop,(0,0),crop);canvas.paste(tile,(x,y+32))
            draw.text((x+8,y+7),label,font=n.font(15,True),fill='white')
            draw.line((x,y+32+152*4,x+511,y+32+152*4),fill=(240,75,84),width=2)
            draw.line((x+256,y+32,x+256,y+799),fill=(62,79,106),width=1)
            if m:
                boot=m['boot_y'];head=m['head_top'];box=m['face_box']
                draw.line((x+200,y+32+boot*4,x+312,y+32+boot*4),fill=(255,208,88),width=2)
                draw.text((x+8,y+720),f'boot {boot}  head {head}  face top {box[1]}',font=n.font(14),fill=(255,215,117))
                for mark in m['face_landmarks'][2:]:
                    xx=x+(mark['x']-32)*4;yy=y+32+mark['y']*4
                    draw.line((xx-3,yy,xx+3,yy),fill='cyan',width=1)
            draw.rectangle((x,y,x+511,y+799),outline=(75,90,115))
    canvas.save(path,optimize=True)

def finalize():
    reports=[]
    for spec in SPECS:
        take=spec['take'];version=spec['version']
        base=ROOT/'xion'/'shot_air_down'/f'attempt-{take}'
        if take==3:
            correction=base/'review-corrections.json';save_json(correction,CORRECTIONS)
            subprocess.run([sys.executable,'-B',str(ROOT/'review_faces.py'),'xion','shot_air_down',str(take),str(correction)],check=True)
        else:
            subprocess.run([sys.executable,'-B',str(ROOT/'review_faces.py'),'xion','shot_air_down',str(take)],check=True)
        source=base/'xion-shot_air_down.png'
        src=Image.open(source).convert('RGBA')
        original_metrics=json.loads((base/'metrics.json').read_text(encoding='utf-8'))
        face=json.loads((base/'face-measured.json').read_text(encoding='utf-8'))
        frames=[];measure=[]
        for i in range(6):
            frame=src.crop((i*192,0,(i+1)*192,192))
            dx=96-spec['belt_x'][i];dy=spec['dy'][i]
            marks=copy.deepcopy(face['frames'][i]['landmarks'])
            original_box=face_box(frame,marks)
            boot=boots(frame,spec['boot_roi'][i])
            placed=Image.new('RGBA',(192,192));placed.alpha_composite(frame,(dx,dy))
            assert np.count_nonzero(np.array(placed)[...,3])==np.count_nonzero(np.array(frame)[...,3]), 'translation clipped pixels'
            assert placed.crop(placed.getbbox()).tobytes()==frame.crop(frame.getbbox()).tobytes(), 'whole frame pixels changed'
            for mark in marks:
                mark['x']+=dx;mark['y']+=dy
            box=[original_box[0]+dx,original_box[1]+dy,original_box[2]+dx,original_box[3]+dy]
            b=placed.getbbox();ratio=face['frames'][i]['face_width_ratio']
            m=dict(frame=i+1,shift=[dx,dy],body_anchor=[96,'manually reviewed belt centre'],
                   bbox=list(b),head_top=b[1],face_box=box,face_width_ratio=ratio,
                   face_landmarks=marks,boot_y=boot+dy,boot_before=boot,
                   boot_roi_before=spec['boot_roi'][i],face_box_before=original_box,
                   margin=n.margins(b,192),**n.frame_metrics(placed))
            m['detail_ratio']=original_metrics['frames'][i]['interior_detail_ratio_to_reference_mean']
            assert .96<=ratio<=1.04
            assert n.spill_pixel_count(placed)==0 and m['margin']['has_4px_margin']
            assert m['detail_ratio']>=.90
            assert m['boot_y']==spec['expected_boots'][i], (take,i,m['boot_y'])
            frames.append(placed);measure.append(m)
        rise_head=measure[1]['head_top']-measure[2]['head_top']
        rise_face=measure[1]['face_box'][1]-measure[2]['face_box'][1]
        assert 3<=rise_head<=5 and 3<=rise_face<=5
        assert abs(measure[2]['head_top']-measure[3]['head_top'])<=2
        target=Path('art/bakeoff/xion/b')/f'xion-shot_air_down-{version}.png'
        n.save_sheet(frames,target,192)
        head=h.measure(target,h.head_template(Image.open(ANCHOR).convert('RGBA').crop((0,0,128,128))),6,.6)
        assert .96<=head['median']<=1.04
        dxs=[m['shift'][0] for m in measure]
        label='무릎을 모으는' if version=='v2' else '사격 때 다리를 넓게 벌리는'
        note=(f'{label} 공중 후보이며 얼굴 폭 1.000, 자동 머리 중앙값 {head["median"]:.3f}, '
              f'2→3 상승은 머리 {rise_head}px·밝은 피부 얼굴 상자 {rise_face}px, '
              f'부츠 최저 y는 {"/".join(map(str,spec["expected_boots"]))}이다. '
              f'배율 {spec["factor"]} 하나를 적용한 뒤 전체 프레임 배치 이동은 x={dxs}, y={spec["dy"]}px이며 게임에는 미적용했다.')
        meta={'note':note,'for':'공중 J 아래 사격','frames':6,'fps':30,'cell':192,'feet':[96,152],'loop':False,'factor':spec['factor']}
        save_json(target.with_suffix('.json'),meta)
        result=dict(take=take,version=version,source=str(source),target=target.as_posix(),source_sha256=sha(source),
                    sheet_sha256=sha(target),factor=spec['factor'],frames=measure,
                    rise_head=rise_head,rise_face_box=rise_face,head_scale=head,
                    original_metrics=original_metrics,original_face_review=face,
                    measurement_note='Head top = highest hair alpha, visually checked; face box = bright skin bbox within reviewed face ROI, not hair. Boots use alpha in verified boot-only ROI, excluding lower gun barrels in F2.')
        save_json(ROOT/f'xion-shot_air_down-{version}-checks.json',result)
        make_board(ROOT/f'xion-shot_air_down-{version}.png',frames,measure,version.upper()+' '+spec['name'])
        reports.append(result)
    # Compact actual-asset comparison, without drawing or altering sprite pixels.
    preview=Image.new('RGB',(960,1000),(24,30,43));d=ImageDraw.Draw(preview)
    for row,r in enumerate(reports):
        strip=Image.open(r['target']).convert('RGBA')
        for col,index in enumerate((1,2,5)):
            f=strip.crop((index*192,0,(index+1)*192,192)).crop((40,30,152,158)).resize((336,384),Image.Resampling.NEAREST)
            x=col*320-8;y=row*500+55;preview.paste(f,(x,y),f)
            d.text((col*320+12,row*500+14),f'{r["version"]} F{index+1}  boot y{r["frames"][index]["boot_y"]}',font=n.font(18,True),fill='white')
            d.line((col*320,y+(152-30)*3,col*320+319,y+(152-30)*3),fill=(240,75,84),width=2)
        d.text((16,row*500+457),f'head rise {r["rise_head"]}px / face-box rise {r["rise_face_box"]}px',font=n.font(18),fill=(255,208,88))
    preview.save(ROOT/'comparison.png',optimize=True)
    save_json(ROOT/'selection.json',[{'take':r['take'],'version':r['version'],'target':r['target'],'accepted':True} for r in reports])
    print(json.dumps([{'version':r['version'],'head_rise':r['rise_head'],'face_rise':r['rise_face_box'],'boots':[f['boot_y'] for f in r['frames']]} for r in reports]))

if __name__=='__main__':
    finalize()
