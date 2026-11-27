"""Whole-image matte/crop/normalization only; never recomposes anatomy."""
import sys, json, shutil, subprocess
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
import normalize as norm
RAW=ROOT/'art/raw/newchar-99b'
REPORT=ROOT/'reports/codex-art-99b'

def illustration(c,n,source,face_box,whole_scale=1.0):
    im=Image.open(RAW/source).convert('RGBA')
    im=norm.remove_chroma_background(im,(0,255,0))
    im=norm.despill_green_edge(im,'auto')
    a=np.array(im); a[a[:,:,3]==0]=0
    im=Image.fromarray(a)
    if im.size!=(1024,1536):
        raise ValueError(f'Unexpected illustration size {im.size}')
    if whole_scale != 1.0:
        small=im.resize((round(im.width*whole_scale),round(im.height*whole_scale)),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',im.size)
        canvas.alpha_composite(small,((im.width-small.width)//2,(im.height-small.height)//2))
        ox,oy=(im.width-small.width)//2,(im.height-small.height)//2
        face_box=tuple(round(v*whole_scale)+(ox if i%2==0 else oy) for i,v in enumerate(face_box))
        im=canvas
    face=im.crop(face_box).resize((256,256),Image.Resampling.LANCZOS)
    out=ROOT/f'art/bakeoff/newchar-2026-11-26/{c}/{n}'
    im.save(out/f'{c}_illustration-{n}.png')
    face.save(out/f'{c}_face-{n}.png')
    for name,color in [('dark','#2a2d34'),('light','#c8c4b8')]:
        bg=Image.new('RGBA',im.size,color); bg.alpha_composite(im)
        bg.convert('RGB').save(REPORT/f'{c}-{n}-illustration-{name}.jpg',quality=90)
    print(c,n,'illustration',im.size,'bbox',im.getbbox(),'spill',norm.spill_pixel_count(im))

def idle(c,n,source,height,ref='nova_female',scale=None):
    out=REPORT/f'normalize-{c}-{n}'
    cmd=[sys.executable,str(ROOT/'tools/sprite_pipeline/normalize.py'),'--sheet',str(RAW/source),'--grid','1x1','--bg','#00ff00','--cell','128','--scale-by',scale or f'height:{height}','--feet-y','120','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--reference',str(RAW/f'ref-{ref}-idle.png')+':0:1','--compare-scale','4','--out-dir',str(out),'--name',f'{c}-idle-{n}']
    subprocess.run(cmd,check=True,cwd=ROOT)
    files=list((out/'frames').glob('*.png'))
    assert len(files)==1
    final=ROOT/f'art/bakeoff/newchar-2026-11-26/{c}/{n}/{c}-idle-{n}.png'
    shutil.copyfile(files[0],final)
    im=Image.open(final)
    im.resize((512,512),Image.Resampling.NEAREST).save(REPORT/f'{c}-{n}-idle-4x.png')
    final.with_suffix('.json').write_text(json.dumps({'note':f'ART-99 외형 후보: {c} {n}, 대기 한 프레임. 게임 미적용.','frames':1},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

if __name__=='__main__':
    c,n=sys.argv[1],int(sys.argv[2])
    if (c,n)==('doron',1):
        illustration(c,n,'doron-1-illustration-green.png',(315,143,585,413))
        idle(c,n,'doron-1-idle-v1.png',88,'nova_female')
    elif (c,n)==('doron',2):
        illustration(c,n,'doron-2-illustration-green.png',(420,73,708,361),0.93)
        idle(c,n,'doron-2-idle-v4.png',88,'nova_female')
    elif (c,n)==('doron',3):
        illustration(c,n,'doron-3-illustration-green.png',(520,212,740,432))
        idle(c,n,'doron-3-idle-v3.png',88,'luna')
    elif (c,n)==('jupi',2):
        illustration(c,n,'jupi-2-illustration-green.png',(393,246,657,510))
        idle(c,n,'jupi-2-idle-v2.png',96,'nova_female')
    elif (c,n)==('jupi',3):
        illustration(c,n,'jupi-3-illustration-green.png',(419,227,677,485))
        idle(c,n,'jupi-3-idle-v5.png',102,'nova_female')
