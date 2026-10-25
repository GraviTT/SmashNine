"""Verify audit bookkeeping, estimator equivalence, and generate a diagnostic summary."""
import sys
sys.dont_write_bytecode=True
import importlib.util,json,re,time
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from audit import ROOT,OUT,ART,STEMS,dump
from head_check import fft_scale

def read(p):return json.loads(p.read_text(encoding='utf-8'))

def figure():
    picks=[('jotunheim_rune_golem_sheet','idle',1,'골렘 · 대기 F1','bottom'),('muspelheim_magma_boar_sheet','idle',1,'마그마 멧돼지 · 대기 F1','bottom'),('niflheim_glacier_wolf_sheet','idle',1,'빙하 늑대 · 대기 F1','bottom'),('rio_female_moves_sheet','mana_combo',6,'Rio 여성 · J 연타 F6','fragment'),('alfheim_moon_stag_sheet','attack',3,'달 사슴 · 공격 F3','right'),('yggdrasil_root_guardian_sheet','attack',3,'뿌리 수호자 · 공격 F3','right')]
    font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',22);small=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',17)
    w,h=450,470;out=Image.new('RGB',(w*3,h*2+60),(23,27,35));dr=ImageDraw.Draw(out);dr.text((16,12),'QA-23  셀 외곽은 비어 있어도, 그림 안쪽이 잘릴 수 있습니다',font=font,fill='white')
    for i,(key,row,number,title,kind) in enumerate(picks):
        d=read(OUT/'metrics'/f'{key}.json');r=next(r for r in d['rows'] if r['name']==row);f=r['frames'][number-1];im=Image.open(ROOT/d['path']).convert('RGBA');cw,ch=d['cell'];xx=(f['sheet_column']-1)*cw;yy=(f['sheet_row']-1)*ch;tile=im.crop((xx,yy,xx+cw,yy+ch));scale=4 if cw==96 else 2
        x=(i%3)*w+25;y=(i//3)*h+105;dr.text((x,y-38),title,font=font,fill='white');bg=Image.new('RGB',(cw*scale,ch*scale),(43,48,58));bd=ImageDraw.Draw(bg)
        for by in range(0,ch*scale,16):
            for bx in range(0,cw*scale,16):
                if (bx//16+by//16)%2:bd.rectangle((bx,by,bx+15,by+15),fill=(49,55,65))
        scaled=tile.resize(bg.size,Image.Resampling.NEAREST);bg.paste(scaled,(0,0),scaled);out.paste(bg,(x,y));dr.rectangle((x,y,x+cw*scale-1,y+ch*scale-1),outline='#7f8a9b')
        b=f['bbox'];x0,y0,x1,y1=b
        if kind=='bottom':
            dr.line((x+x0*scale,y+y1*scale+3,x+x1*scale,y+y1*scale+3),fill='#ff766c',width=3);label=f"하단 최장 직선 {f['bbox_edge_runs']['bottom']}px / 셀 외곽 0px"
        elif kind=='right':
            dr.line((x+x1*scale+3,y+y0*scale,x+x1*scale+3,y+y1*scale),fill='#ff766c',width=3);label=f"우측 최장 직선 {f['bbox_edge_runs']['right']}px / 셀 외곽 0px"
        else:
            a=np.array(tile)[:,:,3]>=128;seen=np.zeros_like(a);comps=[]
            for cy,cx in zip(*np.nonzero(a)):
                if seen[cy,cx]:continue
                stack=[(cy,cx)];seen[cy,cx]=True;pts=[]
                while stack:
                    py,px=stack.pop();pts.append((py,px))
                    for dy in [-1,0,1]:
                        for dx in [-1,0,1]:
                            ny,nx=py+dy,px+dx
                            if 0<=ny<ch and 0<=nx<cw and a[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;stack.append((ny,nx))
                comps.append(pts)
            pts=sorted(comps,key=len,reverse=True)[1];ys,xs=zip(*pts);dr.rectangle((x+min(xs)*scale-5,y+min(ys)*scale-5,x+(max(xs)+1)*scale+5,y+(max(ys)+1)*scale+5),outline='#ff766c',width=3);label=f'검끝 분리 조각 {len(pts)}px / 셀 외곽 0px'
        dr.text((x,y+393),label,font=small,fill='#ffb0a9')
    out.save(OUT/'contact/priority_examples.png')

def main():
    index=read(OUT/'metrics/live_index.json');ci=read(OUT/'metrics/candidate_index.json');allrows=[];issues=[]
    for entry in index+ci:
        key=__import__('pathlib').Path(entry['path']).stem;candidate=entry in ci;p=OUT/'metrics'/('candidates' if candidate else '')/f'{key}.json';d=read(p)
        if not d['dimensions_match']:issues.append((entry['path'],'dimensions'))
        if d['extra_drawn_cells']:issues.append((entry['path'],'extra_drawn'))
        for row in d['rows']:
            allrows.append((d,row))
            assert row['count']==len(row['frames'])
            if row['summary']['missing']:issues.append((entry['path'],row['name'],'missing'))
    assert not issues,issues
    assert sum(x['frames'] for x in index)==937 and len(index)==43 and len(ci)==349
    heads=[]
    for p in (OUT/'metrics/heads').glob('*.json'):heads.extend(read(p)['rows'])
    assert sum(r['total'] for r in heads)==658
    live_head_total=sum(r['total'] for r in heads);live_head_accepted=sum(r['accepted'] for r in heads)
    # Validate optimized estimator against original on different scales and poses.
    spec=importlib.util.spec_from_file_location('qa23_original',ROOT/'tools/sprite_pipeline/head_scale.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
    checks=[]
    for key,row,num in [('frey_sheet','idle',1),('frey_sheet','attack',6),('rio_male_sheet','attack',1),('nova_male_moves_sheet','meteor_kick',2)]:
        d=read(OUT/'metrics'/f'{key}.json');r=next(r for r in d['rows'] if r['name']==row);f=r['frames'][num-1];cw,ch=d['cell'];im=Image.open(ROOT/d['path']).convert('RGBA');x=(f['sheet_column']-1)*cw;y=(f['sheet_row']-1)*ch;frame=im.crop((x,y,x+cw,y+ch));anchor=Image.open(ART/d['stem'].split('_')[0]/f"{d['stem']}_sheet.png").convert('RGBA').crop((0,0,128,128));template=mod.head_template(anchor);old=mod.head_scale(frame,template);new=fft_scale(frame,template,mod);err=abs(old[1]-new[1]);assert old[0]==new[0] and err<1e-9,(old,new);checks.append({'sheet':key,'row':row,'frame':num,'original_scale':old[0],'fft_scale':new[0],'score_abs_error':err})
    figure()
    data={'schema_and_inventory':'pass','live_images':43,'live_frames':937,'candidate_images':349,'live_head_frames':live_head_total,'live_head_accepted':live_head_accepted,'estimator_equivalence':checks,'geometry_errors':issues,'live_empty_cells':0,'candidate_empty_cells':0,'live_identical_adjacent':sum(len(r['summary']['identical_adjacent']) for d,r in allrows if not d['path'].startswith('art/')),'candidate_identical_adjacent':sum(len(r['summary']['identical_adjacent']) for d,r in allrows if d['path'].startswith('art/')),'note':'No Godot run. Estimator equivalence does not establish anatomical accuracy.'}
    dump(OUT/'metrics/validation.json',data);print(json.dumps(data,ensure_ascii=False,indent=2))

if __name__=='__main__':main()
