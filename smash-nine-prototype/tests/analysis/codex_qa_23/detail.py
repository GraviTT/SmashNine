"""QA-23 supplemental cut measurements and review crops; no product writes."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
import json, argparse
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from audit import ROOT,OUT,ART,STEMS,dump

def runs(v):
    z=np.r_[False,v,False].astype(int);d=np.diff(z);return int(max(np.where(d==-1)[0]-np.where(d==1)[0],default=0))

def geometry():
    rows=[]
    for p in (OUT/'metrics').glob('*.json'):
        d=json.loads(p.read_text(encoding='utf-8'))
        if not isinstance(d,dict) or 'rows' not in d:continue
        sheet=Image.open(ROOT/d['path']).convert('RGBA');cw,ch=d['cell']
        for row in d['rows']:
            for f in row['frames']:
                x=(f['sheet_column']-1)*cw;y=(f['sheet_row']-1)*ch
                im=sheet.crop((x,y,x+cw,y+ch));a=np.array(im);m=a[:,:,3]>=128;b=f['bbox']
                if not b:continue
                x0,y0,x1,y1=b
                f['bbox_edge_runs']={'left':runs(m[y0:y1,x0]),'right':runs(m[y0:y1,x1-1]),'top':runs(m[y0,x0:x1]),'bottom':runs(m[y1-1,x0:x1])}
                f['bbox_edge_counts']={'left':int(m[y0:y1,x0].sum()),'right':int(m[y0:y1,x1-1].sum()),'top':int(m[y0,x0:x1].sum()),'bottom':int(m[y1-1,x0:x1].sum())}
                if max(f['bbox_edge_runs'].values())>=12:rows.append({'sheet':p.stem,'row':row['name'],'frame':f['frame'],'bbox':b,'edge_runs':f['bbox_edge_runs']})
        dump(p,d)
    dump(OUT/'metrics/internal_edges.json',rows)
    print(json.dumps(rows,ensure_ascii=False,indent=1))

def strip_crop(key,row,frames,scale=4):
    d=json.loads((OUT/'metrics'/f'{key}.json').read_text(encoding='utf-8'));r=next(x for x in d['rows'] if x['name']==row);sheet=Image.open(ROOT/d['path']).convert('RGBA');cw,ch=d['cell']
    ims=[]
    if d['stem'] in STEMS:
        ref=Image.open(ART/d['stem'].split('_')[0]/f'{d["stem"]}_sheet.png').convert('RGBA').crop((0,0,128,128));tile=Image.new('RGBA',(cw,ch));tile.alpha_composite(ref,((cw-128)//2,32 if ch==192 else 0));ims.append(('idle',tile))
    else:ims.append(('idle',sheet.crop((0,0,cw,ch))))
    for i in frames:
        f=r['frames'][i-1];x=(f['sheet_column']-1)*cw;y=(f['sheet_row']-1)*ch;ims.append(('F'+str(i),sheet.crop((x,y,x+cw,y+ch))))
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20);w=len(ims)*(cw*scale+10);out=Image.new('RGB',(w,ch*scale+70),(40,44,51));draw=ImageDraw.Draw(out);draw.text((10,5),key+' / '+row,font=font,fill='white')
    for i,(label,im) in enumerate(ims):
        x=i*(cw*scale+10);im=im.resize((cw*scale,ch*scale),Image.Resampling.NEAREST);out.paste(im,(x,35),im);draw.rectangle((x,35,x+cw*scale-1,35+ch*scale-1),outline='#79889c');draw.text((x+5,40+ch*scale),label,font=font,fill='white')
    p=OUT/'contact'/f'detail_{key}_{row}.png';out.save(p);print(p.name)

def projectiles():
    ps=sorted((ART/'monsters').glob('*_projectile.png'))+[ART/'monsters/ember_fireball.png'];font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
    out=Image.new('RGB',(1100,math_ceil(len(ps),3)*340),(40,44,51));dr=ImageDraw.Draw(out)
    for i,p in enumerate(ps):
        x=(i%3)*365;y=(i//3)*340;dr.text((x+5,y+5),p.stem.replace('_projectile',''),font=font,fill='white');im=Image.open(p).convert('RGBA');im=im.resize((im.width*8,im.height*8),Image.Resampling.NEAREST);out.paste(im,(x+30,y+40),im)
    out.save(OUT/'contact/projectiles_detail_8x.png')

def math_ceil(a,b):return (a+b-1)//b

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('mode',choices=['geometry','crops']);args=ap.parse_args()
    if args.mode=='geometry':geometry()
    else:
        for key,row,frames in [
            ('rio_female_sheet','attack',[4,5,6]),('rio_female_moves_sheet','mana_combo',[4,5,6]),
            ('rio_female_sheet','walk',[3,4,5]),('nova_male_sheet','walk',[2,3,4,7]),
            ('rio_male_sheet','walk',[1,3,7]),('rio_female_sheet','fall',[1]),('yuki_sheet','fall',[1]),
            ('nova_female_sheet','hurt',[1]),('rio_female_moves_sheet','low_sweep',[1,3,4,6]),
            ('alfheim_moon_stag_sheet','attack',[1,2,3,4]),('jotunheim_rune_golem_sheet','idle',[1,2,3,4]),
            ('muspelheim_magma_boar_sheet','idle',[1,2,3,4]),('niflheim_glacier_wolf_sheet','idle',[1,2,3,4]),
            ('yggdrasil_root_guardian_sheet','attack',[1,2,3,4]),('ember_imp_sheet','idle',[1,2]),('mossling_sheet','idle',[1,2])]:strip_crop(key,row,frames)
        projectiles()
