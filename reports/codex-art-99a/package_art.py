"""ART-99a: whole-image framing, face crops, contact sheets, measured QA. No part edits."""
from pathlib import Path
import json, sys, shutil, hashlib
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'art/raw/newchar-99a'
OUT = ROOT / 'art/bakeoff/newchar-2026-11-26'
REPORT = Path(__file__).resolve().parent
FONT = 'C:/Windows/Fonts/malgun.ttf'
LOOKS = [
    dict(c='borok',n=1,title='보로크 1 · 제련왕',idle='borok1-idle-v6.png',head=[53,14,87,48],body_top=12,skull_top=14,chin=48,illustration_landmarks=[312,470,1478],eye=390,ref='rio_female'),
    dict(c='borok',n=2,title='보로크 2 · 무쇠 거인',idle='borok2-idle-v6.png',head=[43,11,86,47],body_top=10,skull_top=11,chin=47,illustration_landmarks=[315,484,1491],eye=384,ref='rio_female'),
    dict(c='borok',n=3,title='보로크 3 · 젊은 대장장이',idle='borok3-idle-v2.png',head=[44,15,87,49],body_top=13,skull_top=15,chin=49,illustration_landmarks=[287,458,1483],eye=376,ref='rio_female'),
    dict(c='jupi',n=1,title='주피 1 · 폭풍 지휘자',idle='jupi1-idle-v2.png',head=[43,34,78,68],body_top=31,skull_top=34,chin=68,illustration_landmarks=[234,409,1494],eye=335,ref='nova_female'),
]

def font(size):return ImageFont.truetype(FONT,size)

def metrics_and_boards():
    data={
        'task':'CODEX-ART-99 / art-a', 'branch':'codex/newchar-99a',
        'definitions':{
            'automated':'Pillow alpha bbox and pipeline pixel checks. Sprite bbox includes weapon; Jupi body height is separately measured excluding staff.',
            'manual':'Skull/chin/sole landmarks picked visually, not automatic anatomy detection. Main hair volume included; detached hair tips/ahoge, circlet and long beard excluded. Sprite landmark uncertainty ±2 px; illustration ±10 px, Borok1 chin obscured by beard ±15 px.',
            'head_count':'(sole_y - skull_top + 1) / (chin_y - skull_top + 1); illustrative proportions under chosen manual landmarks, not exact anatomical truth.',
            'detail':'normalize.py interior_detail: local interior RGB contrast, ratio to FIRST installed idle frame only. Not a semantic art-quality score.',
            'body_width':'Sprite bbox includes axe, fur and hair; does not represent hitbox width.',
        },'looks':[], 'roster':[]}
    labels=['Frey','Rio 여성','Nova 여성','Luna','Xion']
    ids=['frey','rio_female','nova_female','luna','xion']
    entries=[]
    for label,ident in zip(labels,ids):
        im=Image.open(RAW/f'{ident}-idle-ref.png').convert('RGBA');entries.append((label,im))
        b=im.getbbox();data['roster'].append({'id':ident,'bbox':list(b),'height':b[3]-b[1],'width':b[2]-b[0]})
    concepts=Image.new('RGB',(1920,1260),'#20242b');cd=ImageDraw.Draw(concepts)
    cd.text((28,18),'ART-99a · 보로크 1 / 2 / 3 → 주피 1',font=font(28),fill='#f4eddf')
    cd.text((28,56),'원화는 비교용 축소 · 아래 대기는 동일한 3배 픽셀 배율 · 게임 미적용 후보',font=font(18),fill='#b7bcc4')
    faces=Image.new('RGB',(1120,610),'#2a2d34');fd=ImageDraw.Draw(faces)
    for idx,look in enumerate(LOOKS):
        c,n=look['c'],look['n'];tag=f'{c}{n}';dest=OUT/c/str(n)
        im=Image.open(dest/f'{c}-idle-{n}.png').convert('RGBA');ill=Image.open(dest/f'{c}_illustration-{n}.png').convert('RGBA')
        entries.append((look['title'],im))
        note=look['title']+' — 외형 선택용 대기 1프레임. 게임 미적용.'
        write_json(dest/f'{c}-idle-{n}.json',{'note':note,'frames':1})
        pipeline=json.loads((REPORT/'normalize'/tag/'metrics.json').read_text(encoding='utf-8'))
        framing=json.loads((REPORT/f'{tag}-framing.json').read_text(encoding='utf-8'))
        a=np.asarray(ill);alpha=a[:,:,3];box=ill.getbbox();sk,ch,sole=look['illustration_landmarks']
        h=look['chin']-look['skull_top']+1;ah=121-look['skull_top']
        item={'id':tag,'delivered':True,
            'illustration':{'file':str((dest/f'{c}_illustration-{n}.png').relative_to(ROOT)).replace('\\','/'),'size':list(ill.size),'mode':ill.mode,'alpha_min':int(alpha.min()),'alpha_max':int(alpha.max()),'transparent_pixels':int((alpha==0).sum()),'partial_alpha_pixels':int(((alpha>0)&(alpha<255)).sum()),'opaque_pixels':int((alpha==255).sum()),'transparent_rgb_nonzero':int(((alpha==0)&(a[:,:,:3]!=0).any(axis=2)).sum()),'bbox':list(box),'silhouette_height':box[3]-box[1],'occupancy_height_percent':round((box[3]-box[1])/1536*100,2),'border_alpha_pixels':int(np.count_nonzero(alpha[0,:])+np.count_nonzero(alpha[-1,:])+np.count_nonzero(alpha[:,0])+np.count_nonzero(alpha[:,-1])),'manual_source_skull_chin_sole_y':[sk,ch,sole],'manual_head_count':round((sole-sk+1)/(ch-sk+1),2),'framing':framing},
            'face':{'size':[256,256],'crop_from_final':True,'manual_eye_fraction':round((look['eye']-framing['face_source_box'][1])/(framing['face_source_box'][3]-framing['face_source_box'][1]),4)},
            'sprite':{'file':str((dest/f'{c}-idle-{n}.png').relative_to(ROOT)).replace('\\','/'),'size':list(im.size),'source':look['idle'],'factor':pipeline['summary']['common_scale'],'body_height_excluding_weapon':121-look['body_top'],'manual_head_box':look['head'],'manual_head_height':h,'manual_anatomical_height':ah,'manual_head_count':round(ah/h,2),'reference_first_idle':look['ref'],'detail_percent':round(pipeline['summary']['interior_detail_ratio']*100,2),**pipeline['frames'][0]},
            'visual_review':{'illustration_full_size_dark_light':True,'sprite_nearest_4x':True,'hands_grip_and_feet':'checked visually; hidden finger tips cannot all be counted','prop_complete':True,'extra_limbs_seen':False,'face_clear':True,'sprite_effects_seen':False}}
        data['looks'].append(item)
        x=idx*480
        cd.text((x+24,98),look['title'],font=font(23),fill='#f2dfb5')
        thumb=ill.resize((448,672),Image.Resampling.LANCZOS);concepts.paste(thumb,(x+16,138),thumb.getchannel('A'))
        tile=im.resize((384,384),Image.Resampling.NEAREST);concepts.paste(tile,(x+48,820),tile.getchannel('A'))
        cd.text((x+24,1220),f"몸 {item['sprite']['body_height_excluding_weapon']}px · 머리 약 {item['sprite']['manual_head_count']}등신",font=font(18),fill='#bbc3ce')
        face=Image.open(dest/f'{c}_face-{n}.png').convert('RGBA')
        for row,bgcol in enumerate(['#2a2d34','#c8c4b8']):
            fx=idx*280+12;fy=38+row*284
            faces.paste(bgcol,(fx,fy,fx+256,fy+256));faces.paste(face,(fx,fy),face.getchannel('A'))
            fd.text((fx,fy-28),look['title'],font=font(17),fill='white')
    concepts.save(REPORT/'concepts.png',optimize=True);faces.save(REPORT/'faces.png',optimize=True)
    # Nine columns, four rows: 1x dark/light, 3x dark/light. No rescaling of individual figures.
    width=9*392+140;height=1250
    board=Image.new('RGB',(width,height),'#171b22');d=ImageDraw.Draw(board)
    d.text((22,14),'ART-99a · 현재 게임 대기 첫 칸과 후보 / 동일 발선 y=120',font=font(26),fill='white')
    y=66
    for scale,bgcol in [(1,'#2a2d34'),(1,'#c8c4b8'),(3,'#2a2d34'),(3,'#c8c4b8')]:
        rh=128*scale+36;board.paste(bgcol,(0,y,width,y+rh));d=ImageDraw.Draw(board)
        fg='#f0eee8' if bgcol=='#2a2d34' else '#24272c'
        d.text((12,y+10),f'{scale}×',font=font(26),fill=fg)
        for i,(label,im) in enumerate(entries):
            x=140+i*392+(384-128*scale)//2
            d.text((140+i*392+8,y+5),label,font=font(19),fill=fg)
            tile=im.resize((128*scale,128*scale),Image.Resampling.NEAREST)
            board.paste(tile,(x,y+32),tile.getchannel('A'))
            d.line((140+i*392,y+32+120*scale,140+i*392+384,y+32+120*scale),fill='#7a846e',width=1)
        y+=rh
    board.save(REPORT/'lineup.png',optimize=True)
    write_json(REPORT/'metrics.json',data)
    print(json.dumps([{'id':i['id'],'height':i['sprite']['body_height_excluding_weapon'],'heads':i['sprite']['manual_head_count'],'detail':i['sprite']['detail_percent'],'ill_heads':i['illustration']['manual_head_count']} for i in data['looks']],ensure_ascii=False))

def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

def prepare(c, n, raw_name, face_box):
    dest = OUT/c/str(n)
    im = Image.open(RAW/raw_name).convert('RGBA')
    a = np.asarray(im).copy()
    # Suppress near-zero generated alpha residue, retain soft cutout edges.
    alpha = a[:,:,3].astype(float)
    a[:,:,3] = np.clip((alpha-2)*255/248, 0, 255).round().astype('uint8')
    a[a[:,:,3]==0,:3] = 0
    clean = Image.fromarray(a)
    box = clean.getbbox()
    tight = clean.crop(box)
    scale = min(1352/tight.height, 936/tight.width)
    scaled = tight.resize((round(tight.width*scale),round(tight.height*scale)),Image.Resampling.LANCZOS)
    pos=((1024-scaled.width)//2,(1536-scaled.height)//2)
    final=Image.new('RGBA',(1024,1536)); final.alpha_composite(scaled,pos)
    arr=np.asarray(final).copy(); arr[arr[:,:,3]==0,:3]=0; final=Image.fromarray(arr)
    final.save(dest/f'{c}_illustration-{n}.png',optimize=True)
    # Crop from the delivered illustration, with source-space landmarks mapped exactly.
    mapped=[round((v-box[i%2])*scale+pos[i%2]) for i,v in enumerate(face_box)]
    face=final.crop(tuple(mapped)).resize((256,256),Image.Resampling.LANCZOS)
    face.save(dest/f'{c}_face-{n}.png',optimize=True)
    for name, color in [('dark','#2a2d34'),('light','#c8c4b8')]:
        bg=Image.new('RGBA',final.size,color);bg.alpha_composite(final)
        bg.convert('RGB').save(REPORT/f'{c}{n}-full-{name}.png',optimize=True)
    meta={'source':raw_name,'source_bbox':list(box),'uniform_scale':scale,'paste_xy':list(pos),'face_source_box':face_box,'face_final_box':mapped,'alpha_cleanup':'alpha <=2 ->0; linear 2..250 ->0..255; alpha>=250 ->255; zero RGB when alpha=0'}
    write_json(REPORT/f'{c}{n}-framing.json',meta)
    print(c,n,'illustration',final.size,final.getbbox(),'face',mapped)

if __name__=='__main__':
    if sys.argv[1]=='prepare':prepare(sys.argv[2],int(sys.argv[3]),sys.argv[4],list(map(int,sys.argv[5].split(','))))
    elif sys.argv[1]=='boards':metrics_and_boards()
