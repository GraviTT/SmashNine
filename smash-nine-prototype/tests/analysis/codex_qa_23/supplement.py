"""Focused review crops and descriptive colour-band counts, report only."""
import sys
sys.dont_write_bytecode=True
import json
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from audit import ROOT,OUT,dump
from detail import strip_crop

def main():
    for key,row,fs in [('frey_sheet','attack',[1,3,6]),('rio_male_sheet','attack',[1,3,6]),('nova_male_moves_sheet','meteor_kick',[1,2,6])]:strip_crop(key,row,fs)
    for key,row in [('niflheim_glacier_wolf_sheet-v1','hurt'),('yggdrasil_root_guardian_sheet-v1','hurt'),('jotunheim_rune_golem_sheet-v1','idle')]:
        d=json.loads((OUT/'metrics/candidates'/f'{key}.json').read_text(encoding='utf-8'));r=next(r for r in d['rows'] if r['name']==row);im=Image.open(ROOT/d['path']).convert('RGBA');cw,ch=d['cell'];out=Image.new('RGB',(min(3,len(r['frames']))*cw*6,ch*6+40),(40,44,51));draw=ImageDraw.Draw(out)
        for i,f in enumerate(r['frames'][:3]):
            x=(f['sheet_column']-1)*cw;y=(f['sheet_row']-1)*ch;tile=im.crop((x,y,x+cw,y+ch)).resize((cw*6,ch*6),Image.Resampling.NEAREST);out.paste(tile,(i*cw*6,40),tile);draw.text((i*cw*6+5,10),key+' '+row+' F'+str(f['frame']),fill='white')
        out.save(OUT/'contact'/f'detail_candidate_{key}_{row}.png')
    for key,mode in [('ember_imp_sheet','purple'),('mossling_sheet','teal')]:
        p=OUT/'metrics'/f'{key}.json';d=json.loads(p.read_text(encoding='utf-8'));im=Image.open(ROOT/d['path']).convert('RGBA');cw,ch=d['cell']
        for row in d['rows']:
            for f in row['frames']:
                x=(f['sheet_column']-1)*cw;y=(f['sheet_row']-1)*ch;a=np.array(im.crop((x,y,x+cw,y+ch))).astype(int);r,g,b=a[:,:,:3].transpose(2,0,1);m=a[:,:,3]>0
                vis=a[:,:,3]>=128;inside=vis.copy();pad=np.pad(vis,1)
                for dy,dx in [(-1,0),(1,0),(0,-1),(0,1)]:inside &= pad[1+dy:1+dy+ch,1+dx:1+dx+cw]
                band=(b-r>20)&(b-g>25)&(r-g>15) if mode=='purple' else (g-r>25)&(b-r>25)&(abs(g-b)<50)
                f['observed_band_colour_px']=int((m&band).sum());f['observed_band_rim_px']=int((m&~inside&band).sum())
        d['observed_band_rule']=mode+' RGB predicate; descriptive colour count, not proof of spill';dump(p,d)

if __name__=='__main__':main()
